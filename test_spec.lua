local mock_hs
local AutoCloseApps

before_each(function()
	mock_hs = {
		logger = {
			new = function(_name, _level)
				return {
					i = function() end,
					f = function() end,
					d = function() end,
					df = function() end,
					w = function() end,
				}
			end,
		},
		application = {
			watcher = {
				new = function(cb)
					return {
						_cb = cb,
						start = function(self) self._started = true end,
						stop = function(self) self._stopped = true end,
					}
				end,
				activated = "activated",
			},
			get = function(_name) return nil end,
		},
		timer = {
			doEvery = function(_interval, _fn)
				return {
					stop = function(self) self._stopped = true end,
				}
			end,
		},
		fnutils = {
			partial = function(fn, ...)
				local args = { ... }
				return function() return fn(table.unpack(args)) end
			end,
		},
	}

	package.loaded.hs = nil
	_G.hs = mock_hs

	AutoCloseApps = dofile("init.lua")
end)

after_each(function()
	if AutoCloseApps.quitTimer then AutoCloseApps:stop() end
end)

local function makeMockApp(overrides)
	overrides = overrides or {}
	local app = {
		killed = false,
		allWindows = overrides.allWindows or function() return {} end,
		isFrontmost = overrides.isFrontmost or function() return false end,
	}
	app.kill = function() app.killed = true end
	return app
end

local function registerApps(appsByName)
	mock_hs.application.get = function(name) return appsByName[name] end
end

