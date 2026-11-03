;======================================================================
; ZBUG / Z80 CRT MONITOR VER 1.0 REV 1.1  --  U33 (0800H-0FFFH)
; Disassembled from zbug-u33.bin.  Labels and comments are inferred.
; Requires U32 (0000H-07FFH) for the routines named U_xxxx.
;
; Memory map (ESoCoP restoration notes): U32 0000-07FF, U33 0800-0FFF,
; RAM 2000-27FF.  Address check of this ROM:
;  - every absolute address is inside that map (0004/0020/0060/2000/
;    FFF5 are counts or offsets, not addresses)
;  - every jump/call target in U33 lands on an instruction start
;  - all 10 U32 targets land on instruction starts in the U32 dump,
;    but that dump has bit-6 read errors, so they are unverified
;  - '!!' marks suspect addresses: 099A (27E6H immediate), the five
;    command names padded with 0FFH, and 00AE in the U32 dump
;======================================================================

CR          EQU   000DH               
LF          EQU   000AH               
U_BRKRET    EQU   00AEH               ; U32: breakpoint/step return
U_KEYMON    EQU   00F4H               ; U32: keypad monitor main loop
U_RESUME    EQU   0247H               ; U32: restore registers and resume user program
U_KEYENT    EQU   0272H               ; U32: keypad monitor entry
U_WRTAPE    EQU   04CAH               ; U32: cassette write
U_RDTAPE    EQU   0581H               ; U32: cassette read
U_0604      EQU   0604H               ; U32: (after EPROM program)
U_DISPHEX   EQU   063CH               ; U32: put A as 2 hex digits in display buffer (IX)
U_PACK4     EQU   0659H               ; U32: pack 4 nibbles at 23F7H -> HL
U_HEXASC    EQU   06BBH               ; U32: low nibble of A -> ASCII
MONSTK      EQU   23A8H               ; RAM: monitor stack top when no user frame
TAPEEND     EQU   23C0H               ; RAM: tape end/start parameters (byte-swapped)
TAPESTART   EQU   23C2H               
EPRFLAG     EQU   23DAH               
USERSP      EQU   23E2H               ; RAM: saved user SP (register frame)
BPTAB       EQU   23E4H               ; RAM: breakpoint table, 3 bytes x 5
BPCOUNT     EQU   23F4H               ; RAM: number of breakpoints
DISPBUF     EQU   23F7H               ; RAM: keypad display / nibble buffer
CRTFLAGS    EQU   27E1H               ; RAM: b0 duplex, b1 Myron, b2 Myron line, b3 Myron col
GOADDR      EQU   27E2H               ; RAM: target for GOTRAMP
MONSP       EQU   27E4H               ; RAM: monitor SP at prompt
USRCMDTAB   EQU   27E6H               ; RAM: optional user command table (see PROMPT)
LINEBUF     EQU   27E8H               ; RAM: input line buffer
MEMPTR      EQU   27ECH               ; RAM: MEM command pointer
REGPTR      EQU   27EEH               ; RAM: LD command register pointer

CTC0        EQU   84H
CTC2        EQU   86H
PORT8C      EQU   8CH
PORT90      EQU   90H
SIOAD       EQU   94H
SIOBD       EQU   95H
SIOAC       EQU   96H
SIOBC       EQU   97H
PORT98      EQU   98H

            ORG   0800H


; ------------------------------------------------------------
; Cold start vector -> MONINIT
; ------------------------------------------------------------
COLD:       JP MONINIT                  ; 0800  C3 09 09

; ------------------------------------------------------------
; Serial loader entry: load at addresses in the file (D=0)
; ------------------------------------------------------------
LOADABS:    LD D,00H                    ; 0803  16 00
            JR LOADER                   ; 0805  18 02

; ------------------------------------------------------------
; Serial loader entry: relocate load to address in BC (D=2)
; ------------------------------------------------------------
LOADREL:    LD D,02H                    ; 0807  16 02

; ------------------------------------------------------------
; Common loader: set up SIO/IM2, receive records, show end addr
; ------------------------------------------------------------
LOADER:     EXX                         ; 0809  D9
            LD HL,LDVEC                 ; 080A  21 9A 08
            CALL SIOINIT                ; 080D  CD 9C 08
            LD A,01H                    ; 0810  3E 01
            OUT (SIOBC),A               ; 0812  D3 97
            DEC A                       ; 0814  3D
            OUT (SIOBC),A               ; 0815  D3 97
            EI                          ; 0817  FB
            CALL LDREC                  ; 0818  CD 34 08
            CALL SIORST                 ; 081B  CD CA 08
            JP Z,U_BRKRET               ; 081E  CA AE 00  !! U32 dump here reads CALL 46C6H - bit-6 error, probably CALL 06C6H
            LD IX,DISPBUF               ; 0821  DD 21 F7 23
            LD A,H                      ; 0825  7C
            CALL U_DISPHEX              ; 0826  CD 3C 06  -> U32 (unverified: U32 dump has bit-6 read errors)
            INC IX                      ; 0829  DD 23
            INC IX                      ; 082B  DD 23
            LD A,L                      ; 082D  7D
            CALL U_DISPHEX              ; 082E  CD 3C 06  -> U32 (unverified: U32 dump has bit-6 read errors)
            JP U_KEYMON                 ; 0831  C3 F4 00  -> U32 (unverified: U32 dump has bit-6 read errors)

; ------------------------------------------------------------
; Wait for record start (nibble value 3), read 3-byte header
; ------------------------------------------------------------
LDREC:      HALT                        ; 0834  76
            SUB 03H                     ; 0835  D6 03
            JR NZ,LDREC                 ; 0837  20 FB
            LD D,A                      ; 0839  57
            CALL GETBYTE                ; 083A  CD 77 08
            LD E,A                      ; 083D  5F
            CALL GETBYTE                ; 083E  CD 77 08
            LD H,A                      ; 0841  67
            CALL GETBYTE                ; 0842  CD 77 08
            LD L,A                      ; 0845  6F
            PUSH HL                     ; 0846  E5
            EXX                         ; 0847  D9
            POP HL                      ; 0848  E1
            BIT 1,D                     ; 0849  CB 4A
            JR Z,LDHDR2                 ; 084B  28 10
            BIT 0,D                     ; 084D  CB 42
            JR NZ,085AH                 ; 084F  20 09
            PUSH HL                     ; 0851  E5
            OR A                        ; 0852  B7
            SBC HL,BC                   ; 0853  ED 42
            PUSH HL                     ; 0855  E5
            POP BC                      ; 0856  C1
            POP HL                      ; 0857  E1
            SET 0,D                     ; 0858  CB C2
            OR A                        ; 085A  B7
            SBC HL,BC                   ; 085B  ED 42
LDHDR2:     EXX                         ; 085D  D9
            CALL GETBYTE                ; 085E  CD 77 08
            DEC A                       ; 0861  3D
            RET Z                       ; 0862  C8

; ------------------------------------------------------------
; Store data bytes of the record
; ------------------------------------------------------------
LDDATA:     CALL GETBYTE                ; 0863  CD 77 08
            EXX                         ; 0866  D9
            LD (HL),A                   ; 0867  77
            INC HL                      ; 0868  23
            EXX                         ; 0869  D9
            DEC E                       ; 086A  1D
            JR NZ,LDDATA                ; 086B  20 F6
            LD E,D                      ; 086D  5A
            CALL GETBYTE                ; 086E  CD 77 08
            NEG                         ; 0871  ED 44
            CP E                        ; 0873  BB
            RET NZ                      ; 0874  C0
            JR LDREC                    ; 0875  18 BD

; ------------------------------------------------------------
; Assemble a byte from two nibbles delivered by RXISR; D += byte (checksum)
; ------------------------------------------------------------
GETBYTE:    HALT                        ; 0877  76
            RLC A                       ; 0878  CB 07
            RLC A                       ; 087A  CB 07
            RLC A                       ; 087C  CB 07
            RLC A                       ; 087E  CB 07
            LD C,A                      ; 0880  4F
            HALT                        ; 0881  76
            LD B,A                      ; 0882  47
            OR C                        ; 0883  B1
            ADD A,D                     ; 0884  82
            LD D,A                      ; 0885  57
            LD A,B                      ; 0886  78
            OR C                        ; 0887  B1
            RET                         ; 0888  C9

