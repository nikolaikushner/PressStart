# Retro

Play Game Boy, GBA, NES, and SNES in the browser. The shelf looks like a handheld, the emulators are already in the site, and a GameSir pad works next to the touch buttons. Saves stay on your phone.

**[Play now](https://nikolaikushner.github.io/retro-games/)**

The shells are community skins from [Delta Skins](https://delta-skins.github.io/gbc.html). The Delta name is painted out.

Games are grouped by console. The bottom of the screen is a shell with touch controls, and a physical GameSir pad works alongside those buttons.

Commercial games do not belong here. `roms/nes/gamepad-test.nes` is a small original cartridge: the screen changes color when a button is held.

## Play on an iPhone

1. Push the repository to GitHub and turn on Pages: Settings → Pages → Source: GitHub Actions.
2. Open [the site](https://nikolaikushner.github.io/retro-games/) in Safari.
3. Pair the GameSir over Bluetooth. If the dot on the page stays gray, press any button on the pad. iOS only exposes a controller after a button press.
4. If the buttons still do nothing, set the GameSir app to iOS or Xbox mode, not Switch, and pair the pad again.
5. In Safari tap Share → Add to Home Screen. A home-screen icon hides the address bar, and iOS is less likely to wipe the site's data.

In-game battery saves are written to the browser about every 15 seconds. A snapshot of the exact moment is written every 45 seconds, when you leave the page, and when you tap Save. Next time the button says Continue.

Saves live in this Safari on this iPhone. They are not committed. Add also plays a file from the phone locally and does not upload it to the repository.

## Add a ROM

Put the file in the console folder and refresh the catalog:

```bash
node scripts/sync-library.mjs
```

Pages rebuilds the catalog on every deploy, so committing `roms/library.json` by hand is optional.

| Folder | Console |
| --- | --- |
| `roms/nes` | NES |
| `roms/snes` | SNES |
| `roms/gb`, `roms/gbc` | Game Boy and Color |
| `roms/gba` | Game Boy Advance |
| `roms/genesis` | Mega Drive |
| `roms/n64` | Nintendo 64 |
| `roms/psx` | PlayStation, `.cue` files |
| `roms/bios` | BIOS, when a core asks for one |

GitHub rejects a file larger than 100 MB. The shelf title comes from the file name. Set your own title in `roms/overrides.json`.

For a US PlayStation, add `roms/bios/scph5501.bin`. For Sega CD, add `roms/bios/bios_CD_U.bin`.

The site already includes cores for Game Boy, Game Boy Color, Game Boy Advance, NES, SNES, Mega Drive, Master System, and Game Gear (`vendor/emulatorjs`, EmulatorJS 4.2.3). Nintendo 64, DS, and PlayStation are not in that set.

A cover is a picture with the same name as the ROM: `roms/gba/game.gba` and `roms/gba/game.png`.

Locally:

```bash
npm run serve
```

Open `http://localhost:8080`.
