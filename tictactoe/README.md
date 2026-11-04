# Tic-Tac-Toe for the Z80 Starter Kit

A two-player tic-tac-toe game written in PL/M-80, played on a terminal connected to the
Starter Kit's serial port. It's a PL/M-80 version of a small C program. Players take turns
typing a number from 1 to 9 to place an X or an O.

```
 1 | 2 | 3
---|---|---
 4 | 5 | 6
---|---|---
 7 | 8 | 9

Player 1 (X), enter a number (1-9):
```

## Requirements

- **The U33 CRT monitor.** The game talks to the terminal through the Z80-SIO that the U33
  monitor adds to the board, and it relies on the monitor having already set up the SIO and
  its baud rate.
- **RAM at 3000H-347BH.** The game is built to run at 3000H.
- **Intel ISIS-II tools to build it:** PL/M-80 V4.0 (`plm80`), `link`, `locate` and
  `objhex`, plus `plm80.lib`. The Makefile uses the native Linux builds from
  [c-ports](https://github.com/linuxha/c-ports).

## Building

```
make            # builds tic-tac-toe.hex and prints the entry point
make clean      # removes the build files
```

The Makefile expects c-ports in `~/dev/git/c-ports`, for `locate` and `plm80.lib`.
Override that or any tool path on the command line:

```
make CPORTS=/path/to/c-ports
make LOCATE=/path/to/locate PLMLIB=/path/to/plm80.lib
make RAMSTART=4000H         # build for a different load address
```

Notes on the build:
- `plm80` only accepts ISIS-style file names (up to 6 characters, no `-`), so the
  Makefile compiles a copy named `TICTAC.PLM`.
- `link` and `locate` look for lower-case file names, so the object file is renamed and
  `plm80.lib` is copied into the folder.
- `plm80` exits successfully even when there are compile errors, so the Makefile checks
  the listing and stops if there are any.
- The Linux `locate` file-search command has the same name as Intel's `locate`, so the
  Makefile runs Intel's by its full path.

## Memory map (RAMSTART = 3000H)

| Address | Contents |
|---|---|
| 3000H | `RESET` constant (address 0) |
| 3002H-3019H | `WINS` table of winning lines |
| 301AH-30E4H | text strings |
| **30E5H** | **entry point** (main program) |
| to 3450H | procedures (`CI`, `CO`, `PRINT`, `READNUM`, ...) |
| 3451H-3464H | stack |
| 3465H-347BH | variables |

The entry point isn't 3000H, because PL/M puts constants and strings ahead of the code.
`make` prints it, taken from the HEX file's end record.

## Loading and running

1. Load `tic-tac-toe.hex` into the board. It's an Intel HEX file, which both the U33
   monitor's `DOWN` command and ZBUG's cassette LOAD can read.
2. At the CRT monitor prompt, type `JP 30E5`.

When the game ends (a win or a draw), the program jumps to address 0, ZBUG's reset entry,
which restarts the monitors.

## Terminal I/O

`CI` (read a key) and `CO` (send a character) poll the SIO directly, using the same ports
as the U33 monitor:

| Port | Use |
|---|---|
| 95H | terminal data |
| 97H | terminal control / status |
| 94H | other serial port data (not used) |
| 96H | other serial port control / status (not used) |

Both select status register RR0 by writing 0 to 97H. `CI` waits for bit 0 (character
received) and returns the character with bit 7 cleared. `CO` waits for bit 2 (transmitter
empty) before writing.

The program disables interrupts as its first statement (`DISABLE`). The U33 monitor
reads the keyboard with an SIO interrupt routine, which would otherwise take keys before
`CI` sees them.

The program ends with `CALL RESET`, an indirect call to address 0, rather than
`GOTO 0`, which PL/M-80 V4.0 doesn't accept. This replaces the compiler's normal
`EI` / `HALT` at the end of a main program: after an interrupt, that would fall
through into `CI` and crash.