; ------------------------------------------------------------
; SIO-A Rx interrupt: read char, echo to console, ASCII hex -> nibble in A
; ------------------------------------------------------------
RXISR:      IN A,(SIOAD)                ; 0889  DB 94
            OUT (SIOBD),A               ; 088B  D3 95
            AND 7FH                     ; 088D  E6 7F
            SUB 30H                     ; 088F  D6 30
            CP 0AH                      ; 0891  FE 0A
            JR C,0897H                  ; 0893  38 02
            SUB 07H                     ; 0895  D6 07
            EI                          ; 0897  FB
            RETI                        ; 0898  ED 4D

; ------------------------------------------------------------
; IM 2 vector table used by the loader
; ------------------------------------------------------------
LDVEC:      DW    RXISR                 ; 089A  89 08  -> RXISR

; ------------------------------------------------------------
; Init SIO (both channels) from SIOTAB; I=H, vector=L; CTC ch0 setup
; ------------------------------------------------------------
SIOINIT:    CALL SIORST                 ; 089C  CD CA 08
            IM 2                        ; 089F  ED 5E
            LD A,H                      ; 08A1  7C
            LD I,A                      ; 08A2  ED 47
            LD C,97H                    ; 08A4  0E 97
            LD A,02H                    ; 08A6  3E 02
            OUT (C),A                   ; 08A8  ED 79
            OUT (C),L                   ; 08AA  ED 69
            LD B,0AH                    ; 08AC  06 0A
            LD HL,SIOTAB                ; 08AE  21 C0 08
            OTIR                        ; 08B1  ED B3
            DEC C                       ; 08B3  0D
            DEC A                       ; 08B4  3D
            JR NZ,08ACH                 ; 08B5  20 F5
            LD A,05H                    ; 08B7  3E 05
            OUT (CTC0),A                ; 08B9  D3 84
            LD A,0DH                    ; 08BB  3E 0D
            OUT (CTC0),A                ; 08BD  D3 84
            RET                         ; 08BF  C9

; ------------------------------------------------------------
; SIO initialisation bytes (sent with OTIR to 97H then 96H)
; ------------------------------------------------------------
SIOTAB:     DB    10H,04H,86H,03H,0C1H,05H,6AH,10H,01H,18H; 08C0  10 04 86 03 C1 05 6A 10 01 18  WR0/WR4/WR3/WR5/WR1 pairs

; ------------------------------------------------------------
; Channel-reset both SIO channels (WR0=18H)
; ------------------------------------------------------------
SIORST:     LD A,18H                    ; 08CA  3E 18
            OUT (SIOBC),A               ; 08CC  D3 97
            OUT (SIOAC),A               ; 08CE  D3 96
            RET                         ; 08D0  C9

; ------------------------------------------------------------
; EPROM programmer: copy BC=src..end to DE, pulsing via CTC/PIO
; ------------------------------------------------------------
EPROG:      PUSH BC                     ; 08D1  C5
            INC HL                      ; 08D2  23
            OR A                        ; 08D3  B7
            SBC HL,BC                   ; 08D4  ED 42
            PUSH HL                     ; 08D6  E5
            POP BC                      ; 08D7  C1
            POP HL                      ; 08D8  E1
            JR C,EPRDONE                ; 08D9  38 29
            JR Z,EPRDONE                ; 08DB  28 27
            PUSH DE                     ; 08DD  D5
            PUSH HL                     ; 08DE  E5
            PUSH BC                     ; 08DF  C5
EPRLP:      LD A,25H                    ; 08E0  3E 25
            OUT (CTC2),A                ; 08E2  D3 86
            LD A,0CBH                   ; 08E4  3E CB
            OUT (CTC2),A                ; 08E6  D3 86
            LD A,80H                    ; 08E8  3E 80
            OUT (PORT8C),A              ; 08EA  D3 8C
            LDI                         ; 08EC  ED A0
            LD A,00H                    ; 08EE  3E 00
            OUT (PORT8C),A              ; 08F0  D3 8C
            LD A,03H                    ; 08F2  3E 03
            OUT (CTC2),A                ; 08F4  D3 86
            JP PE,EPRLP                 ; 08F6  EA E0 08
            POP BC                      ; 08F9  C1
            POP HL                      ; 08FA  E1
            POP DE                      ; 08FB  D1
            LD A,01H                    ; 08FC  3E 01
            LD (EPRFLAG),A              ; 08FE  32 DA 23
            JP U_0604                   ; 0901  C3 04 06  -> U32 (unverified: U32 dump has bit-6 read errors)
EPRDONE:    PUSH BC                     ; 0904  C5
            POP HL                      ; 0905  E1
            JP 0821H                    ; 0906  C3 21 08

; ------------------------------------------------------------
; CRT monitor entry: init CRT SIO, banner or register dump
; ------------------------------------------------------------
MONINIT:    CALL CRTINIT                ; 0909  CD 7B 0D
            XOR A                       ; 090C  AF
            OUT (PORT98),A              ; 090D  D3 98
            LD HL,MONSTK                ; 090F  21 A8 23
            SBC HL,SP                   ; 0912  ED 72
            JR NZ,BRKENT                ; 0914  20 15
            LD HL,(USERSP)              ; 0916  2A E2 23
            DEC HL                      ; 0919  2B
            DEC HL                      ; 091A  2B
            LD (USERSP),HL              ; 091B  22 E2 23
            DEC SP                      ; 091E  3B
            DEC SP                      ; 091F  3B
            LD (CRTFLAGS),A             ; 0920  32 E1 27
            LD HL,MSGBANNER             ; 0923  21 0C 0E
            CALL PUTS                   ; 0926  CD 1B 0C
            JR PROMPT                   ; 0929  18 5A

; ------------------------------------------------------------
; Entered from a breakpoint/RST: tidy flags then dump registers
; ------------------------------------------------------------
BRKENT:     LD BC,0FFF5H                ; 092B  01 F5 FF
            LD HL,(USERSP)              ; 092E  2A E2 23
            ADD HL,BC                   ; 0931  09
            LD A,(HL)                   ; 0932  7E
            AND 04H                     ; 0933  E6 04
            LD (HL),A                   ; 0935  77
            CALL CRLF                   ; 0936  CD 0F 0C

; ------------------------------------------------------------
; Print MAIN / ALT. / SPEC register lines
; ------------------------------------------------------------
SHOWREGS:   LD HL,MSGMAIN               ; 0939  21 EA 0E
            CALL PUTS                   ; 093C  CD 1B 0C
            LD HL,(USERSP)              ; 093F  2A E2 23
            LD DE,REGTAB                ; 0942  11 6E 0F
            PUSH HL                     ; 0945  E5
            PUSH HL                     ; 0946  E5
            PUSH HL                     ; 0947  E5
            PUSH DE                     ; 0948  D5
            LD C,00H                    ; 0949  0E 00
            CALL PRREGS                 ; 094B  CD 59 0D
            CALL CRLF                   ; 094E  CD 0F 0C
            POP DE                      ; 0951  D1
            LD HL,MSGALT                ; 0952  21 F5 0E
            CALL PUTS                   ; 0955  CD 1B 0C
            LD HL,MSGREG                ; 0958  21 EE 0E
            CALL PUTS                   ; 095B  CD 1B 0C
            POP HL                      ; 095E  E1
            LD C,0F6H                   ; 095F  0E F6
            CALL PRREGS                 ; 0961  CD 59 0D
            CALL CRLF                   ; 0964  CD 0F 0C
            LD HL,MSGSPEC               ; 0967  21 FA 0E
            CALL PUTS                   ; 096A  CD 1B 0C
            POP HL                      ; 096D  E1
            LD C,00H                    ; 096E  0E 00
            CALL PRREGS                 ; 0970  CD 59 0D
            LD HL,MSGSPEQ               ; 0973  21 05 0F
            CALL PUTS                   ; 0976  CD 1B 0C
            POP HL                      ; 0979  E1
            LD B,H                      ; 097A  44
            LD C,L                      ; 097B  4D
            CALL PRHEX4                 ; 097C  CD 2A 0D
            CALL CRLF                   ; 097F  CD 0F 0C
            OR A                        ; 0982  B7

