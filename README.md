# Coat Check

A free, open-source menu bar manager for macOS. Check the icons you don't need right now behind a divider, and get them back with one click.

Coat Check checks them automatically when the laptop screen is the only one in use, where the notch leaves little room, and brings them back when an external display connects.

- **No permissions.** No Accessibility, no Screen Recording.
- **No telemetry.** Nothing leaves your Mac except Sparkle's update check.
- **Built to last through macOS updates.** It uses the plain divider technique, not the screen capture and private menu bar tricks that break every year.

## How to use it

Coat Check adds two things to the right end of your menu bar: a hanger and a thin divider (│) to its left.

- Every icon to the **left** of the divider gets checked. Hold ⌘ and drag the icons you always want to see to the **right** of the divider, next to the hanger.
- **Click the hanger** to check icons or get them back. You can also click the divider to check them.
- **Right-click the hanger** for Settings, Check for Updates and Quit.

If the hanger ever ends up off-screen, open Coat Check again from Finder or Spotlight and its settings window appears.

### The laptop screen

With only the built-in display in use, Coat Check checks icons automatically. When an external display connects, including with the lid closed, it brings them back. Clicking the hanger overrides this until the next display change. Turn it off in Settings → **Check icons on the laptop screen**.

### Settings

- **Check icons on the laptop screen**: on by default.
- **After showing icons, check them again**: never, or after 5 seconds to 1 minute. Coat Check waits while the pointer is in the menu bar.
- **Open Coat Check at login**: on by default for copies in Applications.

## Command line

Install the `coatcheck` command from Settings → Command line → **Install…**.

```
coatcheck status    Whether icons are checked, and whether only the laptop screen is in use
coatcheck hide      Check the icons left of the divider
coatcheck show      Bring checked icons back
coatcheck toggle    Hide them if they're out, show them if they're checked
coatcheck open      Open Coat Check, or its settings if it's already running
```

Add `--json` for machine-readable output. Exit codes: 0 success, 1 error or Coat Check isn't running, 2 hiding refused because the divider sits right of the hanger.

## How it works

The divider is an ordinary menu bar item. To check icons, it grows wider than the screen, which pushes everything to its left off the menu bar. To bring them back, it shrinks again. Coat Check refuses to hide while the divider sits right of the hanger, so it can never push away its own icon.

## Building

Needs macOS 14 or later and Xcode.

```sh
make test    # unit tests
make lint    # SwiftLint
make run     # build dist/CoatCheck.app and open it
```

Releases are built with `scripts/release.sh` from `main`: Developer ID signing, notarization, a DMG and a Sparkle appcast.

## License

MIT. Coat Check is written from scratch. It shares no code with Ice, Thaw or other GPL-licensed menu bar managers.
