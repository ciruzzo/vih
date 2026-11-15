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
| `/` + text | Search forward |
| `i` | Enter insert mode (`ESC` to leave) |
| `o` | Open a new line below and enter insert mode |
| `x` | Delete the character under the cursor |
| `r` + char | Replace the character under the cursor |
| `dd` | Delete the current line |
| `:` + command | Command line (`:w` = save, `:wq` = save & quit, `:q` = quit, digits = jump to line) |

## Building and running

Only GHC is required:

```sh
ghc --make -package terminal-size vih.hs
./vih somefile.txt
```

The editor queries the terminal size at startup (`System.Console.Terminal.Size`)
and adapts both its screen height and line width to your actual terminal. Any
reasonable terminal size works; there is no minimum requirement.

## Design notes

- **Pure core**: `EditBuffer` (buffer and cursor logic) is a fully pure module,
  so it can be tested with QuickCheck. All I/O lives in `vih.hs`, `Rendering.hs`
  and `Input.hs`.
- **Editor state**: the main loop threads a single `Editor` record (mode +
  session settings + buffer) instead of passing multiple parameters around.
  Simple single-key commands are dispatched via a key→function table
  (`keyActions` in EditBuffer.hs).
- **Terminal adaptation**: height and width are queried at startup. Lines
  longer than the terminal width are clamped (`take cols`), so one logical
  line always occupies exactly one physical row.

## Property tests for the pure core

On Ubuntu/Debian, install the test dependency as a distro package:

```sh
sudo apt install libghc-quickcheck2-dev
```

Note that this installs QuickCheck for the distro GHC, not for any GHC
installed via ghcup. Build and run the tests with the distro GHC:

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
   the file name is now threaded from `main` through `mainLoop` to the handler
3. **Rewrote command-line parsing with a `case` expression** — the original
   `head command` crashed on an empty input line (the original source even left
   the comment "aborts when line command is not parseable. Fix with exception
   catch"); now handled safely with pattern matching
4. **Fixed ANSI escape sequences** — a stray space in `"; "` inside `goto`
   silently disabled the CSI cursor-position sequence, and `cls` did not reset
   the cursor to the origin
5. **Set stdout to `NoBuffering`** — so escape sequences no longer linger in
   the output buffer
6. **Dynamic terminal adaptation** — replaced the hard-coded `yExtent = 40`
   with the terminal's real height (and real width for clamping long lines);
   fixed the `frame` scroll boundary so the cursor row stays visible at the
   bottom of the window
7. **Refactored the main loop around an `Editor` state record** — mode, session
   settings and buffer travel together, replacing long parameter chains;
   added forward search (`/`), `keyActions` dispatch table, and `:wq`

## Known issues / TODO

- Resolve the `[-Wx-partial]` warning on `tail` in `deleteChar`
- Arrow keys (escape-sequence input) support
- Undo
- `n`/`N` repeat-search (currently each `/` requires re-entering the pattern)
- No wrap-around in search: nothing happens if there is no match after the cursor

## License

MIT License — inherited from the original license.txt
(Copyright (c) 2009 Michael Feathers).