; ------------------------------------------------------------
; Return point pushed for every command (Cy=1 -> error message)
; ------------------------------------------------------------
CMDRET:     JR C,CMDERR                 ; 0983  38 22

; ------------------------------------------------------------
; Main loop: prompt '-', read a line, dispatch command
; ------------------------------------------------------------
PROMPT:     LD (MONSP),SP               ; 0985  ED 73 E4 27
            LD A,2DH                    ; 0989  3E 2D
            CALL PUTCH                  ; 098B  CD 4B 0D
            CALL GETLINE                ; 098E  CD 49 0C
            LD HL,CMDTAB                ; 0991  21 11 0F
            LD DE,LINEBUF               ; 0994  11 E8 27
            CALL CMDLOOKUP              ; 0997  CD BF 0C
            LD HL,USRCMDTAB             ; 099A  21 E6 27  !! BAD: immediate LD HL,27E6H - H|L test below is always NZ, so the RAM table at 27E6H is always searched; probably meant LD HL,(27E6H)
            LD A,H                      ; 099D  7C  !! always non-zero (see 099A)
            OR L                        ; 099E  B5
            JR Z,CMDERR                 ; 099F  28 06
            LD DE,LINEBUF               ; 09A1  11 E8 27
            CALL CMDLOOKUP              ; 09A4  CD BF 0C

; ------------------------------------------------------------
; Print a random insult (LD A,R) from MSGERR list
; ------------------------------------------------------------
CMDERR:     LD A,07H                    ; 09A7  3E 07
            CALL PUTCH                  ; 09A9  CD 4B 0D
            LD A,R                      ; 09AC  ED 5F
            AND 07H                     ; 09AE  E6 07
            LD B,A                      ; 09B0  47
            INC B                       ; 09B1  04
            LD HL,MSGERR                ; 09B2  21 2F 0E
ERRSKIP:    LD A,(HL)                   ; 09B5  7E
            OR A                        ; 09B6  B7
            INC HL                      ; 09B7  23
            JR NZ,ERRSKIP               ; 09B8  20 FB
            DJNZ ERRSKIP                ; 09BA  10 F9
            CALL PUTS                   ; 09BC  CD 1B 0C
            CALL CRLF                   ; 09BF  CD 0F 0C
            JR PROMPT                   ; 09C2  18 C1

; ------------------------------------------------------------
; REG  - display registers
; ------------------------------------------------------------
CMD_REG:    CP 0DH                      ; 09C4  FE 0D
            RET C                       ; 09C6  D8
            POP BC                      ; 09C7  C1
            JP SHOWREGS                 ; 09C8  C3 39 09

; ------------------------------------------------------------
; JP [addr] - resume/go via U32 restart code
; ------------------------------------------------------------
CMD_JP:     CP 0DH                      ; 09CB  FE 0D
            JR Z,JPRESUME               ; 09CD  28 0D
            INC DE                      ; 09CF  13
            CALL GETHEX4                ; 09D0  CD E9 0C
            RET C                       ; 09D3  D8
            CALL SETGO                  ; 09D4  CD E2 09
            LD (GOADDR),HL              ; 09D7  22 E2 27
            JR JPGO                     ; 09DA  18 03
JPRESUME:   CALL SETGO                  ; 09DC  CD E2 09
JPGO:       JP U_RESUME                 ; 09DF  C3 47 02  -> U32 (unverified: U32 dump has bit-6 read errors)

; ------------------------------------------------------------
; Patch saved PC on user stack to GOTRAMP, remember old PC in GOADDR
; ------------------------------------------------------------
SETGO:      PUSH HL                     ; 09E2  E5
            LD HL,(USERSP)              ; 09E3  2A E2 23
            DEC HL                      ; 09E6  2B
            LD D,(HL)                   ; 09E7  56
            LD (HL),09H                 ; 09E8  36 09
            DEC HL                      ; 09EA  2B
            LD E,(HL)                   ; 09EB  5E
            LD (HL),0F6H                ; 09EC  36 F6
            EX DE,HL                    ; 09EE  EB
            LD (GOADDR),HL              ; 09EF  22 E2 27
            POP HL                      ; 09F2  E1
            JP SIOOFF                   ; 09F3  C3 41 0C

; ------------------------------------------------------------
; Trampoline: switch port 98H, then jump to (GOADDR)
; ------------------------------------------------------------
GOTRAMP:    PUSH AF                     ; 09F6  F5
            IN A,(PORT90)               ; 09F7  DB 90
            LD A,01H                    ; 09F9  3E 01
            OUT (PORT98),A              ; 09FB  D3 98
            POP AF                      ; 09FD  F1
            PUSH HL                     ; 09FE  E5
            LD HL,(GOADDR)              ; 09FF  2A E2 27
            EX (SP),HL                  ; 0A02  E3
            RET                         ; 0A03  C9

; ------------------------------------------------------------
; MYRON - toggle Myron (talk to SIO-A terminal) mode, flag bit 1
; ------------------------------------------------------------
CMD_MYRON:  LD HL,MSGMYMODE             ; 0A04  21 A9 0E
            CALL PUTS                   ; 0A07  CD 1B 0C
            BIT 1,(IX+00H)              ; 0A0A  DD CB 00 4E
            JR Z,MYRON_ON               ; 0A0E  28 0B
            RES 1,(IX+00H)              ; 0A10  DD CB 00 8E
            LD HL,MSGOFF                ; 0A14  21 B8 0E
            CALL PUTS                   ; 0A17  CD 1B 0C
            RET                         ; 0A1A  C9
MYRON_ON:   SET 1,(IX+00H)              ; 0A1B  DD CB 00 CE
            LD HL,MSGON                 ; 0A1F  21 BE 0E
            CALL PUTS                   ; 0A22  CD 1B 0C
            RET                         ; 0A25  C9

; ------------------------------------------------------------
; DUPLEX - toggle duplex flag bit 0
; ------------------------------------------------------------
CMD_DUPLEX: OR A                        ; 0A26  B7
            BIT 0,(IX+00H)              ; 0A27  DD CB 00 46
            JR Z,DUPL_ON                ; 0A2B  28 05
            RES 0,(IX+00H)              ; 0A2D  DD CB 00 86
            RET                         ; 0A31  C9
DUPL_ON:    SET 0,(IX+00H)              ; 0A32  DD CB 00 C6
            RET                         ; 0A36  C9

; ------------------------------------------------------------
; IN pp - read a port, print 'PORT pp HAS dd'
; ------------------------------------------------------------
CMD_IN:     CALL EXPSP                  ; 0A37  CD 30 0C
            CALL GETHEX2                ; 0A3A  CD 10 0D
            RET C                       ; 0A3D  D8
            IN D,(C)                    ; 0A3E  ED 50
            LD HL,MSGPORT               ; 0A40  21 C3 0E
            CALL PUTS                   ; 0A43  CD 1B 0C
            LD B,C                      ; 0A46  41
            CALL PRHEX2                 ; 0A47  CD 32 0D
            LD HL,MSGHAS                ; 0A4A  21 C9 0E
            CALL PUTS                   ; 0A4D  CD 1B 0C
            LD B,D                      ; 0A50  42
            CALL PRHEX2                 ; 0A51  CD 32 0D
            CALL CRLF                   ; 0A54  CD 0F 0C
            RET                         ; 0A57  C9

; ------------------------------------------------------------
; OUT pp dd - write a port
; ------------------------------------------------------------
CMD_OUT:    CALL EXPSP                  ; 0A58  CD 30 0C
            CALL GETHEX2                ; 0A5B  CD 10 0D
            RET C                       ; 0A5E  D8
            LD A,(DE)                   ; 0A5F  1A
            CALL EXPSP                  ; 0A60  CD 30 0C
            PUSH BC                     ; 0A63  C5
            CALL GETHEX2                ; 0A64  CD 10 0D
            POP DE                      ; 0A67  D1
            RET C                       ; 0A68  D8
            OUT (C),E                   ; 0A69  ED 59
            RET                         ; 0A6B  C9

