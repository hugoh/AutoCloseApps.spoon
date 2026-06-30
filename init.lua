-- vim: set ft=lua:

--- === AutoCloseApps ===
---
--- A Hammerspoon Spoon that automatically quits applications after periods of inactivity.
---
--- Download: https://github.com/hugoh/AutoCloseApps.spoon/releases/latest

local obj = {}
obj.__index = obj

obj.name = "AutoCloseApps"
obj.version = "dev"
obj.author = "Hugo Haas"
obj.license = "MIT"
obj.homepage = "https://github.com/hugoh/AutoCloseApps.spoon"

-- Internal state
obj.lastActiveTimes = {}
obj.monitoredApps = {}
obj.monitoredAppsSet = {}
obj.quitTimer = nil
--- AutoCloseApps.quitCheckInterval
--- Variable
--- Seconds between idle-application checks (default: 600).
obj.quitCheckInterval = 600
obj.appWatcher = nil

-- Logger
obj.logger = hs.logger.new(obj.name, "info")

function obj:updateLastActiveTime(name) self.lastActiveTimes[name] = os.time() end

function obj:getLastActiveTime(name) return self.lastActiveTimes[name] end

--- AutoCloseApps:monitor(appConfigs) -> AutoCloseApps
--- Method
--- Set the list of applications to watch and their idle timeouts.
---
--- Parameters:
---  * appConfigs - A list of tables, each with a `name` (string) and `idleTime` (seconds) field.
---    An optional `excludeFromIdleClose` (boolean) field can be set to `true` to never
---    force-quit that app even when it has zero windows, e.g. for apps that may be doing
---    background work (uploading, syncing, recording) with no open windows.
---
--- Returns:
---  * The AutoCloseApps object, for method chaining
function obj:monitor(appConfigs)
	self.monitoredApps = appConfigs
	self.monitoredAppsSet = {}
	for _, c in ipairs(appConfigs) do
		self.monitoredAppsSet[c.name] = true
		-- Seed the last active time for apps that aren't tracked yet, so apps added via
		-- monitor() after start() are eligible for idle-closing without needing a restart.
		if self:getLastActiveTime(c.name) == nil then self:updateLastActiveTime(c.name) end
	end
	return self
end

--- AutoCloseApps:start() -> AutoCloseApps
--- Method
--- Start monitoring for idle applications.
---
--- Returns:
---  * The AutoCloseApps object, for method chaining
function obj:start()
	if self.quitTimer or self.appWatcher then
		self.logger.w("AutoCloseApps already started; stopping previous instance first")
		self:stop()
	end

	self.logger.i("Starting AutoCloseApps Spoon")

	-- Initialize the last active times for monitored apps
	for _, appConfig in ipairs(self.monitoredApps) do
		self:updateLastActiveTime(appConfig.name)
	end

	-- Watch for app activation events to track last active time
	self.appWatcher = hs.application.watcher.new(function(appName, eventType, _)
		if eventType == hs.application.watcher.activated and self.monitoredAppsSet[appName] then
			self.logger.df("Updating last activity for %s", appName)
			self:updateLastActiveTime(appName)
		end
	end)
	self.appWatcher:start()

	-- Start a timer to check for idle applications
	self.quitTimer = hs.timer.doEvery(self.quitCheckInterval, hs.fnutils.partial(self.checkForIdleApps, self))

	return self
end

--- AutoCloseApps:stop()
--- Method
--- Stop monitoring and cancel all timers.
function obj:stop()
	self.logger.i("Stopping AutoCloseApps Spoon")
	self.lastActiveTimes = {}
	if self.quitTimer then
		self.quitTimer:stop()
		self.quitTimer = nil
	end
	if self.appWatcher then
		self.appWatcher:stop()
		self.appWatcher = nil
	end
end

function obj:checkForIdleApps()
	self.logger.d("Checking idle apps")
	local currentTime = os.time()

	for _, appConfig in ipairs(self.monitoredApps) do
		local appName = appConfig.name
		local app = hs.application.get(appName)
		if app then
			local idleTime = appConfig.idleTime or 3600 -- Default to 1 hour
			local lastActive = self:getLastActiveTime(appName)
			if lastActive and (currentTime - lastActive >= idleTime) then
				if appConfig.excludeFromIdleClose then
					self.logger.df("App: %s, Excluded from idle-closing", appName)
				elseif app:isFrontmost() then
					self.logger.df("App: %s, Frontmost", appName)
				elseif #app:allWindows() == 0 then
					self.logger.i("App: " .. appName .. ", Closing")
					app:kill()
				else
					self.logger.df("App: %s, Has windows", appName)
				end
			else
				self.logger.df("App: %s, Active", appName)
			end
		else
			self.logger.df("App: %s, Not Running", appName)
		end
	end
end

return obj
