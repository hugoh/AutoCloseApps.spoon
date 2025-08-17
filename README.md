# AutoCloseApps Spoon

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Hammerspoon Spoon](https://img.shields.io/badge/Hammerspoon-Spoon-FFA500.svg)](https://www.hammerspoon.org/docs/index.html)

A Hammerspoon Spoon that automatically quits applications after periods of inactivity.

**Repository**: [https://github.com/hugoh/AutoCloseApps.spoon](https://github.com/hugoh/AutoCloseApps.spoon)

## Features

- Automatically quits applications after configurable idle periods
- Configurable check intervals

## Alternatives

If you're looking for other solutions in this space, consider:

- [Quitter](https://marco.org/apps#quitter)

## Installation

1. Ensure you have [Hammerspoon](https://www.hammerspoon.org) installed
2. Clone this repository to your Spoons directory:
```bash
cd ~/.hammerspoon/Spoons
git clone https://github.com/hugoh/AutoCloseApps.spoon.git
```

## Configuration

Add this to your `.hammerspoon/init.lua`:

```lua
-- Load and configure the Spoon
local autoCloseApps = hs.loadSpoon("AutoCloseApps")

-- Optional configuration (defaults shown)
autoCloseApps.quitCheckInterval = 600  -- Check every 60 seconds

autoCloseApps:monitor({
    {name = "Safari", idleTime = 3600},  -- Quit after 1 hour inactivity
    {name = "Slack", idleTime = 1800},   -- Quit after 30 minutes
    {name = "Mail", idleTime = 7200}     -- Quit after 2 hours
}):start()
```