; ------------------------------------------------------------
; BP [addr|?] - set / list / clear (no arg) breakpoints, max 5
; ------------------------------------------------------------
CMD_BP:     CP 0DH                      ; 0A6C  FE 0D
            JR Z,BPCLEAR                ; 0A6E  28 3E
            CALL EXPSP                  ; 0A70  CD 30 0C
            LD A,(DE)                   ; 0A73  1A
            CP 3FH                      ; 0A74  FE 3F
            JR Z,BPLIST                 ; 0A76  28 3A
            CALL GETHEX4                ; 0A78  CD E9 0C
            RET C                       ; 0A7B  D8
            LD IY,BPTAB                 ; 0A7C  FD 21 E4 23
            PUSH HL                     ; 0A80  E5
            CALL SHOWBPS                ; 0A81  CD B9 0A
            POP HL                      ; 0A84  E1
            JR Z,BPSTORE                ; 0A85  28 14
            CP 05H                      ; 0A87  FE 05
            JR C,BPSLOT                 ; 0A89  38 07
            LD HL,MSGNOMORE             ; 0A8B  21 DD 0E
            CALL PUTS                   ; 0A8E  CD 1B 0C
            RET                         ; 0A91  C9
BPSLOT:     LD B,A                      ; 0A92  47
BPSLOT1:    INC IY                      ; 0A93  FD 23
            INC IY                      ; 0A95  FD 23
            INC IY                      ; 0A97  FD 23
            DJNZ BPSLOT1                ; 0A99  10 F8
BPSTORE:    INC A                       ; 0A9B  3C
            LD (BPCOUNT),A              ; 0A9C  32 F4 23
            LD (IY+00H),H               ; 0A9F  FD 74 00
            LD (IY+01H),L               ; 0AA2  FD 75 01
            LD B,H                      ; 0AA5  44
            LD C,L                      ; 0AA6  4D
            CALL PRHEX4                 ; 0AA7  CD 2A 0D
            CALL CRLF                   ; 0AAA  CD 0F 0C
            RET                         ; 0AAD  C9
BPCLEAR:    XOR A                       ; 0AAE  AF
            LD (BPCOUNT),A              ; 0AAF  32 F4 23
BPLIST:     CALL SHOWBPS                ; 0AB2  CD B9 0A
            CALL CRLF                   ; 0AB5  CD 0F 0C
            RET                         ; 0AB8  C9

; ------------------------------------------------------------
; Print 'BREAKPOINTS: ' and each address in BPTAB
; ------------------------------------------------------------
SHOWBPS:    LD HL,MSGBPS                ; 0AB9  21 CF 0E
            CALL PUTS                   ; 0ABC  CD 1B 0C
            LD A,(BPCOUNT)              ; 0ABF  3A F4 23
            OR A                        ; 0AC2  B7
            RET Z                       ; 0AC3  C8
            LD HL,BPTAB                 ; 0AC4  21 E4 23
            PUSH AF                     ; 0AC7  F5
SHOWBP1:    PUSH AF                     ; 0AC8  F5
            LD B,(HL)                   ; 0AC9  46
            INC HL                      ; 0ACA  23
            LD C,(HL)                   ; 0ACB  4E
            INC HL                      ; 0ACC  23
            INC HL                      ; 0ACD  23
            CALL PRHEX4                 ; 0ACE  CD 2A 0D
            CALL PRSPACE                ; 0AD1  CD 49 0D
            POP AF                      ; 0AD4  F1
            DEC A                       ; 0AD5  3D
            JR NZ,SHOWBP1               ; 0AD6  20 F0
            POP AF                      ; 0AD8  F1
            RET                         ; 0AD9  C9

; ------------------------------------------------------------
; S - leave CRT monitor, back to U32 keypad monitor
; ------------------------------------------------------------
CMD_S:      CP 0DH                      ; 0ADA  FE 0D
            SCF                         ; 0ADC  37
            RET NZ                      ; 0ADD  C0
            CALL TOKEYPAD               ; 0ADE  CD 3B 0C
            JP U_KEYENT                 ; 0AE1  C3 72 02  -> U32 (unverified: U32 dump has bit-6 read errors)

; ------------------------------------------------------------
; DOWN name [addr] - send 'COPY name' to host on SIO-A, then load
; ------------------------------------------------------------
CMD_DOWN:   CALL EXPSP                  ; 0AE4  CD 30 0C
DOWN1:      LD A,(DE)                   ; 0AE7  1A
            CP 20H                      ; 0AE8  FE 20
            JR Z,DOWNADR                ; 0AEA  28 0C
            CP 0DH                      ; 0AEC  FE 0D
            JR Z,DOWNNA                 ; 0AEE  28 03
            INC DE                      ; 0AF0  13
            JR DOWN1                    ; 0AF1  18 F4
DOWNNA:     XOR A                       ; 0AF3  AF
            LD (DE),A                   ; 0AF4  12
            SCF                         ; 0AF5  37
            JR DOWNGO                   ; 0AF6  18 07
DOWNADR:    XOR A                       ; 0AF8  AF
            LD (DE),A                   ; 0AF9  12
            INC DE                      ; 0AFA  13
            CALL GETHEX4                ; 0AFB  CD E9 0C
            RET C                       ; 0AFE  D8
DOWNGO:     PUSH AF                     ; 0AFF  F5
            PUSH HL                     ; 0B00  E5
            LD DE,LINEBUF               ; 0B01  11 E8 27
            PUSH DE                     ; 0B04  D5
            LD HL,STRCOPY               ; 0B05  21 09 0F
            LD BC,0004H                 ; 0B08  01 04 00
            LDIR                        ; 0B0B  ED B0
            POP HL                      ; 0B0D  E1
            CALL PUTS2                  ; 0B0E  CD 24 0C
            LD HL,STRCRSP               ; 0B11  21 0D 0F
            CALL PUTS2                  ; 0B14  CD 24 0C
            POP BC                      ; 0B17  C1
            POP AF                      ; 0B18  F1
            POP HL                      ; 0B19  E1
            JP C,LOADABS                ; 0B1A  DA 03 08
            JP LOADREL                  ; 0B1D  C3 07 08

; ------------------------------------------------------------
; MEM addr - examine/modify memory ('-' back, CR next, hh store)
; ------------------------------------------------------------
CMD_MEM:    CALL EXPSP                  ; 0B20  CD 30 0C
            CALL GETHEX4                ; 0B23  CD E9 0C
            RET C                       ; 0B26  D8
MEMLP:      LD (MEMPTR),HL              ; 0B27  22 EC 27  MEMPTR (27ECH) is inside LINEBUF; OK only because MEM input is limited to C=3
            LD B,H                      ; 0B2A  44
            LD C,L                      ; 0B2B  4D
            CALL PRHEX4                 ; 0B2C  CD 2A 0D
            CALL PRSPACE                ; 0B2F  CD 49 0D
            LD B,(HL)                   ; 0B32  46
            CALL PRHEX2                 ; 0B33  CD 32 0D
            CALL PRSPACE                ; 0B36  CD 49 0D
            LD C,03H                    ; 0B39  0E 03
            LD A,5EH                    ; 0B3B  3E 5E
            CALL GETLN_C                ; 0B3D  CD 6A 0C
            LD DE,LINEBUF               ; 0B40  11 E8 27
            LD HL,(MEMPTR)              ; 0B43  2A EC 27
            LD A,(DE)                   ; 0B46  1A
            CP 0DH                      ; 0B47  FE 0D
            JR Z,MEMNXT                 ; 0B49  28 0B
            CP 2DH                      ; 0B4B  FE 2D
            JR Z,MEMPRV                 ; 0B4D  28 0A
            PUSH HL                     ; 0B4F  E5
            CALL GETHEX2                ; 0B50  CD 10 0D
            POP HL                      ; 0B53  E1
            RET C                       ; 0B54  D8
            LD (HL),C                   ; 0B55  71
