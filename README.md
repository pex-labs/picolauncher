<div align="center">

<img src="media/logo.png" alt="PicoLauncher" width="70%">

PICO-8 powered games launcher for the [PeX Console](https://pex-labs.com/)

[![crates.io](https://img.shields.io/crates/v/picolauncher.svg)](https://crates.io/crates/picolauncher)
[![docs.rs](https://docs.rs/picolauncher/badge.svg)](https://docs.rs/picolauncher)
[![MIT/Apache 2.0](https://img.shields.io/badge/license-MIT%2FApache-blue.svg)](#)

</div>

**NOTE**: This project is still early access! There are many not implemented features, potential bugs, and cross platform support is still WIP! Bug reports and feature requests are greatly welcome! :))

**PicoLauncher** is a game launcher and 'operating system' for handheld consoles that run [PICO-8](https://www.lexaloffle.com/pico-8.php) natively. It seeks to streamline and revamp the PICO-8 gaming experience with features and apps like
- revamped SPLORE
- play paid games and apps too! (coming soon)
- photo gallery
- gif player (coming soon)
- music player
- settings/preferences app
- on screen keyboard (coming soon)
- physical cartridges (coming soon)

**PicoLauncher** is developed for the [PeX Console](https://pex-labs.com/) by PeX Labs, however in the future support may come for other devices.

<div style="display: flex; justify-content: space-between;">
<img src="media/pexsplore.gif" alt="pexsplore" style="max-width: 100%; height: auto;">
<img src="media/gallery.gif" alt="pexsplore" style="max-width: 100%; height: auto;">
</div>
<div style="display: flex; justify-content: space-between;">
<img src="media/tunes.gif" alt="pexsplore" style="max-width: 100%; height: auto;">
<img src="media/settings.gif" alt="pexsplore" style="max-width: 100%; height: auto;">
</div>

## Getting started

**PicoLauncher** requires an installed version of PICO-8 (if you don't have it, you can buy it [here](https://www.lexaloffle.com/pico-8.php?#getpico8)). You can either use a pre-compiled version from the latest [release]() or build this project from source.

### Pre-compiled

Download the pre-compiled release for your platform and unzip it. You will then find executables for all supported platforms. The `drive/` directory will be where the PICO-8 data files will be stored. For now, you can only run **PicoLauncher** from the same directory as the executables.

On windows, if your PICO-8 binary doesn't reside at the default location of `C:\\Program Files (x86)\\PICO-8\\pico8.exe`, you need to set the environment variable `PICO8_BINARY` before launching.
```sh
set PICO8_BINARY=<path to pico8>
./picolauncher.exe
```

On linux, if PICO-8 is not in your PATH, you need to set the environment variable as well.
```sh
PICO8_BINARY=<path to pico8>
./picolauncher
```

### Build from source

To build from source, you need to have a [rust toolchain](https://www.rust-lang.org/tools/install) installed. To build **PicoLauncher** for all platforms, there is a provided build script at `dev/scripts/build_linux.sh` and `dev/scripts/build_windows.sh`. The built files are present in the `build_<platform>/` directory, as well as zipped up in `build_<platform>.zip`. This is the same build that is distributed in the pre-compiled release.

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more details! Don't hesitate to report bugs and post feature requests!

## Credits

Pre-bundled games
- [birds with guns](https://www.lexaloffle.com/bbs/?tid=45334)
- [bun bun samurai](https://www.lexaloffle.com/bbs/?tid=54707)
- [celeste](https://www.lexaloffle.com/bbs/?tid=2145)
- [cherrybomb](https://www.lexaloffle.com/bbs/?tid=48986)
- [mot's grand prix](https://www.lexaloffle.com/bbs/?pid=97606)
- [oblivion eve](https://www.lexaloffle.com/bbs/?pid=142641)
- [pico night punkin'](https://www.lexaloffle.com/bbs/?tid=42715)
- [poom](https://www.lexaloffle.com/bbs/?pid=101541)
- [swordfish](https://www.lexaloffle.com/bbs/?tid=31141)

