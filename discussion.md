# ZBUG ROM disassembly discussion

Files produced: `zbug-u33.asm` (labelled U33 listing, repo root). Scratch files
(raw listings, disassembler `z80dis.py`, generator `u33gen.py`) were written to the
Claude scratchpad directory.

---

## 1. Input

> disassemble @zbug-u32.bin starting at address 0

## 1. Output

I've disassembled the whole 2 KB of `zbug-u32.bin` (0000–07FF), but the dump looks
corrupted, so most of the listing can't be trusted. Data bit 6 reads as 1 when it
should be 0 on many bytes. No Z80 disassembler was installed, so I wrote a small one
(`z80dis.py`).

**Why I think bit 6 is bad:**

| Read | Likely real value | What it should be |
|---|---|---|
| `71 C0 63` at 0000 | `31 C0 23` | `LD SP,23C0H`, the usual first instruction of a monitor |
| `58 43` after the RST vectors at 0008, 0010, 0018… | `18 03` | `JR +3`. The RST 28H vector at 002E has a clean `18 03`, so the bad bytes are the same thing with bit 6 set |
| `LD (63E2H),SP` / `LD (23E2H),IX` | `23E2H` | The same variable read two ways. There are 115 references to `23xx` and only 7 to `63xx`, so RAM is at `23xx` |
| `CALL 467CH` at 0087 | `CALL 063CH` | 65 calls go to `06xx` and only 4 to `46xx`. *(Corrected: I originally guessed `CALL 067CH`; the clean image in section 5 shows bit 6 was also wrong in the low byte.)* |
| `JP 40F4H` | `JP 00F4H` | `zbug-u33.bin` has a clean `JP 00F4H` at 0031 |

The errors only ever turn a 0 into a 1, and they're intermittent: the same byte reads
correctly in some places and wrong in others. That points to a marginal read (a weak or
floating D6 line, bad socket contact, or a timing problem) rather than a damaged ROM. I
can't repair it in software, because plenty of Z80 opcodes really do have bit 6 set
(all of 40–7F, C3, and others), so the bad bytes can't be told apart from the good ones.

**What I'd suggest:**
1. **Re-read U32 a few times and compare the dumps.** If the reads differ from each
   other, it's the reader or the contact. If they keep matching this file, suspect the
   chip. On a 2716/2516, D6 is pin 16, so check that contact and reseat the chip.
2. `zbug-u33.bin` looks clean by comparison. It starts with `JP 0909H` and its RAM
   references are consistently `23xx`, so it was probably read on a good pass.

Once you have a good dump of U32, I can redo the disassembly with code and data
separated (07B7–07F7 looks like keypad/display lookup tables) and labels for the RST
vectors and RAM variables.

---

## 2. Input

> disassemble @zbug-u33.bin starting at address 0800H

## 2. Output

I've disassembled all 2 KB of `zbug-u33.bin` (0800–0FFF). Unlike U32, this dump looks
clean: RAM references are consistently at `23xx`/`27xx`, the calls land on real routine
entry points, and the text strings are readable.

The disassembler decodes every byte as an instruction, so the data areas show up as
meaningless code. Here's what's code and what's data:

**Code highlights**
- **0800** `JP 0909H` is the cold-start entry. 0803 and 0807 are two more entry points
  that set D=0 or D=2, then share a loader at 0809.
- **0809–0906** is an interrupt-driven nibble loader: `HALT` waits for each interrupt
  and `RLC A` ×4 shifts nibbles together. It looks like the **DOWN**load path, with an
  option to add or subtract an offset (`SBC HL,BC`). It sets up `IM 2` and the
  interrupt vector at 089C, then initialises the peripherals:
  - The bytes at 08C0–08C9 are an init table sent to ports 97/96 with `OTIR`, not code.
  - Port 84 gets the values 05 and 0D.
- **0889** is an interrupt routine: it reads port 94, echoes it to port 95, converts
  ASCII hex to binary, then does `EI` / `RETI`.
- **089A** holds `89 08`, the IM 2 vector pointing at 0889. It's data, not
  `ADC A,C` / `EX AF,AF'`.
- **08D1–08F8** is a byte-by-byte copy loop that drives ports 86 and 8C around an
  `LDI` — almost certainly the EPROM programmer.
- **0909** is the CRT monitor main entry: banner and register dump
  ("MAIN REG / ALT. / SPEC REG"), prompt loop at 0985. 0C1B looks like print-string,
  0C0F prints CR/LF. At 09AC it uses `LD A,R` as a random number to pick an error
  message.
- The code relies on routines in U32 (`CALL 063CH`, `JP 00F4H`, `JP 0604H`).