MEMNXT:     INC HL                      ; 0B56  23
            JR MEMLP                    ; 0B57  18 CE
MEMPRV:     DEC HL                      ; 0B59  2B
            JR MEMLP                    ; 0B5A  18 CB

; ------------------------------------------------------------
; RDTAPE - read cassette (U32 routine)
; ------------------------------------------------------------
CMD_RDTAPE: CALL SIOOFF                 ; 0B5C  CD 41 0C
            JP U_RDTAPE                 ; 0B5F  C3 81 05  -> U32 (unverified: U32 dump has bit-6 read errors)

; ------------------------------------------------------------
; WRTAPE start end - write cassette (U32 routine)
; ------------------------------------------------------------
CMD_WRTAPE: CALL GET2ADDR               ; 0B62  CD FF 0B
            RET C                       ; 0B65  D8
            LD A,H                      ; 0B66  7C
            LD H,L                      ; 0B67  65
            LD L,A                      ; 0B68  6F
            LD (TAPESTART),HL           ; 0B69  22 C2 23
            LD L,B                      ; 0B6C  68
            LD H,C                      ; 0B6D  61
            LD (TAPEEND),HL             ; 0B6E  22 C0 23
            CALL SIOOFF                 ; 0B71  CD 41 0C
            JP U_WRTAPE                 ; 0B74  C3 CA 04  -> U32 (unverified: U32 dump has bit-6 read errors)

; ------------------------------------------------------------
; LD rr - show register from REGTAB and accept a new value
; ------------------------------------------------------------
CMD_LD:     CALL EXPSP                  ; 0B77  CD 30 0C
            LD HL,REGTAB                ; 0B7A  21 6E 0F
            LD BC,0020H                 ; 0B7D  01 20 00
LDFIND:     LD A,(DE)                   ; 0B80  1A
            CPIR                        ; 0B81  ED B1
            JR Z,LDCHK2                 ; 0B83  28 02
            SCF                         ; 0B85  37
            RET                         ; 0B86  C9
LDCHK2:     INC DE                      ; 0B87  13
            LD A,(DE)                   ; 0B88  1A
            CPI                         ; 0B89  ED A1
            JR Z,LDFOUND                ; 0B8B  28 03
            DEC DE                      ; 0B8D  1B
            JR LDFIND                   ; 0B8E  18 F0
LDFOUND:    DEC HL                      ; 0B90  2B
            DEC HL                      ; 0B91  2B
            LD B,02H                    ; 0B92  06 02
LDPNAME:    LD A,(HL)                   ; 0B94  7E
            CALL PUTCH                  ; 0B95  CD 4B 0D
            INC HL                      ; 0B98  23
            DJNZ LDPNAME                ; 0B99  10 F9
            INC HL                      ; 0B9B  23
            LD A,(HL)                   ; 0B9C  7E
            CP 0F7H                     ; 0B9D  FE F7
            PUSH AF                     ; 0B9F  F5
            JR C,LDOFS                  ; 0BA0  38 13
            CP 0FFH                     ; 0BA2  FE FF
            JR Z,LDOFS                  ; 0BA4  28 0F
            INC DE                      ; 0BA6  13
            LD A,(DE)                   ; 0BA7  1A
            CP 27H                      ; 0BA8  FE 27
            JR NZ,LDOFS                 ; 0BAA  20 09
            CALL PUTCH                  ; 0BAC  CD 4B 0D
            POP AF                      ; 0BAF  F1
            LD A,(HL)                   ; 0BB0  7E
            SUB 0AH                     ; 0BB1  D6 0A
            JR LDOFS1                   ; 0BB3  18 01
LDOFS:      POP AF                      ; 0BB5  F1
LDOFS1:     LD C,A                      ; 0BB6  4F
            LD B,0FFH                   ; 0BB7  06 FF
            LD HL,(USERSP)              ; 0BB9  2A E2 23
            ADD HL,BC                   ; 0BBC  09
            LD A,3DH                    ; 0BBD  3E 3D
            CALL PUTCH                  ; 0BBF  CD 4B 0D
            LD B,(HL)                   ; 0BC2  46
            DEC HL                      ; 0BC3  2B
            LD C,(HL)                   ; 0BC4  4E
            CALL PRHEX4                 ; 0BC5  CD 2A 0D
            CALL PRSPACE                ; 0BC8  CD 49 0D
            LD C,05H                    ; 0BCB  0E 05
            LD (REGPTR),HL              ; 0BCD  22 EE 27  REGPTR (27EEH) is inside LINEBUF; OK only because LD input is limited to C=5
            LD A,5EH                    ; 0BD0  3E 5E
            CALL GETLN_C                ; 0BD2  CD 6A 0C
            CALL GETHEXB                ; 0BD5  CD E6 0C
            JR C,LDNOVAL                ; 0BD8  38 09
            PUSH HL                     ; 0BDA  E5
            POP BC                      ; 0BDB  C1
            LD HL,(REGPTR)              ; 0BDC  2A EE 27
            LD (HL),C                   ; 0BDF  71
            INC HL                      ; 0BE0  23
            LD (HL),B                   ; 0BE1  70
            RET                         ; 0BE2  C9
LDNOVAL:    LD A,(LINEBUF)              ; 0BE3  3A E8 27
            CP 0DH                      ; 0BE6  FE 0D
            RET Z                       ; 0BE8  C8
            SCF                         ; 0BE9  37
            RET                         ; 0BEA  C9

; ------------------------------------------------------------
; EPROM start end dest - program EPROM
; ------------------------------------------------------------
CMD_EPROM:  CALL GET2ADDR               ; 0BEB  CD FF 0B
            RET C                       ; 0BEE  D8
            CALL NEXTSP                 ; 0BEF  CD 2F 0C
            PUSH BC                     ; 0BF2  C5
            PUSH HL                     ; 0BF3  E5
            CALL GETHEX4                ; 0BF4  CD E9 0C
            POP BC                      ; 0BF7  C1
            POP DE                      ; 0BF8  D1
            RET C                       ; 0BF9  D8
            EX (SP),HL                  ; 0BFA  E3
            POP HL                      ; 0BFB  E1
            JP EPROG                    ; 0BFC  C3 D1 08

; ------------------------------------------------------------
; Parse ' hhhh hhhh' -> BC=first, HL=second
; ------------------------------------------------------------
GET2ADDR:   CALL EXPSP                  ; 0BFF  CD 30 0C
            CALL GETHEX4                ; 0C02  CD E9 0C
            RET C                       ; 0C05  D8
            CALL NEXTSP                 ; 0C06  CD 2F 0C
            PUSH HL                     ; 0C09  E5
            CALL GETHEX4                ; 0C0A  CD E9 0C
            POP BC                      ; 0C0D  C1
            RET                         ; 0C0E  C9

; ------------------------------------------------------------
; Print CR LF (returns Cy=0)
; ------------------------------------------------------------
CRLF:       LD A,0DH                    ; 0C0F  3E 0D
            CALL PUTCH                  ; 0C11  CD 4B 0D
            LD A,0AH                    ; 0C14  3E 0A
            CALL PUTCH                  ; 0C16  CD 4B 0D
            OR A                        ; 0C19  B7
            RET                         ; 0C1A  C9

; ------------------------------------------------------------
; Print 0-terminated string at HL to console
; ------------------------------------------------------------
PUTS:       LD A,(HL)                   ; 0C1B  7E
            OR A                        ; 0C1C  B7
            RET Z                       ; 0C1D  C8
            CALL PUTCH                  ; 0C1E  CD 4B 0D
            INC HL                      ; 0C21  23
            JR PUTS                     ; 0C22  18 F7

; ------------------------------------------------------------
; Print string at HL to console AND send to SIO-A (host)
; ------------------------------------------------------------
PUTS2:      LD A,(HL)                   ; 0C24  7E
            OR A                        ; 0C25  B7
            RET Z                       ; 0C26  C8
            CALL PUTCH                  ; 0C27  CD 4B 0D
            OUT (SIOAD),A               ; 0C2A  D3 94
            INC HL                      ; 0C2C  23
            JR PUTS2                    ; 0C2D  18 F5

