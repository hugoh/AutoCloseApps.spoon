local obj = {}
obj.__index = obj

obj.name = "AutoCloseApps"
obj.version = "1.0"
obj.author = "Hugo Haas"
obj.license = "MIT"
obj.homepage = "https://github.com/hugoh/AutoCloseApps.spoon"

-- Internal state
obj.lastActiveTimes = {}
obj.monitoredApps = {}
obj.quitTimer = nil
obj.quitCheckInterval = 600 -- Check every 60 seconds by default
obj.windowFilter = nil

-- Logger
obj.logger = hs.logger.new(obj.name, "info")

local function normalizeAppName(name)
	return string.gsub(name, "%.", "DOT")
end

function obj:updateLastActiveTime(name)
	self.lastActiveTimes[normalizeAppName(name)] = os.time()
end

function obj:getLastActiveTime(name)
	return self.lastActiveTimes[normalizeAppName(name)]
end

function obj:monitor(appConfigs)
	self.monitoredApps = appConfigs
	return self
end

function obj:start()
	self.logger.i("Starting AutoCloseApps Spoon")

	-- Initialize the last active times for monitored apps
	for _, appConfig in ipairs(self.monitoredApps) do
		self:updateLastActiveTime(appConfig.name)
	end

	-- Set up a window filter to track focus changes
	self.windowFilter = hs.window.filter.new():setDefaultFilter({})
	self.windowFilter:subscribe(hs.window.filter.windowFocused, function(win)
		local appName = win:application():name()
		if self:isMonitored(appName) then
			self.logger.df("Updating last activity for %s", appName)
			self:updateLastActiveTime(appName)
		end
	end)

	-- Start a timer to check for idle applications
	self.quitTimer = hs.timer.doEvery(self.quitCheckInterval, hs.fnutils.partial(self.checkForIdleApps, self))

	return self
end

function obj:stop()
	self.logger.i("Stopping AutoCloseApps Spoon")
	self.lastActiveTimes = {}
	if self.quitTimer then
		self.quitTimer:stop()
		self.quitTimer = nil
	end
	if self.windowFilter then
		self.windowFilter:unsubscribe(hs.window.filter.windowFocused)
		self.windowFilter = nil
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
				if #app:allWindows() == 0 then
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

function obj:isMonitored(appName)
	for _, appConfig in ipairs(self.monitoredApps) do
		if appConfig.name == appName then
			return true
		end
	end
	return false
end

return obj
