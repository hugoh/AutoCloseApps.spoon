# AutoCloseApps Spoon

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Hammerspoon Spoon](https://img.shields.io/badge/Hammerspoon-Spoon-FFA500.svg)](https://www.hammerspoon.org/docs/index.html)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://hugoh.github.io/AutoCloseApps.spoon/)

A Hammerspoon Spoon that automatically quits applications after periods of inactivity.

**Repository**: [https://github.com/hugoh/AutoCloseApps.spoon](https://github.com/hugoh/AutoCloseApps.spoon)

## Features

- Automatically quits applications after configurable idle periods
- Configurable check intervals

## Alternatives

If you're looking for other solutions in this space, consider:

- [Quitter](https://marco.org/apps#quitter)

## Installation

Ensure you have [Hammerspoon](https://www.hammerspoon.org) installed, then choose a method:

### Release zip (recommended)

1. Download `AutoCloseApps.spoon.zip` from the [latest release](https://github.com/hugoh/AutoCloseApps.spoon/releases/latest)
2. Unzip — this produces an `AutoCloseApps.spoon` folder
3. Move it to `~/.hammerspoon/Spoons/`
4. Reload Hammerspoon (menu bar icon → Reload Config, or run `hs.reload()` in the console)

### SpoonInstall (if you already use it)

```lua
spoon.SpoonInstall:installSpoonFromZip(
  "https://github.com/hugoh/AutoCloseApps.spoon/releases/latest/download/AutoCloseApps.spoon.zip"
)
```

### Clone from git (for development or latest changes)

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

## API documentation

Full API reference is available at **<https://hugoh.github.io/AutoCloseApps.spoon/>**.
