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
    {name = "Mail", idleTime = 7200},    -- Quit after 2 hours
    {name = "Backblaze", idleTime = 1800, excludeFromIdleClose = true}  -- Never auto-quit
}):start()
```

### Safety limitations

An app is only quit when it has zero open windows, is not frontmost, and has been idle for
longer than its configured `idleTime`. However, Hammerspoon/`hs.application` has no reliable
way to detect whether a window-less app is doing background work (uploading, syncing,
recording, etc.) or holds unsaved state, so it's possible for this Spoon to quit such an app
while it's busy. If you rely on an app that performs background work without a visible window
(backup/sync clients, recorders, etc.), set `excludeFromIdleClose = true` for it, or omit it
from `monitor()` entirely.

## API documentation

Full API reference is available at **<https://hugoh.github.io/AutoCloseApps.spoon/>**.