; ------------------------------------------------------------
; A=(DE), then fall into EXPSP
; ------------------------------------------------------------
NEXTSP:     LD A,(DE)                   ; 0C2F  1A

; ------------------------------------------------------------
; Require a space at (DE) (DE++), else abort to CMDERR
; ------------------------------------------------------------
EXPSP:      CP 20H                      ; 0C30  FE 20
            INC DE                      ; 0C32  13
            RET Z                       ; 0C33  C8
            LD SP,(MONSP)               ; 0C34  ED 7B E4 27
            JP CMDERR                   ; 0C38  C3 A7 09

; ------------------------------------------------------------
; Out 1 to 8CH and 98H, then SIOOFF
; ------------------------------------------------------------
TOKEYPAD:   LD A,01H                    ; 0C3B  3E 01
            OUT (PORT8C),A              ; 0C3D  D3 8C
            OUT (PORT98),A              ; 0C3F  D3 98

; ------------------------------------------------------------
; Reset SIO and drop CMDRET from the stack (no return to prompt)
; ------------------------------------------------------------
SIOOFF:     CALL SIORST                 ; 0C41  CD CA 08
            POP BC                      ; 0C44  C1
            EX (SP),HL                  ; 0C45  E3
            POP HL                      ; 0C46  E1
            PUSH BC                     ; 0C47  C5
            RET                         ; 0C48  C9

; ------------------------------------------------------------
; Read a line into LINEBUF (interrupt driven, HALT waits)
; ------------------------------------------------------------
GETLINE:    DI                          ; 0C49  F3
            LD IX,CRTFLAGS              ; 0C4A  DD 21 E1 27
            RES 2,(IX+00H)              ; 0C4E  DD CB 00 96
            BIT 1,(IX+00H)              ; 0C52  DD CB 00 4E
            JR Z,GLWAIT                 ; 0C56  28 04
            SET 2,(IX+00H)              ; 0C58  DD CB 00 D6
GLWAIT:     EI                          ; 0C5C  FB
            HALT                        ; 0C5D  76
            BIT 2,(IX+00H)              ; 0C5E  DD CB 00 56
            JR Z,GLSTART                ; 0C62  28 04
            CP 5EH                      ; 0C64  FE 5E
            JR NZ,GLLOOP                ; 0C66  20 0B
GLSTART:    LD C,18H                    ; 0C68  0E 18  max line 18H chars: LINEBUF 27E8H..27FFH = last byte of RAM, no margin

; ------------------------------------------------------------
; Enter with C=max length, A=first char
; ------------------------------------------------------------
GETLN_C:    LD HL,LINEBUF               ; 0C6A  21 E8 27
            LD B,00H                    ; 0C6D  06 00
            RES 2,(IX+00H)              ; 0C6F  DD CB 00 96
GLLOOP:     BIT 2,(IX+00H)              ; 0C73  DD CB 00 56
            PUSH AF                     ; 0C77  F5
            JR Z,GLLOCAL                ; 0C78  28 04
            OUT (SIOAD),A               ; 0C7A  D3 94
            JR GLCHR                    ; 0C7C  18 03
GLLOCAL:    CALL EDITCHR                ; 0C7E  CD 96 0C
GLCHR:      POP AF                      ; 0C81  F1
            CP 0DH                      ; 0C82  FE 0D
            JR Z,GLEOL                  ; 0C84  28 04
            EI                          ; 0C86  FB
            HALT                        ; 0C87  76
            JR GLLOOP                   ; 0C88  18 E9
GLEOL:      LD A,0AH                    ; 0C8A  3E 0A
            CALL PUTCH                  ; 0C8C  CD 4B 0D
            BIT 2,(IX+00H)              ; 0C8F  DD CB 00 56
            JR NZ,GLWAIT                ; 0C93  20 C7
            RET                         ; 0C95  C9

; ------------------------------------------------------------
; Store char in buffer, handle BS(08H); ignore ctrl and '^'
; ------------------------------------------------------------
EDITCHR:    CP 08H                      ; 0C96  FE 08
            JR Z,EDBS                   ; 0C98  28 18
            CP 0DH                      ; 0C9A  FE 0D
            JR Z,EDSTORE                ; 0C9C  28 06
            CP 20H                      ; 0C9E  FE 20
            RET C                       ; 0CA0  D8
            CP 5EH                      ; 0CA1  FE 5E
            RET Z                       ; 0CA3  C8
EDSTORE:    LD (HL),A                   ; 0CA4  77
            INC HL                      ; 0CA5  23
            INC B                       ; 0CA6  04
            LD A,B                      ; 0CA7  78
            CP C                        ; 0CA8  B9
            RET C                       ; 0CA9  D8
            DEC HL                      ; 0CAA  2B
            DEC B                       ; 0CAB  05
            LD A,08H                    ; 0CAC  3E 08
            CALL PUTCH                  ; 0CAE  CD 4B 0D
            RET                         ; 0CB1  C9
EDBS:       DEC HL                      ; 0CB2  2B
            DEC B                       ; 0CB3  05
            BIT 7,B                     ; 0CB4  CB 78
            RET Z                       ; 0CB6  C8
            INC HL                      ; 0CB7  23
            INC B                       ; 0CB8  04
            LD A,0CH                    ; 0CB9  3E 0C
            CALL PUTCH                  ; 0CBB  CD 4B 0D
            RET                         ; 0CBE  C9

; ------------------------------------------------------------
; Match LINEBUF (DE) against table at HL; jump to handler with CMDRET pushed
; ------------------------------------------------------------
CMDLOOKUP:  PUSH DE                     ; 0CBF  D5
CLCMP:      LD A,(DE)                   ; 0CC0  1A
            CPI                         ; 0CC1  ED A1
            JR NZ,CLSKIP                ; 0CC3  20 07
            LD A,(HL)                   ; 0CC5  7E
            OR A                        ; 0CC6  B7
            JR Z,CLFOUND                ; 0CC7  28 0F
            INC DE                      ; 0CC9  13
            JR CLCMP                    ; 0CCA  18 F4
CLSKIP:     XOR A                       ; 0CCC  AF
CLSKIP1:    CPI                         ; 0CCD  ED A1
            JR NZ,CLSKIP1               ; 0CCF  20 FC
            POP DE                      ; 0CD1  D1
            INC HL                      ; 0CD2  23
            INC HL                      ; 0CD3  23
            CP (HL)                     ; 0CD4  BE
            RET Z                       ; 0CD5  C8
            JR CMDLOOKUP                ; 0CD6  18 E7
CLFOUND:    POP BC                      ; 0CD8  C1
            INC HL                      ; 0CD9  23
            LD C,(HL)                   ; 0CDA  4E
            INC HL                      ; 0CDB  23
            LD B,(HL)                   ; 0CDC  46
            INC DE                      ; 0CDD  13
            LD A,(DE)                   ; 0CDE  1A
            POP HL                      ; 0CDF  E1
            LD HL,CMDRET                ; 0CE0  21 83 09
            PUSH HL                     ; 0CE3  E5
            PUSH BC                     ; 0CE4  C5
            RET                         ; 0CE5  C9

; ------------------------------------------------------------
; GETHEX4 from start of LINEBUF
; ------------------------------------------------------------
GETHEXB:    LD DE,LINEBUF               ; 0CE6  11 E8 27

; ------------------------------------------------------------
; Parse 4 hex digits at DE -> HL (via U32 0659H), Cy=1 on error
; ------------------------------------------------------------
GETHEX4:    LD B,04H                    ; 0CE9  06 04
            LD HL,DISPBUF               ; 0CEB  21 F7 23
GH4LP:      CALL HEXDIG                 ; 0CEE  CD F8 0C
            RET C                       ; 0CF1  D8
            DJNZ GH4LP                  ; 0CF2  10 FA
            CALL U_PACK4                ; 0CF4  CD 59 06  -> U32 (unverified: U32 dump has bit-6 read errors)
            RET                         ; 0CF7  C9