**Data at 0E0C–0FFF (not code)**
```
0E0C  "Z80 CRT MONITOR VER 1.0 REV 1.1"
0E30  error messages chosen at random: "WRONG BUCKO!", "YOU LOSE!", "NO,STUPID!",
      "WHAT?", "NO,I WON'T!", "I CAN'T DO THAT!", "TRY AGAIN!", "SURE..MAYBE LATER!"
0E93  "THAT WAS FROM MYRON" / "MYRON MODE IS ON/OFF"
0EC3  "PORT xx HAS ", "BREAKPOINTS: ", "NO MORE!"
0EEA  "MAIN REG: ", "ALT.", "SPEC REG: "
0F09  command table: COPY, JP, OUT, MEM, RDTA, WRTA, EPRO(M), MYRO(N),
      DOWN, DUPL, REG …  (entries look like name + handler address)
```

---

## 3. Input

> yes, decode the command table and label the subroutines

## 3. Output

I wrote the labelled listing to `zbug-u33.asm` in the repo root. Every code address and
RAM variable now has a name, the data areas show as `DB`/`DW`, and the major routines
have a header comment. No Z80 assembler is installed here, so I haven't reassembled the
file to check it matches the ROM byte for byte.

**Command table (CMDTAB at 0F11)**

Each entry is the command name, a `00` byte, then the handler address. The lookup
routine at 0CBF compares the typed line against each name and jumps to its handler.

| Command | Handler | What it does |
|---|---|---|
| `S` | 0ADA `CMD_S` | Single step one instruction: jumps to ZBUG `CCS2` (0272H), the SS key handler. *(Corrected: I originally said it returned to the keypad monitor.)* |
| `BP [addr\|?]` | 0A6C `CMD_BP` | Set a breakpoint (up to 5, otherwise "NO MORE!"); `?` lists them; no argument clears them |
| `JP [addr]` | 09CB `CMD_JP` | Run or resume a program, using U32's resume code at 0247H |
| `LD rr` | 0B77 `CMD_LD` | Show one saved register and accept a new value |
| `IN pp` | 0A37 `CMD_IN` | Read a port and print "PORT pp HAS dd" |
| `OUT pp dd` | 0A58 `CMD_OUT` | Write a value to a port |
| `MEM addr` | 0B20 `CMD_MEM` | Examine/change memory: hex stores a byte, CR moves forward, `-` moves back |
| `RDTA..` | 0B5C `CMD_RDTAPE` | Read cassette (U32 0581H) |
| `WRTA..` | 0B62 `CMD_WRTAPE` | Write cassette from start to end address (U32 04CAH) |
| `EPRO.` | 0BEB `CMD_EPROM` | Program an EPROM: start, end, destination (routine at 08D1) |
| `MYRO.` | 0A04 `CMD_MYRON` | Turn "Myron mode" on or off: characters arriving on the second serial port are printed, so it works as a chat link to another terminal |
| `DOWN name [addr]` | 0AE4 `CMD_DOWN` | Send `COPY name` to the host on the second serial port, then receive the file with the loader, optionally relocated to `addr` |
| `DUPL..` | 0A26 `CMD_DUPLEX` | Toggle full/half duplex (echo) |
| `REG` | 09C4 `CMD_REG` | Display all registers |

**Five commands can't be typed as burned.** The names RDTA, WRTA, EPRO, MYRO and DUPL
are padded with `FF` bytes before the `00`. The input routine strips bit 7 from every
key, so a typed character can never be `FF` and those names can never match. The
padding fits RDTAPE, WRTAPE, EPROM, MYRON and DUPLEX exactly, so the full names were
probably meant to be burned in later and never were.

**Other tables**
- **REGTAB (0F6E):** for each register (AF, BC, DE, HL, PC, IX, IY, IF), a 3-character
  name and its position relative to the saved user stack pointer.
- **Interrupt vectors:** 089A points to `RXISR` (loader); 0F8E points to `CRTISR`
  (console/Myron handler).
- **SIOTAB (08C0):** 10 setup bytes for the serial chip. Ports 94–97 look like a Z80
  SIO: channel B (95/97) is the CRT console, channel A (94/96) is the host / Myron line.

**Probable bug at 099A:** after the built-in table, the prompt loop does
`LD HL,27E6H` and then tests whether HL is zero. The test always passes, so the monitor
always searches a command table at 27E6 in RAM. The author probably meant
`LD HL,(27E6H)`.

The names of the U32 routines (`U_xxxx`) are guesses from how this ROM uses them.

---

## 4. Input

> disassemble @zbug-u33.bin starting at address 0800H, note the bad addresses in the comments

## 4. Output

I've regenerated `zbug-u33.asm` (ORG 0800H) with every address checked against the
memory map and comments on the suspect ones, marked `!!`
(`grep '!!' zbug-u33.asm`).

Memory map from `Docs/RestorationSDS-Z80.pdf`: U32 at 0000–07FF, U33 at 0800–0FFF,
RAM at 2000–27FF.

**No address is out of range.** Every absolute address in U33 falls inside that map.
The values that look out of range (0004, 0020, 0060, 2000, FFF5) are counts or offsets.
Every jump and call target inside U33 lands on an instruction start or a known table.

**Addresses flagged `!!`:**

