# vih

A fixed fork of *vih*, a vi clone in Haskell by Michael Feathers (~2009).
It consists of plain .hs files with no build system (cabal/stack) required —
just a bare GHC.

## What is this

A full-screen editor in the vi style. Open a file, edit it, and save with `:w`.

Supported key bindings (command mode):

| Key | Action |
|------|------|
| `h` `j` `k` `l` | Move cursor (left, down, up, right) |
| `w` `b` | Word-wise movement (forward, backward) |
| `0` `$` | Beginning / end of line |
| `gg` `G` | Top / bottom of file |
| `i` | Enter insert mode (`ESC` to leave) |
| `o` | Open a new line below and enter insert mode |
| `x` | Delete the character under the cursor |
| `r` + char | Replace the character under the cursor |
| `dd` | Delete the current line |
| `:` + command | Command line (`:w` = save, `:q` = quit, digits = jump to line) |

## Building and running

Only GHC is required:

```sh
ghc --make -package terminal-size vih.hs 
./vih somefile.txt
```

## Important note on terminal size

This editor hard-codes the screen height as **`yExtent = 40` lines** (Rendering.hs),
and does not handle wrapping of lines longer than 80 characters.

**Your terminal should be at least 42 lines × 80 columns.** On a smaller terminal,
each redraw overflows the screen and causes scrolling, breaking the display.
To check:

```sh
stty size
# e.g. "47 80" = 47 lines × 80 columns → OK
```

If your terminal is too small, resize it, or adjust `yExtent` in Rendering.hs
to fit your environment (`commandHome` is derived from `yExtent`, so a single
change is enough).

## Property tests for the pure core

`EditBuffer` (the core buffer logic) is a fully pure module, structured so
that QuickCheck properties can be written against it.

On Ubuntu/Debian, install the test dependency as a distro package:

```sh
sudo apt install libghc-quickcheck2-dev
```

Note that this installs QuickCheck for the distro GHC, not for any GHC
installed via ghcup. Build the test with the distro GHC:

```sh
ghc --make Eb_Check.hs -o eb_check
./eb_check
```

Properties verified:

- `prop_insert_delete_inverse`: insert → move left → delete returns the buffer
  to the original empty state (newline excluded — newline deletion is not implemented)
- `prop_insert_char_advances`: inserting n times advances the cursor position x by exactly n

## Fixes in this fork

The original repository has been unmaintained since ~2009. This fork fixes:

1. **Loading a file from the command-line argument** — the original `main` never
   called `getArgs` and always started from an empty buffer, so `./vih file`
   displayed nothing
2. **Saving with `:w`** — added file writing to the command-line handling;
   the file name is now threaded from `main` through `mainLoop` to `handleCommandLine`
3. **Rewrote `handleCommandLine` parsing with a `case` expression** — the original
   `head command` crashed on an empty input line (the original source even left
   the comment "aborts when line command is not parseable. Fix with exception catch");
   now handled safely with pattern matching
4. **Fixed ANSI escape sequences** — a stray space in `"; "` inside `goto` silently
   disabled the CSI cursor-position sequence, and `cls` did not reset the cursor
   to the origin
5. **Set stdout to `NoBuffering`** — so escape sequences no longer linger in the
   output buffer

## Known issues / TODO

- Query the actual terminal size and make `yExtent` dynamic
- Wrap or truncate lines longer than 80 columns
- Resolve the `[-Wx-partial]` warning on `tail` in `deleteChar`
- Arrow keys (escape-sequence input) support
- Undo

## License

MIT License — inherited from the original license.txt
(Copyright (c) 2009 Michael Feathers).