; ------------------------------------------------------------
; ASCII hex at (DE) -> nibble at (HL); DE++,HL++; Cy=1 if not hex
; ------------------------------------------------------------
HEXDIG:     LD A,(DE)                   ; 0CF8  1A
            SUB 30H                     ; 0CF9  D6 30
            RET M                       ; 0CFB  F8
            CP 0AH                      ; 0CFC  FE 0A
            JR C,HDOK                   ; 0CFE  38 0B
            CP 11H                      ; 0D00  FE 11
            RET C                       ; 0D02  D8
            SUB 07H                     ; 0D03  D6 07
            CP 10H                      ; 0D05  FE 10
            JR C,HDOK                   ; 0D07  38 02
            CCF                         ; 0D09  3F
            RET                         ; 0D0A  C9
HDOK:       LD (HL),A                   ; 0D0B  77
            INC DE                      ; 0D0C  13
            INC HL                      ; 0D0D  23
            OR A                        ; 0D0E  B7
            RET                         ; 0D0F  C9

; ------------------------------------------------------------
; Parse 2 hex digits at DE -> C, Cy=1 on error
; ------------------------------------------------------------
GETHEX2:    PUSH DE                     ; 0D10  D5
            POP HL                      ; 0D11  E1
            LD B,02H                    ; 0D12  06 02
GH2LP:      CALL HEXDIG                 ; 0D14  CD F8 0C
            RET C                       ; 0D17  D8
            DJNZ GH2LP                  ; 0D18  10 FA
            DEC HL                      ; 0D1A  2B
            DEC HL                      ; 0D1B  2B
            LD C,(HL)                   ; 0D1C  4E
            SLA C                       ; 0D1D  CB 21
            SLA C                       ; 0D1F  CB 21
            SLA C                       ; 0D21  CB 21
            SLA C                       ; 0D23  CB 21
            INC HL                      ; 0D25  23
            LD A,(HL)                   ; 0D26  7E
            OR C                        ; 0D27  B1
            LD C,A                      ; 0D28  4F
            RET                         ; 0D29  C9

; ------------------------------------------------------------
; Print BC as 4 hex digits
; ------------------------------------------------------------
PRHEX4:     CALL PRHEX2                 ; 0D2A  CD 32 0D
            LD B,C                      ; 0D2D  41
            CALL PRHEX2                 ; 0D2E  CD 32 0D
            RET                         ; 0D31  C9

; ------------------------------------------------------------
; Print B as 2 hex digits
; ------------------------------------------------------------
PRHEX2:     LD A,B                      ; 0D32  78
            SRL A                       ; 0D33  CB 3F
            SRL A                       ; 0D35  CB 3F
            SRL A                       ; 0D37  CB 3F
            SRL A                       ; 0D39  CB 3F
            CALL U_HEXASC               ; 0D3B  CD BB 06  -> U32 (unverified: U32 dump has bit-6 read errors)
            CALL PUTCH                  ; 0D3E  CD 4B 0D
            LD A,B                      ; 0D41  78
            CALL U_HEXASC               ; 0D42  CD BB 06  -> U32 (unverified: U32 dump has bit-6 read errors)
            CALL PUTCH                  ; 0D45  CD 4B 0D
            RET                         ; 0D48  C9

; ------------------------------------------------------------
; Print a space
; ------------------------------------------------------------
PRSPACE:    LD A,20H                    ; 0D49  3E 20

; ------------------------------------------------------------
; Print A on console (SIO-B), waits for Tx empty
; ------------------------------------------------------------
PUTCH:      PUSH AF                     ; 0D4B  F5
            XOR A                       ; 0D4C  AF
PUTCHW:     OUT (SIOBC),A               ; 0D4D  D3 97
            IN A,(SIOBC)                ; 0D4F  DB 97
            AND 04H                     ; 0D51  E6 04
            JR Z,PUTCHW                 ; 0D53  28 F8
            POP AF                      ; 0D55  F1
            OUT (SIOBD),A               ; 0D56  D3 95
            RET                         ; 0D58  C9

; ------------------------------------------------------------
; Print 4 regs: names from table DE, values from frame HL, C=offset adj
; ------------------------------------------------------------
PRREGS:     LD B,04H                    ; 0D59  06 04
PRREG1:     PUSH BC                     ; 0D5B  C5
            LD B,03H                    ; 0D5C  06 03
PRNAME:     LD A,(DE)                   ; 0D5E  1A
            CALL PUTCH                  ; 0D5F  CD 4B 0D
            INC DE                      ; 0D62  13
            DJNZ PRNAME                 ; 0D63  10 F9
            LD A,(DE)                   ; 0D65  1A
            ADD A,C                     ; 0D66  81
            LD C,A                      ; 0D67  4F
            LD B,0FFH                   ; 0D68  06 FF
            PUSH HL                     ; 0D6A  E5
            ADD HL,BC                   ; 0D6B  09
            LD B,(HL)                   ; 0D6C  46
            DEC HL                      ; 0D6D  2B
            LD C,(HL)                   ; 0D6E  4E
            CALL PRHEX4                 ; 0D6F  CD 2A 0D
            POP HL                      ; 0D72  E1
            INC DE                      ; 0D73  13
            CALL PRSPACE                ; 0D74  CD 49 0D
            POP BC                      ; 0D77  C1
            DJNZ PRREG1                 ; 0D78  10 E1
            RET                         ; 0D7A  C9

; ------------------------------------------------------------
; Init SIO with CRT interrupt vector table CRTVEC
; ------------------------------------------------------------
CRTINIT:    LD HL,CRTVEC                ; 0D7B  21 8E 0F
            CALL SIOINIT                ; 0D7E  CD 9C 08
            RET                         ; 0D81  C9

; ------------------------------------------------------------
; SIO interrupt: console key or Myron char from SIO-A
; ------------------------------------------------------------
CRTISR:     XOR A                       ; 0D82  AF
            OUT (SIOAC),A               ; 0D83  D3 96
            IN A,(SIOAC)                ; 0D85  DB 96
            RRCA                        ; 0D87  0F
            JR C,MYRCHR                 ; 0D88  38 49
            IN A,(SIOBD)                ; 0D8A  DB 95
            AND 7FH                     ; 0D8C  E6 7F
            JR Z,CRTBRK                 ; 0D8E  28 14
            BIT 0,(IX+00H)              ; 0D90  DD CB 00 46
            JR Z,ISRRET                 ; 0D94  28 0C
            PUSH AF                     ; 0D96  F5
            LD A,08H                    ; 0D97  3E 08
            CALL PUTCH                  ; 0D99  CD 4B 0D
            LD A,23H                    ; 0D9C  3E 23
            CALL PUTCH                  ; 0D9E  CD 4B 0D
            POP AF                      ; 0DA1  F1

; ------------------------------------------------------------
; EI-less RETI
; ------------------------------------------------------------
ISRRET:     RETI                        ; 0DA2  ED 4D

; ------------------------------------------------------------
; Null/break from console: optional break to SIO-A, back to PROMPT
; ------------------------------------------------------------
CRTBRK:     LD A,(CRTFLAGS)             ; 0DA4  3A E1 27
            AND 02H                     ; 0DA7  E6 02
            JR Z,TOPROMPT               ; 0DA9  28 1B
            LD A,05H                    ; 0DAB  3E 05
            OUT (SIOAC),A               ; 0DAD  D3 96
            LD A,7AH                    ; 0DAF  3E 7A
            OUT (SIOAC),A               ; 0DB1  D3 96
            PUSH BC                     ; 0DB3  C5
            LD BC,2000H                 ; 0DB4  01 00 20
            DEC C                       ; 0DB7  0D
            JR NZ,0DB7H                 ; 0DB8  20 FD
            DEC B                       ; 0DBA  05
            JR NZ,0DB7H                 ; 0DBB  20 FA
            POP BC                      ; 0DBD  C1
            LD A,05H                    ; 0DBE  3E 05
            OUT (SIOAC),A               ; 0DC0  D3 96
            LD A,6AH                    ; 0DC2  3E 6A
            OUT (SIOAC),A               ; 0DC4  D3 96
TOPROMPT:   CALL ISRRET                 ; 0DC6  CD A2 0D  CALL to a RETI on purpose - clears the SIO interrupt daisy chain
            CALL CRLF                   ; 0DC9  CD 0F 0C

