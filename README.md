# Millennium MUI Pack

PowerShell and batch scripts to install a preconfigured Millennium Steam skin setup with selected plugins and an optional theme.

This repository exists to make it easier for me and my friends to set up Millennium in a consistent way using one download and a simple installer script. I do **not** claim any ownership of the plugins, themes, or the Millennium skin itself. All credit goes to their original authors.

---

## What this repo includes

- A preconfigured `Millennium` folder archive:
  - Plugins:
    - [LuaTools](https://github.com/clemdotla/luatools-installer)
    - [steamtools-collection](https://github.com/clemdotla/steamtools-collection)
    - [size-on-disk](https://steambrew.app/plugin?id=e73371b61eef)
  - Theme (optional):
    - [NEVKO-UI](https://steambrew.app/theme?id=PfApgfY80M1svZEWXQtX)
- Installer scripts:
  - PowerShell installer (`Millennium_MUI_Installer.ps1`)
  - (Optional) CMD/batch installer version

The archive is just a packaged Millennium configuration so it can be dropped into the correct Steam folder automatically.

---

## What this repo does *not* do

- It does **not** modify or redistribute Millennium, LuaTools, steamtools-collection, size-on-disk, or NEVKO-UI source code.
- It does **not** bypass any form of DRM, licensing, or paid content.
- It does **not** claim any of these projects as its own.

This is essentially a convenience installer and configuration bundle on top of existing third-party tools and themes.

---

## Requirements

- Windows
- Steam installed
- [7-Zip](https://www.7-zip.org/) installed in a standard location (`C:\Program Files\7-Zip` or `C:\Program Files (x86)\7-Zip`)
- PowerShell 5+ (comes with modern Windows)

---

## How to use (PowerShell installer)

1. **Close Steam** if it’s running.
2. Open **PowerShell**.
3. (Optional) Allow running scripts for this session:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Run the online installer:
   ```powershell
   irm https://raw.githubusercontent.com/Mario64MUI/MUI-Files/refs/heads/main/scripts/Millennium_MUI_Installer.ps1 | iex
   ```
5. Follow the prompts.  
   The script will:
   - Detect your Steam install path (via registry, with a sensible fallback)
   - Close Steam
   - Remove your existing `Millennium` folder (clean install)
   - Download the latest `Millennium MUI Pack` release archive
   - Extract it into the correct `steamui\skins\Millennium` folder

After it finishes, start Steam and select the Millennium skin in the Steam interface settings.

---

## Credits

All of the actual content (skin, plugins, theme) is created and maintained by their respective authors:

- Millennium skin by its original developers
- LuaTools by [clemdotla](https://github.com/clemdotla/luatools-installer)
- steamtools-collection by [clemdotla](https://github.com/clemdotla/steamtools-collection)
- size-on-disk by its author on [Steambrew](https://steambrew.app/plugin?id=e73371b61eef)
- NEVKO-UI theme by its author on [Steambrew](https://steambrew.app/theme?id=PfApgfY80M1svZEWXQtX)

If you like these tools and themes, please support the original projects and authors.

---

## License and disclaimer

- The installer scripts in this repository are provided “as is”, with no warranty.
- This repository only contains:
  - Convenience scripts
  - A prepackaged configuration archive
- All third-party content included in the archive remains under its original license and ownership.

If any original author of the included projects wants this repository or the bundled archive removed or changed, I will comply.
