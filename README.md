# MUI Files

Personal repository used as a lightweight host for files and scripts: configs, installers, and various assets (images, audio, etc.). Some folders are used as direct download targets for scripts or tools I maintain.

This repo is not a “project” in the traditional sense; it is mainly storage + automation for my own use and for a few friends.

---

## Contents

Current examples of what this repo may contain:

- Installer scripts (PowerShell / batch)
- Configuration archives (for tools, skins, plugins)
- Static assets (images, audio, other files) used as direct-download hosting
- Experimental or personal-use utilities

Specific contents may change over time; older files can be removed, renamed, or replaced as needed.

---

## Millennium MUI Pack (Steam / Millennium)

One of the main things currently hosted here is a preconfigured **Millennium** Steam skin setup (“Millennium MUI Pack”) plus installer scripts.

### What the Millennium MUI Pack includes

A packaged `Millennium` folder with:

- Plugins:
  - [LuaTools](https://github.com/clemdotla/luatools-installer)
  - [steamtools-collection](https://github.com/clemdotla/steamtools-collection)
  - [size-on-disk](https://steambrew.app/plugin?id=e73371b61eef)
- Theme (optional):
  - [NEVKO-UI](https://steambrew.app/theme?id=PfApgfY80M1svZEWXQtX)

This archive is just a ready-to-use configuration so Millennium can be dropped into the correct Steam folder automatically.

### Millennium installer (PowerShell)

Script: `scripts/Millennium_MUI_Installer.ps1`

**Requirements:**

- Windows 10/11
- Steam installed  
- [7-Zip](https://www.7-zip.org/) installed in a standard location  
- PowerShell 5+ (default on modern Windows)

**Usage:**

1. Close Steam if it’s running.
2. Open PowerShell.
3. (Optional) Allow scripts for this session:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Run the online installer:
   ```powershell
   irm https://raw.githubusercontent.com/Mario64MUI/MUI-Files/refs/heads/main/scripts/Millennium_MUI_Installer.ps1 | iex
   ```
5. Follow the prompts.

The script will:

- Detect your Steam install path (via registry, with a fallback)
- Close Steam
- Remove your existing `Millennium` folder (clean install)
- Download the `Millennium MUI Pack` release archive from this repo
- Extract it into `steamui\skins\Millennium`

After it finishes, start Steam and select the Millennium skin in the Steam interface settings.

---

## Credits for third‑party content

Any third-party projects referenced or archived in this repo (skins, plugins, themes, etc.) are created and maintained by their respective authors. For the Millennium MUI Pack specifically:

- Millennium skin by its original developers
- LuaTools by [clemdotla](https://github.com/clemdotla/luatools-installer)
- steamtools-collection by [clemdotla](https://github.com/clemdotla/steamtools-collection)
- size-on-disk by its author on [Steambrew](https://steambrew.app/plugin?id=e73371b61eef)
- NEVKO-UI theme by its author on [Steambrew](https://steambrew.app/theme?id=PfApgfY80M1svZEWXQtX)

If you use or like these tools and themes, please support the original projects and authors.

---

## License and disclaimer

- Scripts and small utilities I write in this repository are provided “as is”, with no warranty.
- This repo is used as a personal file host; files may be added or removed at any time.
- All third-party content (skins, plugins, themes, media, etc.) remains under its original license and ownership.
- If any original author objects to their content being referenced or bundled here, I will remove or adjust it upon request.