; ------------------------------------------------------------
; Restore monitor SP and re-enter PROMPT
; ------------------------------------------------------------
ABORT:      LD SP,(MONSP)               ; 0DCC  ED 7B E4 27
            JP 0989H                    ; 0DD0  C3 89 09

; ------------------------------------------------------------
; Char from SIO-A (Myron): print it
; ------------------------------------------------------------
MYRCHR:     IN A,(SIOAD)                ; 0DD3  DB 94
            BIT 3,(IX+00H)              ; 0DD5  DD CB 00 5E
            JR NZ,MYRCHR1               ; 0DD9  20 09
            CALL CRLF                   ; 0DDB  CD 0F 0C
            SET 3,(IX+00H)              ; 0DDE  DD CB 00 DE
            JR MYRCHR2                  ; 0DE2  18 01
MYRCHR1:    POP HL                      ; 0DE4  E1  POP HL drops a stack word; harmless, every path ends at ABORT which reloads SP
MYRCHR2:    CALL PUTCH                  ; 0DE5  CD 4B 0D
            LD A,38H                    ; 0DE8  3E 38
            OUT (SIOAC),A               ; 0DEA  D3 96
            CALL ISRRET                 ; 0DEC  CD A2 0D
            LD BC,0060H                 ; 0DEF  01 60 00
            EI                          ; 0DF2  FB
MYRDLY:     DEC B                       ; 0DF3  05
            JR NZ,MYRDLY                ; 0DF4  20 FD
            DEC C                       ; 0DF6  0D
            JR NZ,MYRDLY                ; 0DF7  20 FA
            DI                          ; 0DF9  F3
            RES 3,(IX+00H)              ; 0DFA  DD CB 00 9E
            BIT 2,(IX+00H)              ; 0DFE  DD CB 00 56
            JR NZ,TOPROMPT              ; 0E02  20 C2
MYRDONE:    LD HL,MSGMYRON              ; 0E04  21 93 0E
            CALL PUTS                   ; 0E07  CD 1B 0C
            JR ABORT                    ; 0E0A  18 C0
MSGBANNER:  DB    CR,LF,'Z80 CRT MONITOR VER 1.0 REV 1.1',CR,LF,00H; 0E0C  0D 0A 5A 38 ..
            DB    'WRONG BUCKO!',00H    ; 0E30  57 52 4F 4E ..
            DB    'YOU LOSE!',00H       ; 0E3D  59 4F 55 20 ..
            DB    'NO,STUPID!',00H      ; 0E47  4E 4F 2C 53 ..
            DB    'WHAT?',00H           ; 0E52  57 48 41 54 ..
            DB    'NO,I WON',27H,'T!',00H; 0E58  4E 4F 2C 49 ..
            DB    'I CAN',27H,'T DO THAT!',00H; 0E64  49 20 43 41 ..
            DB    'TRY AGAIN!',00H      ; 0E75  54 52 59 20 ..
            DB    'SURE..MAYBE LATER!',00H; 0E80  53 55 52 45 ..
MSGMYRON:   DB    'THAT WAS FROM MYRON',CR,LF,00H; 0E93  54 48 41 54 ..
MSGMYMODE:  DB    'MYRON MODE IS ',00H  ; 0EA9  4D 59 52 4F ..
MSGOFF:     DB    'OFF',CR,LF,00H       ; 0EB8  4F 46 46 0D ..
MSGON:      DB    'ON',CR,LF,00H        ; 0EBE  4F 4E 0D 0A ..
MSGPORT:    DB    'PORT ',00H           ; 0EC3  50 4F 52 54 ..
MSGHAS:     DB    ' HAS ',00H           ; 0EC9  20 48 41 53 ..
MSGBPS:     DB    'BREAKPOINTS: ',00H   ; 0ECF  42 52 45 41 ..
MSGNOMORE:  DB    CR,LF,'NO MORE!',CR,LF,00H; 0EDD  0D 0A 4E 4F ..
MSGMAIN:    DB    'MAIN'                ; 0EEA  4D 41 49 4E
MSGREG:     DB    ' REG: ',00H          ; 0EEE  20 52 45 47 ..
MSGALT:     DB    'ALT.',00H            ; 0EF5  41 4C 54 2E ..
MSGSPEC:    DB    'SPEC REG: ',00H      ; 0EFA  53 50 45 43 ..
MSGSPEQ:    DB    'SP=',00H             ; 0F05  53 50 3D 00

; ------------------------------------------------------------
; 'COPY' copied to LINEBUF by DOWN, then '\r  ' sent
; ------------------------------------------------------------
STRCOPY:    DB    'COPY'                ; 0F09  43 4F 50 59
STRCRSP:    DB    CR,'  ',0             ; 0F0D  0D 20 20 00

; ------------------------------------------------------------
; Command table: name, 0, DW handler ... terminated by 0
; ------------------------------------------------------------
CMDTAB:     DB    'S',0                 ; 0F11  53 00 DA 0A
            DW    CMD_S                 
            DB    'BP',0                ; 0F15  42 50 00 6C 0A
            DW    CMD_BP                
            DB    'JP',0                ; 0F1A  4A 50 00 CB 09
            DW    CMD_JP                
            DB    'LD',0                ; 0F1F  4C 44 00 77 0B
            DW    CMD_LD                
            DB    'IN',0                ; 0F24  49 4E 00 37 0A
            DW    CMD_IN                
            DB    'OUT',0               ; 0F29  4F 55 54 00 58 0A
            DW    CMD_OUT               
            DB    'MEM',0               ; 0F2F  4D 45 4D 00 20 0B
            DW    CMD_MEM               
            DB    'RDTA',0FFH,0FFH,0    ; 0F35  52 44 54 41 FF FF 00 5C 0B  !! contains 0FFH - can never match typed input
            DW    CMD_RDTAPE            
            DB    'WRTA',0FFH,0FFH,0    ; 0F3E  57 52 54 41 FF FF 00 62 0B  !! contains 0FFH - can never match typed input
            DW    CMD_WRTAPE            
            DB    'EPRO',0FFH,0         ; 0F47  45 50 52 4F FF 00 EB 0B  !! contains 0FFH - can never match typed input
            DW    CMD_EPROM             
            DB    'MYRO',0FFH,0         ; 0F4F  4D 59 52 4F FF 00 04 0A  !! contains 0FFH - can never match typed input
            DW    CMD_MYRON             
            DB    'DOWN',0              ; 0F57  44 4F 57 4E 00 E4 0A
            DW    CMD_DOWN              
            DB    'DUPL',0FFH,0FFH,0    ; 0F5E  44 55 50 4C FF FF 00 26 0A  !! contains 0FFH - can never match typed input
            DW    CMD_DUPLEX            
            DB    'REG',0               ; 0F67  52 45 47 00 C4 09
            DW    CMD_REG               
            DB    0                     ; 0F6D  00  end of table

; ------------------------------------------------------------
; Register table: 3-char name, frame offset (from USERSP)
; ------------------------------------------------------------
REGTAB:     DB    'AF=',0FDH            ; 0F6E  41 46 3D FD  offset -3
            DB    'BC=',0FBH            ; 0F72  42 43 3D FB  offset -5
            DB    'DE=',0F9H            ; 0F76  44 45 3D F9  offset -7
            DB    'HL=',0F7H            ; 0F7A  48 4C 3D F7  offset -9
            DB    'PC=',0FFH            ; 0F7E  50 43 3D FF  offset -1
            DB    'IX=',0EBH            ; 0F82  49 58 3D EB  offset -21
            DB    'IY=',0E9H            ; 0F86  49 59 3D E9  offset -23
            DB    'IF=',0F5H            ; 0F8A  49 46 3D F5  offset -11

; ------------------------------------------------------------
; IM 2 vector table used by the CRT monitor
; ------------------------------------------------------------
CRTVEC:     DW    CRTISR                ; 0F8E  82 0D  -> CRTISR

; ------------------------------------------------------------
; Unused (erased) to end of ROM
; ------------------------------------------------------------
FREE:       DS    70H,0FFH              ; 0F90  FF ..  0F90-0FFF

            END