describe("AutoCloseApps", function()
	describe("module structure", function()
		it("returns a table", function() assert.is.table(AutoCloseApps) end)

		it("has name", function() assert.are.equal("AutoCloseApps", AutoCloseApps.name) end)

		it("has default quitCheckInterval", function() assert.are.equal(600, AutoCloseApps.quitCheckInterval) end)

		it("initializes with empty monitoredApps", function()
			assert.is.table(AutoCloseApps.monitoredApps)
			assert.are.equal(0, #AutoCloseApps.monitoredApps)
		end)

		it("initializes with nil timer", function() assert.is_nil(AutoCloseApps.quitTimer) end)
	end)

	describe("monitor()", function()
		it("sets monitoredApps", function()
			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })
			assert.are.equal(1, #AutoCloseApps.monitoredApps)
			assert.are.equal("Safari", AutoCloseApps.monitoredApps[1].name)
		end)

		it("builds monitoredAppsSet", function()
			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })
			assert.is_true(AutoCloseApps.monitoredAppsSet["Safari"])
			assert.is_nil(AutoCloseApps.monitoredAppsSet["Chrome"])
		end)

		it("returns self for chaining", function()
			local result = AutoCloseApps:monitor({})
			assert.are.equal(AutoCloseApps, result)
		end)

		it("seeds lastActiveTimes for newly added apps", function()
			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })
			assert.is_number(AutoCloseApps:getLastActiveTime("Safari"))
		end)

		it("seeds lastActiveTimes for apps added after start()", function()
			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })
			AutoCloseApps:start()
			assert.is_nil(AutoCloseApps:getLastActiveTime("Slack"))

			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 }, { name = "Slack", idleTime = 1800 } })

			assert.is_number(AutoCloseApps:getLastActiveTime("Slack"))
			AutoCloseApps:stop()
		end)

		it("does not reset lastActiveTime for an already-tracked app", function()
			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })
			local originalTime = AutoCloseApps:getLastActiveTime("Safari")
			AutoCloseApps.lastActiveTimes["Safari"] = originalTime - 100

			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })

			assert.are.equal(originalTime - 100, AutoCloseApps:getLastActiveTime("Safari"))
		end)
	end)

	describe("updateLastActiveTime / getLastActiveTime", function()
		it("stores and retrieves a timestamp", function()
			local before = os.time()
			AutoCloseApps:updateLastActiveTime("TestApp")
			local after = os.time()
			local t = AutoCloseApps:getLastActiveTime("TestApp")
			assert.is_number(t)
			assert.is_true(t >= before and t <= after)
		end)

		it("returns nil for untracked app", function() assert.is_nil(AutoCloseApps:getLastActiveTime("Unknown")) end)
	end)

	describe("start()", function()
		before_each(function() AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } }) end)

		after_each(function() AutoCloseApps:stop() end)

		it("creates quitTimer", function()
			AutoCloseApps:start()
			assert.is_not_nil(AutoCloseApps.quitTimer)
		end)

		it("creates appWatcher", function()
			AutoCloseApps:start()
			assert.is_not_nil(AutoCloseApps.appWatcher)
		end)

		it("initializes lastActiveTimes for monitored apps", function()
			AutoCloseApps:start()
			assert.is_number(AutoCloseApps:getLastActiveTime("Safari"))
		end)

		it("returns self for chaining", function()
			local result = AutoCloseApps:start()
			assert.are.equal(AutoCloseApps, result)
		end)

		it("stops the previous timer and watcher when called again", function()
			AutoCloseApps:start()
			local firstTimer = AutoCloseApps.quitTimer
			local firstWatcher = AutoCloseApps.appWatcher

			AutoCloseApps:start()

			assert.is_true(firstTimer._stopped)
			assert.is_true(firstWatcher._stopped)
			assert.is_not_nil(AutoCloseApps.quitTimer)
			assert.is_not_nil(AutoCloseApps.appWatcher)
			assert.are_not.equal(firstTimer, AutoCloseApps.quitTimer)
			assert.are_not.equal(firstWatcher, AutoCloseApps.appWatcher)
		end)
	end)

	describe("stop()", function()
		before_each(function()
			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })
			AutoCloseApps:start()
		end)

		it("nils out the timer", function()
			AutoCloseApps:stop()
			assert.is_nil(AutoCloseApps.quitTimer)
		end)

		it("nils out the app watcher", function()
			AutoCloseApps:stop()
			assert.is_nil(AutoCloseApps.appWatcher)
		end)

		it("clears lastActiveTimes", function()
			AutoCloseApps:stop()
			assert.is_nil(AutoCloseApps:getLastActiveTime("Safari"))
		end)
	end)

	describe("checkForIdleApps()", function()
		it("does nothing when app is not running", function()
			AutoCloseApps:monitor({ { name = "Safari", idleTime = 3600 } })
			mock_hs.application.get = function(_name) return nil end
			AutoCloseApps:updateLastActiveTime("Safari")
			AutoCloseApps:checkForIdleApps()
		end)

		local idleCheckCases = {
			{
				name = "kills idle app with no windows",
				monitorEntry = { name = "Safari", idleTime = 1 },
				lastActiveOffset = 10,
				expectKilled = true,
			},
			{
				name = "does not kill frontmost app even with no windows",
				monitorEntry = { name = "Safari", idleTime = 1 },
				appOverrides = { isFrontmost = function() return true end },
				lastActiveOffset = 10,
				expectKilled = false,
			},
			{
				name = "does not kill app marked excludeFromIdleClose",
				monitorEntry = { name = "Safari", idleTime = 1, excludeFromIdleClose = true },
				lastActiveOffset = 10,
				expectKilled = false,
			},
			{
				name = "does not kill app that has windows",
				monitorEntry = { name = "Safari", idleTime = 1 },
				appOverrides = { allWindows = function() return { {} } end },
				lastActiveOffset = 10,
				expectKilled = false,
			},
			{
				name = "does not kill app within idle time",
				monitorEntry = { name = "Safari", idleTime = 3600 },
				lastActiveOffset = 0,
				expectKilled = false,
			},
			{
				name = "uses default idleTime of 3600 when not specified",
				monitorEntry = { name = "Safari" },
				lastActiveOffset = 7200,
				expectKilled = true,
			},
		}

		for _, case in ipairs(idleCheckCases) do
			it(case.name, function()
				local mockApp = makeMockApp(case.appOverrides)
				registerApps({ Safari = mockApp })
				AutoCloseApps:monitor({ case.monitorEntry })
				AutoCloseApps.lastActiveTimes["Safari"] = os.time() - case.lastActiveOffset
				AutoCloseApps:checkForIdleApps()
				assert.are.equal(case.expectKilled, mockApp.killed)
			end)
		end

		it("continues checking subsequent apps when one app's check errors", function()
			local brokenApp = makeMockApp({ allWindows = function() error("boom") end })
			local healthyApp = makeMockApp()
			registerApps({ Broken = brokenApp, Safari = healthyApp })
			AutoCloseApps:monitor({
				{ name = "Broken", idleTime = 1 },
				{ name = "Safari", idleTime = 1 },
			})
			AutoCloseApps.lastActiveTimes["Broken"] = os.time() - 10
			AutoCloseApps.lastActiveTimes["Safari"] = os.time() - 10

			assert.has_no.errors(function() AutoCloseApps:checkForIdleApps() end)
			assert.is_true(healthyApp.killed)
		end)
	end)
end)
