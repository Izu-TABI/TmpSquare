<p align="center">
  <img src="docs/images/icon.png" width="128" alt="TmpSquare icon">
</p>

<h1 align="center">TmpSquare</h1>

<p align="center">
  A macOS menu bar app that gives you a temporary "shelf" for your files<br>
  English | <a href="README.md">日本語</a>
</p>

<p align="center">
  <img src="docs/images/demo.gif" width="640" alt="Shaking the cursor while dragging files opens a shelf; the dropped files are later dragged out together into another folder">
</p>

Shake the cursor left and right while dragging files, and a shelf appears right there. Park your files on it, open the destination folder or app, then drag them all out at once. Handy when you're collecting files from different windows.

<p align="center">
  <img src="docs/images/screenshots.png" width="820" alt="An empty shelf, a shelf showing files as a stack, and a shelf showing files as a list">
</p>

> [!NOTE]
> The app's interface is currently in Japanese only.

## Download

**[Download TmpSquare.zip](https://github.com/Izu-TABI/TmpSquare/releases/latest/download/TmpSquare.zip)** (macOS 14 or later, Apple silicon / Intel)

1. Open the zip and move `TmpSquare.app` to your Applications folder.
2. Open `TmpSquare.app`. The app isn't notarized by Apple, so the first time you'll see a warning that it was not opened. Click **Done**.
3. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to TmpSquare. Confirm with **Open Anyway** again.

You're all set when a dashed-square icon appears in the menu bar. Older versions are available on the [Releases](https://github.com/Izu-TABI/TmpSquare/releases) page.

## Usage

| Action | Result |
| --- | --- |
| Shake the cursor left and right while dragging files | A shelf opens at the center of the shake and follows the cursor until your hand settles (drop right onto it) |
| ⌥⇧Space / "新しいシェルフ" (New Shelf) in the menu bar | Opens an empty shelf |
| Drop onto the shelf | Adds files, folders, images, links, text, and attachments from Photos or Mail |
| Drag the card stack | Drags all items out at once |
| Click the cards / the list button | Switches to the list view (drag items one by one, double-click to open) |
| Right-click / the "…" button | Open, Show in Finder, Share, Copy, Copy Path, Compress to ZIP, Remove from Shelf |
| Drag the header | Moves the shelf |
| ✕ / esc | Closes the shelf |

- When you drop into Finder, it behaves just like Finder (moves on the same disk; hold ⌥ to copy).
- Items you drag out are removed from the shelf, and an emptied shelf closes automatically (configurable in the menu).
- Dropped image data, attachments, and ZIP files are stored in `~/Library/Caches/com.odentabetai.TmpSquare/Items` and deleted on the next launch.
- Shake detection on/off, shake sensitivity, and launch at login can be set from the menu bar.

## Building from source

### Requirements

- macOS 14 or later (shown with Liquid Glass on macOS 26)
- Xcode Command Line Tools (the full Xcode app is not required)

### Build and run

```bash
./scripts/build.sh --run       # build build/TmpSquare.app and launch it
./scripts/build.sh --install   # install to /Applications and launch it
./scripts/test.sh              # run the tests
```

### Publishing a release

Bump `CFBundleShortVersionString` in `Resources/Info.plist`, commit and push, then run the script below. It builds a universal app (Apple silicon and Intel) and publishes a `v<version>` release on GitHub with `TmpSquare.zip` attached.

```bash
./scripts/release.sh
```

### Regenerating the demo images

After changing the look of the app, regenerate the README images (`docs/images`) with the command below. It actually runs the shelf, records it frame by frame, and composites the cursor and dragged files on top. A shelf briefly appears in the center of the screen while recording.

```bash
./scripts/make-demo.sh
```

## Project layout

```
Sources/TmpSquare/
├── App/        launch, menu bar, settings, global hotkey
├── Shake/      shake detection while dragging
├── Shelf/      shelf window, state, importing drops, actions
├── Views/      SwiftUI views and AppKit-based drag-out
└── Support/    temporary storage, ZIP creation, menu item helpers
Tests/TmpSquareTests/   tests for shake detection, shelf placement, importing, drop handling, ZIP
scripts/        build, test, release, icon and demo image generation
docs/images/    README images
```

## Debug options (debug builds only)

```bash
swift build
.build/debug/TmpSquare --open-shelf --expanded ~/Desktop/a.pdf ~/Desktop/b.png
```

`--open-shelf` opens a shelf with the given items in the center of the screen. The app can write its own window to a PNG, so you can check the UI without screen recording permission.

| Option | Description |
| --- | --- |
| `--snapshot out.png` | Writes the shelf's appearance |
| `--filmstrip out.png` | Toggles between stack and list view and writes the frames side by side |
| `--record <dir>` | Walks through the shelf's states from empty, writes each scene's frames, then quits (for the demo images) |
| `--drop-later` | Opens an empty shelf and adds the items during `--filmstrip` (the drop animation) |
| `--expanded` | Opens in list view |
| `--dark` / `--light` | Forces the appearance |
| `--key` / `--shadow` | Makes the shelf the key window before capturing / includes the window shadow |

Animation timings are collected in `ShelfMotion` in `Sources/TmpSquare/Views/ShelfView.swift`.

## License

[MIT License](LICENSE)