| Addr | Issue |
|---|---|
| 099A | `LD HL,27E6H` loads a fixed value, so the zero test at 099D can never be true; the RAM table at 27E6H is always searched. Almost certainly meant `LD HL,(27E6H)`. |
| 081E | `JP Z,00AEH` goes to U32. In the U32 dump the instruction at 00AE reads `CALL 46C6H`, outside the memory map — another bit-6 read error. *(Corrected: I guessed `CALL 06C6H`; the real instruction is `CALL 0686H`, ZBUG's `UFGCR`. 00AE is `RESTR1`, and the U33 code there is fine.)* |
| 0F35, 0F3E, 0F47, 0F4F, 0F5E | Command names RDTA, WRTA, EPRO, MYRO, DUPL are padded with `FF` and can never match typed input. |

**Unverified (noted, not flagged):** the other U32 entry points (00F4, 0247, 0272,
04CA, 0581, 0604, 063C, 0659, 06BB) each land on an instruction start and the code
there fits how U33 uses it (e.g. 06BB starts the hex-to-ASCII conversion). Because of
the bit-6 errors in the U32 dump they're marked "unverified" until there's a clean read.
*(Update: all ten are now verified against the clean ZBUG image and the original
listing — see section 6.)*

**Tight but correct (commented, not flagged):**
- The input buffer at 27E8H holds up to 24 characters, ending exactly at 27FFH, the
  last byte of RAM.
- MEM and LD keep their pointers at 27ECH and 27EEH, inside the input buffer; that works
  only because those commands limit input to 3 and 5 characters.
- At 0DC6 there's a deliberate `CALL` to a `RETI` to clear the SIO interrupt chain.
- At 0DE4 a stray `POP HL` is harmless because every path out reloads the stack pointer.

---

## 5. Input

> disassemble @t/SDS-Z80.BIN

## 5. Output

`t/SDS-Z80.BIN` is a clean copy of the ZBUG ROM in U32. It starts `31 C0 23`
(`LD SP,23C0H`), as predicted, and its RAM references are all `23xx`. (The file had no
permissions; I added read permission for the owner to read it.)

Compared with `zbug-u32.bin`, 72 bytes differ:
- **70 differ only in bit 6, and in every case the dump has it set.** That confirms the
  diagnosis: D6 reads as 1 when it shouldn't.
- **2 differ in bit 3 and look deliberate.** At 05DE and 05FE, ZBUG's PROM programmer
  has `LD HL,2000H`; this board's ROM has `LD HL,2800H` in both places. The original
  listing in the manual also has 2000H, so this is a local change, probably so the
  programmer copies from the extra RAM at 2800H.

Two of my earlier guesses were wrong because bit 6 was also bad in low bytes:

| Addr | Dump | I guessed | Actual |
|---|---|---|---|
| 0087 | `CALL 467CH` | `CALL 067CH` | `CALL 063CH` |
| 00AE | `CALL 46C6H` | `CALL 06C6H` | `CALL 0686H` |

`t/sdmonv21a.7z` and `Docs/Z80StarterKit-sdmon.mac.txt` are SD Monitor v2.10 for the
SBC-100/200, a different monitor, so they can't be used to check ZBUG.

---

## 6. Input

> do all three  *(correct the wrong guesses, build a repaired U32 image, make a labelled U32 listing)*

## 6. Output

- **`zbug-u32-repaired.bin`** is `t/SDS-Z80.BIN` with this board's two `2800H` bytes
  put back. Checked: it equals `zbug-u32.bin` with bit 6 cleared in exactly the 70 bad
  bytes, and every other byte is identical.
- **`zbug-u32.asm`** is now a labelled listing of the repaired image, using the label
  names from the original ZBUG listing in the Z80 Starter Kit manual, Appendix II
  (modules RESTR V1.7, DISUP V0.3, DECKY V2.1, UTIL V1.5). It decodes the jump table for
  the 12 command keys, the segment / key / register tables and the CTC vector table,
  and marks the two Mercer changes with `!!`. Checked: the byte column of the listing
  reproduces the repaired image exactly.
- **`zbug-u33.asm`** now uses the official ZBUG names for every call into U32 (`RESTR1`,
  `DISUP`, `CCS1A`, `CCS2`, `CCS10`, `CCS11`, `CCS12B`, `UFOR1`, `UFOR2`, `UBASC`) and
  for ZBUG's RAM variables. This fixed three mistakes:
  - The `S` command is single step (`CCS2`), not a return to the keypad monitor.
  - I had the tape start and end addresses swapped: `PUNHS` (23C0) is the start and
    `PUNHE` (23C2) is the end.
  - The 081E note said 00AE was probably `CALL 06C6H`; it's `CALL 0686H`.
- The wrong statements earlier in this file are corrected in place, marked *Corrected*.

Memory map from the manual (section 3-18): ZBUG 0000–07FF, PROM1 (U33) 0800–0FFF,
PROM2 / programmer socket (U34) 1000–17FF, RAM 2000–23FF plus optional 2400–27FF.
ZBUG uses 2390–23FF.
