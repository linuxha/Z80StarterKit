;======================================================================
; ZBUG MONITOR  --  U32 (0000H-07FFH)
; (C) 1978 Micro Design Concepts, for the S.D. Systems Z80 Starter Kit
;
; Disassembled from zbug-u32-repaired.bin.  Labels and comments follow
; the original listing in the Z80 Starter Kit Operations Manual,
; Appendix II (modules RESTR V1.7, DISUP V0.3, DECKY V2.1, UTIL V1.5).
;
; zbug-u32-repaired.bin = t/SDS-Z80.BIN (a clean ZBUG image) with this
; board's two local changes at 05E0H/0600H (LD HL,2800H instead of
; 2000H, marked '!!').  It equals the original U32 dump zbug-u32.bin
; with the bad bit 6 cleared in the 70 bytes where the dump read it as 1.
;
; Memory map (manual 3-18): ZBUG 0000-07FF, PROM1 (U33) 0800-0FFF,
; PROM2/programmer (U34) 1000-17FF, RAM 2000-23FF (+ optional 2400-27FF);
; ZBUG uses 2390H-23FFH.
;======================================================================

CTC0      EQU   84H           ; CTC channel 0 - reserved for user / interrupt vector
CTC1      EQU   85H           ; CTC channel 1 - cassette punch
CTC2      EQU   86H           ; CTC channel 2 - single step and PROM programmer
CTC3      EQU   87H           ; CTC channel 3 - cassette load
SEGLH     EQU   88H           ; write only - segment latch
DIGLH     EQU   8CH           ; write only - digit select (bit 7 = PROM program enable)
KBSEL     EQU   90H           ; read only - keyboard columns, sense switch, cassette data
PROM1     EQU   0800H         ; PROM1 socket (U33)
ZBUGSP    EQU   23A8H         ; ZBUG stack top
USERSP    EQU   23C0H         ; initial user SP
PUNHSH    EQU   23C0H         ; punch start address, high
PUNHSL    EQU   23C1H         ; punch start address, low
PUNHEH    EQU   23C2H         ; punch end address, high
PUNHEL    EQU   23C3H         ; punch end address, low
RST16     EQU   23C4H         ; RAM jump targets for RST 10H..38H
RST24     EQU   23C7H         
RST32     EQU   23CAH         
RST40     EQU   23CDH         
RST48     EQU   23D0H         
RST56     EQU   23D3H         
CTC0U     EQU   23D6H         ; RAM target for CTC channel 0 interrupt
FLG24     EQU   23D9H         ; punch bit flag
PRFLG     EQU   23DAH         ; PROM programming mode
KEYPTR    EQU   23DBH         ; next DISMEM digit for a hex key
UIF       EQU   23DDH         ; user IFF (4 or 0)
PFLG      EQU   23DEH         ; port examine mode
RFLG      EQU   23DFH         ; register display mode
ARFLG     EQU   23E0H         ; alternate register display mode
MFLG      EQU   23E1H         ; memory examine mode
STKPT     EQU   23E2H         ; saved user SP
STKPT1    EQU   23E3H         
BPTAB     EQU   23E4H         ; breakpoint table: 5 x (addr hi, addr lo, op code)
SSFLG     EQU   23F3H         ; single step mode
BFLG      EQU   23F4H         ; number of breakpoints
DIG2      EQU   23F5H         ; 2 digits entered
DIG4      EQU   23F6H         ; 4 digits entered
DISMEM    EQU   23F7H         ; display memory, 8 digits DISMEM..DSMEM7
DSMEM1    EQU   23F8H         
DSMEM2    EQU   23F9H         
DSMEM3    EQU   23FAH         
DSMEM4    EQU   23FBH         
DSMEM5    EQU   23FCH         
DSMEM6    EQU   23FDH         
DSMEM7    EQU   23FEH         

          ORG   0000H

; ----------------------------------------------------------------
; RESTR module (V1.7): RST, NMI and breakpoint routines
; RST 0 = reset entry: set ZBUG stack, finish init at RESTAR
; ----------------------------------------------------------------
RST0:     LD SP,PUNHSH              ; 0000  31 C0 23
          JP RESTAR                 ; 0003  C3 9F 00  U32 dump read C3 DF 40
          DB    0FFH,0FFH           ; 0006  FF FF  unused

; ----------------------------------------------------------------
; RST 8 = breakpoint entry: save user SP and stack all registers.
; RST 10H-38H jump to RAM (RST16..RST56) and are interleaved
; with the BPENTn register-save chain
; ----------------------------------------------------------------
BPENT:    LD (STKPT),SP             ; 0008  ED 73 E2 23
          PUSH AF                   ; 000C  F5
          PUSH BC                   ; 000D  C5
          JR BPENT2                 ; 000E  18 03
          JP RST16                  ; 0010  C3 C4 23
BPENT2:   LD A,I                    ; 0013  ED 57
          DI                        ; 0015  F3
          JR BPENT3                 ; 0016  18 03
          JP RST24                  ; 0018  C3 C7 23
BPENT3:   PUSH DE                   ; 001B  D5
          PUSH HL                   ; 001C  E5
          PUSH AF                   ; 001D  F5
          JR BPENT4                 ; 001E  18 03
          JP RST32                  ; 0020  C3 CA 23
BPENT4:   EX AF,AF'                 ; 0023  08
          EXX                       ; 0024  D9
          PUSH AF                   ; 0025  F5
          JR BPENT5                 ; 0026  18 03
          JP RST40                  ; 0028  C3 CD 23
BPENT5:   PUSH BC                   ; 002B  C5
          PUSH DE                   ; 002C  D5
          PUSH HL                   ; 002D  E5
          JR BPENT6                 ; 002E  18 03
          JP RST48                  ; 0030  C3 D0 23
BPENT6:   PUSH IX                   ; 0033  DD E5
          NOP                       ; 0035  00
          JR BPENT7                 ; 0036  18 03
          JP RST56                  ; 0038  C3 D3 23
BPENT7:   PUSH IY                   ; 003B  FD E5
          LD A,03H                  ; 003D  3E 03
          OUT (CTC2),A              ; 003F  D3 86
          LD IX,(STKPT)             ; 0041  DD 2A E2 23
          INC IX                    ; 0045  DD 23
          INC IX                    ; 0047  DD 23
          LD (STKPT),IX             ; 0049  DD 22 E2 23
          LD A,(IX-02H)             ; 004D  DD 7E FE
          OR A                      ; 0050  B7
          JR NZ,BPENT8              ; 0051  20 03
          DEC (IX-01H)              ; 0053  DD 35 FF
BPENT8:   DEC (IX-02H)              ; 0056  DD 35 FE
          LD A,(IX-0CH)             ; 0059  DD 7E F4
          AND 04H                   ; 005C  E6 04
          LD (UIF),A                ; 005E  32 DD 23
          CALL UFOR3                ; 0061  CD 7C 06
          JR BPNT8A                 ; 0064  18 03

; ----------------------------------------------------------------
; NMI vector (MON key / single step) -> NMIS
; ----------------------------------------------------------------
NMIV:     JP NMIS                   ; 0066  C3 CB 01
BPNT8A:   JR Z,REMBP2               ; 0069  28 13

; ----------------------------------------------------------------
; Remove breakpoints (restore user op codes) while in ZBUG
; ----------------------------------------------------------------
REMBP:    LD A,(IX+02H)             ; 006B  DD 7E 02
          CP 0CFH                   ; 006E  FE CF
          JR Z,REMBP1               ; 0070  28 07
REMBP0:   LD L,(IX+01H)             ; 0072  DD 6E 01
          LD H,(IX+00H)             ; 0075  DD 66 00
          LD (HL),A                 ; 0078  77
REMBP1:   CALL UIX3                 ; 0079  CD 34 06
          JR NZ,REMBP               ; 007C  20 ED

; ----------------------------------------------------------------
; Display PC and A, then go to DISUP
; ----------------------------------------------------------------
REMBP2:   LD IX,DISMEM              ; 007E  DD 21 F7 23
          LD HL,(STKPT)             ; 0082  2A E2 23
          DEC HL                    ; 0085  2B
          LD A,(HL)                 ; 0086  7E
          CALL UFOR1                ; 0087  CD 3C 06
          INC IX                    ; 008A  DD 23
          INC IX                    ; 008C  DD 23
          DEC HL                    ; 008E  2B
          LD A,(HL)                 ; 008F  7E
          CALL UFOR1                ; 0090  CD 3C 06
          INC IX                    ; 0093  DD 23
          INC IX                    ; 0095  DD 23
          DEC HL                    ; 0097  2B
          LD A,(HL)                 ; 0098  7E
          CALL UFOR1                ; 0099  CD 3C 06
          JP DISUP                  ; 009C  C3 F4 00

; ----------------------------------------------------------------
; Finish restart: save SP, set ZBUG SP 23A8H, clear flags
; ----------------------------------------------------------------
RESTAR:   LD (STKPT),SP             ; 009F  ED 73 E2 23
          LD SP,ZBUGSP              ; 00A3  31 A8 23
          LD A,00H                  ; 00A6  3E 00
          LD (BFLG),A               ; 00A8  32 F4 23
          LD (UIF),A                ; 00AB  32 DD 23

; ----------------------------------------------------------------
; Restart monitor: clear flags (UFGCR), show prompt; if KBSEL
; bit 5 (sense switch) is clear, jump to PROM1 at 0800H
; ----------------------------------------------------------------
RESTR1:   CALL UFGCR                ; 00AE  CD 86 06
          LD A,11H                  ; 00B1  3E 11
          LD (DISMEM),A             ; 00B3  32 F7 23
          LD A,10H                  ; 00B6  3E 10
          LD (DSMEM1),A             ; 00B8  32 F8 23
          LD (DSMEM2),A             ; 00BB  32 F9 23
          JR RESTR2                 ; 00BE  18 02

; ----------------------------------------------------------------
; User entry 00C0H: relative offset calculation (-> RESTR3)
; ----------------------------------------------------------------
RELOFS:   JR RESTR3                 ; 00C0  18 13
RESTR2:   LD (DSMEM3),A             ; 00C2  32 FA 23
          LD (DSMEM4),A             ; 00C5  32 FB 23
          LD (DSMEM5),A             ; 00C8  32 FC 23
          IN A,(KBSEL)              ; 00CB  DB 90
          BIT 5,A                   ; 00CD  CB 6F
          JP NZ,DISUP               ; 00CF  C2 F4 00
          JP PROM1                  ; 00D2  C3 00 08  PROM1 (U33)

; ----------------------------------------------------------------
; Relative offset: HL = JR destination, DE = address of JR op code
; ----------------------------------------------------------------
RESTR3:   INC DE                    ; 00D5  13
          PUSH DE                   ; 00D6  D5
          POP IX                    ; 00D7  DD E1
          INC DE                    ; 00D9  13
          LD A,L                    ; 00DA  7D
          SUB E                     ; 00DB  93
          LD L,A                    ; 00DC  6F
          LD (IX+00H),A             ; 00DD  DD 77 00
          LD A,H                    ; 00E0  7C
          SBC A,D                   ; 00E1  9A
          LD IX,DISMEM              ; 00E2  DD 21 F7 23
          CALL UFOR1                ; 00E6  CD 3C 06
          LD IX,DSMEM2              ; 00E9  DD 21 F9 23
          LD A,L                    ; 00ED  7D
          CALL UFOR1                ; 00EE  CD 3C 06
          JP DISUP                  ; 00F1  C3 F4 00

; ----------------------------------------------------------------
; DISUP module (V0.3): display update - DISMEM -> 6 digits, then DECKY
; ----------------------------------------------------------------
DISUP:    LD HL,DISMEM              ; 00F4  21 F7 23
          LD B,20H                  ; 00F7  06 20
DISUP1:   LD E,(HL)                 ; 00F9  5E
          LD D,00H                  ; 00FA  16 00
          LD A,00H                  ; 00FC  3E 00
          OUT (DIGLH),A             ; 00FE  D3 8C
          LD IX,SEGPT               ; 0100  DD 21 A6 07
          ADD IX,DE                 ; 0104  DD 19
          LD A,(IX+00H)             ; 0106  DD 7E 00
          OUT (SEGLH),A             ; 0109  D3 88
          LD A,B                    ; 010B  78
          OUT (DIGLH),A             ; 010C  D3 8C
          LD E,2DH                  ; 010E  1E 2D
DISUP2:   DEC E                     ; 0110  1D
          LD A,00H                  ; 0111  3E 00
          CP E                      ; 0113  BB
          JR NZ,DISUP2              ; 0114  20 FA
          LD A,01H                  ; 0116  3E 01
          CP B                      ; 0118  B8
          JR Z,DISUP3               ; 0119  28 05
          INC HL                    ; 011B  23
          SRL B                     ; 011C  CB 38
          JR DISUP1                 ; 011E  18 D9
DISUP3:   JP DECKY                  ; 0120  C3 23 01

; ----------------------------------------------------------------
; DECKY module (V2.1): key decode and command execution.
; Scan the matrix; hex keys go to DISMEM at (KEYPTR),
; command keys dispatch through JPTAB
; ----------------------------------------------------------------
DECKY:    LD A,7FH                  ; 0123  3E 7F
          OUT (SEGLH),A             ; 0125  D3 88
          LD A,3FH                  ; 0127  3E 3F
          OUT (DIGLH),A             ; 0129  D3 8C
          IN A,(KBSEL)              ; 012B  DB 90
          AND 1FH                   ; 012D  E6 1F
          CP 1FH                    ; 012F  FE 1F
          JP Z,DISUP                ; 0131  CA F4 00
          CALL D20MS                ; 0134  CD 4F 06
          LD C,8CH                  ; 0137  0E 8C
          LD B,01H                  ; 0139  06 01
KEYDN1:   OUT (C),B                 ; 013B  ED 41
          IN A,(KBSEL)              ; 013D  DB 90
          AND 1FH                   ; 013F  E6 1F
          CP 1FH                    ; 0141  FE 1F
          JR NZ,KEYDN2              ; 0143  20 0A
          SLA B                     ; 0145  CB 20
          LD A,40H                  ; 0147  3E 40
          CP B                      ; 0149  B8
          JR NZ,KEYDN1              ; 014A  20 EF
          JP DISUP                  ; 014C  C3 F4 00
KEYDN2:   LD C,00H                  ; 014F  0E 00
KEYDN3:   DEC C                     ; 0151  0D
          SRL B                     ; 0152  CB 38
          JR NZ,KEYDN3              ; 0154  20 FB
          SLA C                     ; 0156  CB 21
          SLA C                     ; 0158  CB 21
          SLA C                     ; 015A  CB 21
          SLA C                     ; 015C  CB 21
          ADD A,C                   ; 015E  81
          LD HL,KYTBL               ; 015F  21 B9 07
KEYDN4:   CP (HL)                   ; 0162  BE
          JR Z,KEYDN5               ; 0163  28 04
          INC HL                    ; 0165  23
          INC B                     ; 0166  04
          JR KEYDN4                 ; 0167  18 F9
KEYDN5:   IN A,(KBSEL)              ; 0169  DB 90
          AND 1FH                   ; 016B  E6 1F
          CP 1FH                    ; 016D  FE 1F
          JR NZ,KEYDN5              ; 016F  20 F8
          CALL D20MS                ; 0171  CD 4F 06
          LD A,B                    ; 0174  78
          CP 10H                    ; 0175  FE 10
          JR NC,KEYDN6              ; 0177  30 45
          LD HL,(KEYPTR)            ; 0179  2A DB 23
          LD (HL),B                 ; 017C  70
          OR A                      ; 017D  B7
          LD BC,DSMEM1              ; 017E  01 F8 23
          SBC HL,BC                 ; 0181  ED 42
          JR Z,KEYDNA               ; 0183  28 20
          OR A                      ; 0185  B7
          LD BC,DSMEM3              ; 0186  01 FA 23
          LD HL,(KEYPTR)            ; 0189  2A DB 23
          SBC HL,BC                 ; 018C  ED 42
          JR Z,KEYDN8               ; 018E  28 1B
          OR A                      ; 0190  B7
          LD BC,DSMEM7              ; 0191  01 FE 23
          LD HL,(KEYPTR)            ; 0194  2A DB 23
          SBC HL,BC                 ; 0197  ED 42
          JR Z,KEYDN9               ; 0199  28 16
KEYDN7:   LD HL,(KEYPTR)            ; 019B  2A DB 23
          INC HL                    ; 019E  23
          LD (KEYPTR),HL            ; 019F  22 DB 23
          JP DISUP                  ; 01A2  C3 F4 00
KEYDNA:   LD HL,DIG2                ; 01A5  21 F5 23
          INC (HL)                  ; 01A8  34
          JR KEYDN7                 ; 01A9  18 F0
KEYDN8:   LD HL,DIG4                ; 01AB  21 F6 23
          INC (HL)                  ; 01AE  34
          JR KEYDN7                 ; 01AF  18 EA
KEYDN9:   CALL ALTER                ; 01B1  CD B4 03
          LD HL,(KEYPTR)            ; 01B4  2A DB 23
          DEC HL                    ; 01B7  2B
          LD (KEYPTR),HL            ; 01B8  22 DB 23
          JP DISUP                  ; 01BB  C3 F4 00

; ----------------------------------------------------------------
; Command key: index JPTAB with (key-10H)*3
; ----------------------------------------------------------------
KEYDN6:   SUB 10H                   ; 01BE  D6 10
          LD C,A                    ; 01C0  4F
          ADD A,C                   ; 01C1  81
          ADD A,C                   ; 01C2  81
          LD C,A                    ; 01C3  4F
          LD B,00H                  ; 01C4  06 00
          LD HL,JPTAB               ; 01C6  21 0C 02
          ADD HL,BC                 ; 01C9  09
          JP (HL)                   ; 01CA  E9

; ----------------------------------------------------------------
; NMI service: single step or MON abort - stack user registers
; ----------------------------------------------------------------
NMIS:     LD (STKPT),SP             ; 01CB  ED 73 E2 23
          PUSH AF                   ; 01CF  F5
          LD A,03H                  ; 01D0  3E 03
          OUT (CTC2),A              ; 01D2  D3 86
          LD A,I                    ; 01D4  ED 57
          PUSH BC                   ; 01D6  C5
          PUSH DE                   ; 01D7  D5
          PUSH HL                   ; 01D8  E5
          PUSH AF                   ; 01D9  F5
          EX AF,AF'                 ; 01DA  08
          EXX                       ; 01DB  D9
          PUSH AF                   ; 01DC  F5
          PUSH BC                   ; 01DD  C5
          PUSH DE                   ; 01DE  D5
          PUSH HL                   ; 01DF  E5
          PUSH IX                   ; 01E0  DD E5
          PUSH IY                   ; 01E2  FD E5
          LD IX,(STKPT)             ; 01E4  DD 2A E2 23
          INC IX                    ; 01E8  DD 23
          INC IX                    ; 01EA  DD 23
          LD A,(IX-0CH)             ; 01EC  DD 7E F4
          AND 04H                   ; 01EF  E6 04
          LD (UIF),A                ; 01F1  32 DD 23
          LD (STKPT),IX             ; 01F4  DD 22 E2 23
NMIS1:    LD A,(SSFLG)              ; 01F8  3A F3 23
          OR A                      ; 01FB  B7
          JP Z,DECKY                ; 01FC  CA 23 01
NMIS2:    LD A,00H                  ; 01FF  3E 00
          LD (SSFLG),A              ; 0201  32 F3 23
          CALL UFOR3                ; 0204  CD 7C 06
          JP Z,REMBP2               ; 0207  CA 7E 00
          JR CCS1C                  ; 020A  18 42

; ----------------------------------------------------------------
; Jump table for command keys (key codes 10H-1BH)
; ----------------------------------------------------------------
JPTAB:    JP CCS1                   ; 020C  C3 30 02  key EXEC
          JP CCS2                   ; 020F  C3 72 02  key SS
          JP CCS3                   ; 0212  C3 A1 02  key MON
          JP CCS4                   ; 0215  C3 A4 02  key NEXT
          JP CCS5                   ; 0218  C3 ED 02  key REG' DISP
          JP CCS6                   ; 021B  C3 08 03  key REG DISP
          JP CCS7                   ; 021E  C3 6B 03  key PORT EXAM
          JP CCS8                   ; 0221  C3 95 03  key MEM EXAM
          JP CCS9                   ; 0224  C3 97 04  key BP
          JP CCS10                  ; 0227  C3 CA 04  key PUNCH
          JP CCS11                  ; 022A  C3 81 05  key LOAD
          JP CCS12                  ; 022D  C3 D3 05  key PROG

; ----------------------------------------------------------------
; EXEC key: optional new PC from display, then proceed
; ----------------------------------------------------------------
CCS1:     LD A,00H                  ; 0230  3E 00
          OUT (DIGLH),A             ; 0232  D3 8C
          LD A,(DIG4)               ; 0234  3A F6 23
          OR A                      ; 0237  B7
          JR Z,CCS1A                ; 0238  28 0D
          CALL UFOR2                ; 023A  CD 59 06
          LD IX,(STKPT)             ; 023D  DD 2A E2 23
          LD (IX-02H),L             ; 0241  DD 75 FE
          LD (IX-01H),H             ; 0244  DD 74 FF

; ----------------------------------------------------------------
; Proceed: if breakpoints set, single step once first
; ----------------------------------------------------------------
CCS1A:    CALL UFOR3                ; 0247  CD 7C 06
          JR NZ,CCS2A               ; 024A  20 2B
          JR CCS1D                  ; 024C  18 16

; ----------------------------------------------------------------
; Install breakpoints (RST 8 = 0CFH) and save user op codes
; ----------------------------------------------------------------
CCS1C:    LD IX,BPTAB               ; 024E  DD 21 E4 23
CCS1CA:   LD H,(IX+00H)             ; 0252  DD 66 00
          LD L,(IX+01H)             ; 0255  DD 6E 01
          LD A,(HL)                 ; 0258  7E
          LD C,0CFH                 ; 0259  0E CF
          LD (HL),C                 ; 025B  71
          LD (IX+02H),A             ; 025C  DD 77 02
          CALL UIX3                 ; 025F  CD 34 06
          JR NZ,CCS1CA              ; 0262  20 EE

; ----------------------------------------------------------------
; Enable keyboard NMI for abort, restore registers
; ----------------------------------------------------------------
CCS1D:    LD A,04H                  ; 0264  3E 04
          OUT (DIGLH),A             ; 0266  D3 8C
          LD A,45H                  ; 0268  3E 45
          OUT (CTC2),A              ; 026A  D3 86
          LD A,01H                  ; 026C  3E 01
          OUT (CTC2),A              ; 026E  D3 86
          JR CCS2B                  ; 0270  18 12

; ----------------------------------------------------------------
; SS key: single step - CTC2 counts down to an NMI
; ----------------------------------------------------------------
CCS2:     LD A,00H                  ; 0272  3E 00
          LD (BFLG),A               ; 0274  32 F4 23
CCS2A:    LD A,01H                  ; 0277  3E 01
          LD (SSFLG),A              ; 0279  32 F3 23
          LD A,07H                  ; 027C  3E 07
          OUT (CTC2),A              ; 027E  D3 86
          LD A,0BH                  ; 0280  3E 0B
          OUT (CTC2),A              ; 0282  D3 86

; ----------------------------------------------------------------
; Restore user registers and return to the user program
; ----------------------------------------------------------------
CCS2B:    POP IY                    ; 0284  FD E1
          POP IX                    ; 0286  DD E1
          POP HL                    ; 0288  E1
          POP DE                    ; 0289  D1
          POP BC                    ; 028A  C1
          POP AF                    ; 028B  F1
          EX AF,AF'                 ; 028C  08
          EXX                       ; 028D  D9
          POP AF                    ; 028E  F1
          LD I,A                    ; 028F  ED 47
          POP HL                    ; 0291  E1
          POP DE                    ; 0292  D1
          POP BC                    ; 0293  C1
          LD A,(UIF)                ; 0294  3A DD 23
          OR A                      ; 0297  B7
          JP NZ,CCS2C               ; 0298  C2 9E 02
          POP AF                    ; 029B  F1
          DI                        ; 029C  F3
          RET                       ; 029D  C9
CCS2C:    POP AF                    ; 029E  F1
          EI                        ; 029F  FB
          RET                       ; 02A0  C9

; ----------------------------------------------------------------
; MON key: restart monitor
; ----------------------------------------------------------------
CCS3:     JP RESTR1                 ; 02A1  C3 AE 00

; ----------------------------------------------------------------
; NEXT key: next memory / port / PROM error
; ----------------------------------------------------------------
CCS4:     LD A,(MFLG)               ; 02A4  3A E1 23
          CP 01H                    ; 02A7  FE 01
          JR Z,CCS4B                ; 02A9  28 12
          LD A,(PFLG)               ; 02AB  3A DE 23
          CP 01H                    ; 02AE  FE 01
          JR Z,CCS4C                ; 02B0  28 26
          LD A,(PRFLG)              ; 02B2  3A DA 23
          CP 01H                    ; 02B5  FE 01
CCS4A:    JP NZ,RESTR1              ; 02B7  C2 AE 00
          JP CCS12D                 ; 02BA  C3 30 06
CCS4B:    CALL UFOR2                ; 02BD  CD 59 06
          INC HL                    ; 02C0  23
          LD A,H                    ; 02C1  7C
          CALL UFOR1                ; 02C2  CD 3C 06
          INC IX                    ; 02C5  DD 23
          INC IX                    ; 02C7  DD 23
          LD A,L                    ; 02C9  7D
          CALL UFOR1                ; 02CA  CD 3C 06
          INC IX                    ; 02CD  DD 23
          INC IX                    ; 02CF  DD 23
          LD A,(HL)                 ; 02D1  7E
          CALL UFOR1                ; 02D2  CD 3C 06
          JP DISUP                  ; 02D5  C3 F4 00
CCS4C:    CALL UFOR2                ; 02D8  CD 59 06
          LD C,H                    ; 02DB  4C
          INC C                     ; 02DC  0C
          IN A,(C)                  ; 02DD  ED 78
          LD A,C                    ; 02DF  79
          CALL UFOR1                ; 02E0  CD 3C 06
          LD IX,DSMEM4              ; 02E3  DD 21 FB 23
          CALL UFOR1                ; 02E7  CD 3C 06
          JP DISUP                  ; 02EA  C3 F4 00

; ----------------------------------------------------------------
; REG' DISP key: alternate register display
; ----------------------------------------------------------------
CCS5:     LD A,01H                  ; 02ED  3E 01
          LD (ARFLG),A              ; 02EF  32 E0 23
          LD IX,DISMEM              ; 02F2  DD 21 F7 23
          LD A,12H                  ; 02F6  3E 12
          LD (IX+01H),A             ; 02F8  DD 77 01
          CALL ALTER5               ; 02FB  CD 55 04
          LD A,(HL)                 ; 02FE  7E
          LD IX,DSMEM4              ; 02FF  DD 21 FB 23
          CALL UFOR1                ; 0303  CD 3C 06
          JR CCS6C                  ; 0306  18 5A

; ----------------------------------------------------------------
; REG DISP key: main register display
; ----------------------------------------------------------------
CCS6:     LD A,01H                  ; 0308  3E 01
          LD (RFLG),A               ; 030A  32 DF 23
          CALL ALTER6               ; 030D  CD 6E 04
          JR C,CCS6A                ; 0310  38 0A
          LD A,(HL)                 ; 0312  7E
          LD IX,DSMEM4              ; 0313  DD 21 FB 23
          CALL UFOR1                ; 0317  CD 3C 06
          JR CCS6C                  ; 031A  18 46
CCS6A:    CP 03H                    ; 031C  FE 03
          JR Z,CCS6B                ; 031E  28 35
          CP 02H                    ; 0320  FE 02
          JR Z,CCS6A1               ; 0322  28 17
          LD A,(HL)                 ; 0324  7E
          LD IX,DSMEM4              ; 0325  DD 21 FB 23
          LD (KEYPTR),IX            ; 0329  DD 22 DB 23
          CALL UFOR1                ; 032D  CD 3C 06
          INC HL                    ; 0330  23
          LD A,(HL)                 ; 0331  7E
          LD IX,DSMEM2              ; 0332  DD 21 F9 23
          CALL UFOR1                ; 0336  CD 3C 06
          JR CCS6D                  ; 0339  18 2D
CCS6A1:   LD A,(STKPT1)             ; 033B  3A E3 23
          LD IX,DSMEM2              ; 033E  DD 21 F9 23
          CALL UFOR1                ; 0342  CD 3C 06
          LD A,(STKPT)              ; 0345  3A E2 23
          LD IX,DSMEM4              ; 0348  DD 21 FB 23
          CALL UFOR1                ; 034C  CD 3C 06
          LD (KEYPTR),IX            ; 034F  DD 22 DB 23
          JR CCS6D                  ; 0353  18 13
CCS6B:    LD IX,DSMEM4              ; 0355  DD 21 FB 23
          LD A,(UIF)                ; 0359  3A DD 23
          CALL UFOR1                ; 035C  CD 3C 06
          LD HL,DSMEM7              ; 035F  21 FE 23
CCS6C:    LD HL,DSMEM6              ; 0362  21 FD 23
          LD (KEYPTR),HL            ; 0365  22 DB 23
CCS6D:    JP DISUP                  ; 0368  C3 F4 00

; ----------------------------------------------------------------
; PORT EXAM key
; ----------------------------------------------------------------
CCS7:     LD A,(DIG2)               ; 036B  3A F5 23
          CP 01H                    ; 036E  FE 01
          JR NZ,CCS7A               ; 0370  20 20
          LD (PFLG),A               ; 0372  32 DE 23
          LD A,10H                  ; 0375  3E 10
          LD (DSMEM2),A             ; 0377  32 F9 23
          LD (DSMEM3),A             ; 037A  32 FA 23
          CALL UFOR2                ; 037D  CD 59 06
          LD C,H                    ; 0380  4C
          IN A,(C)                  ; 0381  ED 78
          LD IX,DSMEM4              ; 0383  DD 21 FB 23
          CALL UFOR1                ; 0387  CD 3C 06
          INC IX                    ; 038A  DD 23
          INC IX                    ; 038C  DD 23
          LD (KEYPTR),IX            ; 038E  DD 22 DB 23
CCS7A:    JP DISUP                  ; 0392  C3 F4 00

; ----------------------------------------------------------------
; MEM EXAM key
; ----------------------------------------------------------------
CCS8:     LD A,(DIG4)               ; 0395  3A F6 23
          OR A                      ; 0398  B7
          JR Z,CCS8A                ; 0399  28 16
          LD (MFLG),A               ; 039B  32 E1 23
          CALL UFOR2                ; 039E  CD 59 06
          LD A,(HL)                 ; 03A1  7E
          LD IX,DSMEM4              ; 03A2  DD 21 FB 23
          CALL UFOR1                ; 03A6  CD 3C 06
          INC IX                    ; 03A9  DD 23
          INC IX                    ; 03AB  DD 23
          LD (KEYPTR),IX            ; 03AD  DD 22 DB 23
CCS8A:    JP DISUP                  ; 03B1  C3 F4 00

; ----------------------------------------------------------------
; Enter data into memory, port or register (8 digits typed)
; ----------------------------------------------------------------
ALTER:    LD IX,DISMEM              ; 03B4  DD 21 F7 23
          LD A,(PFLG)               ; 03B8  3A DE 23
          OR A                      ; 03BB  B7
          JR NZ,ALTER2              ; 03BC  20 2A
          LD A,(RFLG)               ; 03BE  3A DF 23
          OR A                      ; 03C1  B7
          JR NZ,ALTR3               ; 03C2  20 35
          LD A,(ARFLG)              ; 03C4  3A E0 23
          OR A                      ; 03C7  B7
          JP NZ,ALTR4               ; 03C8  C2 41 04
          LD A,(MFLG)               ; 03CB  3A E1 23
          OR A                      ; 03CE  B7
          JP Z,RESTR1               ; 03CF  CA AE 00
          CALL UFOR2                ; 03D2  CD 59 06
          LD A,(IX+06H)             ; 03D5  DD 7E 06
          CALL ALTER7               ; 03D8  CD 8E 04
          OR (IX+07H)               ; 03DB  DD B6 07
          LD (HL),A                 ; 03DE  77
          LD A,(HL)                 ; 03DF  7E
ALTER1:   LD IX,DSMEM4              ; 03E0  DD 21 FB 23
          CALL UFOR1                ; 03E4  CD 3C 06
          RET                       ; 03E7  C9
ALTER2:   CALL UFOR2                ; 03E8  CD 59 06
          LD A,(IX+06H)             ; 03EB  DD 7E 06
          CALL ALTER7               ; 03EE  CD 8E 04
          OR (IX+07H)               ; 03F1  DD B6 07
          LD C,H                    ; 03F4  4C
          OUT (C),A                 ; 03F5  ED 79
          JR ALTER1                 ; 03F7  18 E7

; ----------------------------------------------------------------
; Main register change
; ----------------------------------------------------------------
ALTR3:    CALL ALTER6               ; 03F9  CD 6E 04
          JR C,ALTR3A               ; 03FC  38 0D
          LD A,(IX+06H)             ; 03FE  DD 7E 06
          CALL ALTER7               ; 0401  CD 8E 04
          OR (IX+07H)               ; 0404  DD B6 07
          LD (HL),A                 ; 0407  77
          JP ALTER1                 ; 0408  C3 E0 03
ALTR3A:   CP 03H                    ; 040B  FE 03
          JR Z,ALTR3B               ; 040D  28 24
          CP 02H                    ; 040F  FE 02
          JR Z,ALTR3C               ; 0411  28 2A
          LD A,(IX+04H)             ; 0413  DD 7E 04
          CALL ALTER7               ; 0416  CD 8E 04
          OR (IX+05H)               ; 0419  DD B6 05
          INC HL                    ; 041C  23
          LD (HL),A                 ; 041D  77
          LD IX,DSMEM2              ; 041E  DD 21 F9 23
          CALL UFOR1                ; 0422  CD 3C 06
          LD A,(IX+04H)             ; 0425  DD 7E 04
          CALL ALTER7               ; 0428  CD 8E 04
          OR (IX+05H)               ; 042B  DD B6 05
          DEC HL                    ; 042E  2B
          LD (HL),A                 ; 042F  77
          JP ALTER1                 ; 0430  C3 E0 03
ALTR3B:   LD A,(DSMEM7)             ; 0433  3A FE 23
          LD (UIF),A                ; 0436  32 DD 23
          LD (DSMEM5),A             ; 0439  32 FC 23
          RET                       ; 043C  C9

; ----------------------------------------------------------------
; SP change is illegal
; ----------------------------------------------------------------
ALTR3C:   POP HL                    ; 043D  E1
          JP RESTR1                 ; 043E  C3 AE 00

; ----------------------------------------------------------------
; Alternate register change
; ----------------------------------------------------------------
ALTR4:    LD IX,DISMEM              ; 0441  DD 21 F7 23
          CALL ALTER5               ; 0445  CD 55 04
          LD A,(IX+06H)             ; 0448  DD 7E 06
          CALL ALTER7               ; 044B  CD 8E 04
          OR (IX+07H)               ; 044E  DD B6 07
          LD (HL),A                 ; 0451  77
          JP ALTER1                 ; 0452  C3 E0 03

; ----------------------------------------------------------------
; Alt register: key value -> offset via REGTBP
; ----------------------------------------------------------------
ALTER5:   LD E,(IX+00H)             ; 0455  DD 5E 00
          LD B,00H                  ; 0458  06 00
          LD D,00H                  ; 045A  16 00
          LD HL,REGTBP              ; 045C  21 E5 07
          ADD HL,DE                 ; 045F  19
          LD C,(HL)                 ; 0460  4E
          LD A,C                    ; 0461  79
          CP 19H                    ; 0462  FE 19
          JP Z,RESTR1               ; 0464  CA AE 00
          LD HL,(STKPT)             ; 0467  2A E2 23
          OR A                      ; 046A  B7
          SBC HL,BC                 ; 046B  ED 42
          RET                       ; 046D  C9

; ----------------------------------------------------------------
; Main register: key value -> offset via REGTB
; ----------------------------------------------------------------
ALTER6:   LD IX,DISMEM              ; 046E  DD 21 F7 23
          LD E,(IX+00H)             ; 0472  DD 5E 00
          LD B,00H                  ; 0475  06 00
          LD D,00H                  ; 0477  16 00
          LD HL,REGTB               ; 0479  21 D5 07
          ADD HL,DE                 ; 047C  19
          LD C,(HL)                 ; 047D  4E
          LD A,C                    ; 047E  79
          CP 19H                    ; 047F  FE 19
          JP Z,RESTR1               ; 0481  CA AE 00
          LD HL,(STKPT)             ; 0484  2A E2 23
          LD A,E                    ; 0487  7B
          OR A                      ; 0488  B7
          SBC HL,BC                 ; 0489  ED 42
          CP 06H                    ; 048B  FE 06
          RET                       ; 048D  C9

; ----------------------------------------------------------------
; A <<= 4
; ----------------------------------------------------------------
ALTER7:   SLA A                     ; 048E  CB 27
          SLA A                     ; 0490  CB 27
          SLA A                     ; 0492  CB 27
          SLA A                     ; 0494  CB 27
          RET                       ; 0496  C9

; ----------------------------------------------------------------
; BP key: install breakpoint (max 5) or clear all
; ----------------------------------------------------------------
CCS9:     LD A,(DIG4)               ; 0497  3A F6 23
          OR A                      ; 049A  B7
          JR NZ,CCS90               ; 049B  20 05
          LD (BFLG),A               ; 049D  32 F4 23
          JR CCS91                  ; 04A0  18 10
CCS90:    CALL UFOR2                ; 04A2  CD 59 06
          CALL UFOR3                ; 04A5  CD 7C 06
          JR Z,CCS9B                ; 04A8  28 10
          LD A,B                    ; 04AA  78
          CP 05H                    ; 04AB  FE 05
          JR NZ,CCS9A               ; 04AD  20 06
          JP RESTR1                 ; 04AF  C3 AE 00
CCS91:    JP DISUP                  ; 04B2  C3 F4 00
CCS9A:    CALL UIX3                 ; 04B5  CD 34 06
          JR NZ,CCS9A               ; 04B8  20 FB
CCS9B:    LD A,(BFLG)               ; 04BA  3A F4 23
          INC A                     ; 04BD  3C
          LD (BFLG),A               ; 04BE  32 F4 23
          LD (IX+00H),H             ; 04C1  DD 74 00
          LD (IX+01H),L             ; 04C4  DD 75 01
          JP DISUP                  ; 04C7  C3 F4 00

; ----------------------------------------------------------------
; PUNCH key: write cassette, Kansas City Standard.
; Start address at PUNHSH/PUNHSL, end at PUNHEH/PUNHEL
; ----------------------------------------------------------------
CCS10:    CALL UFOR4                ; 04CA  CD A7 06
          LD A,01H                  ; 04CD  3E 01
          LD (FLG24),A              ; 04CF  32 D9 23
          IM 2                      ; 04D2  ED 5E
          LD BC,CTC1P               ; 04D4  01 FA 07
          LD A,B                    ; 04D7  78
          LD I,A                    ; 04D8  ED 47
          LD A,C                    ; 04DA  79
          OUT (CTC0),A              ; 04DB  D3 84
          LD A,85H                  ; 04DD  3E 85
          OUT (CTC1),A              ; 04DF  D3 85
          LD A,1AH                  ; 04E1  3E 1A
          OUT (CTC1),A              ; 04E3  D3 85
          LD A,(PUNHSH)             ; 04E5  3A C0 23
          LD D,A                    ; 04E8  57
          LD A,(PUNHSL)             ; 04E9  3A C1 23
          LD E,A                    ; 04EC  5F
          LD A,(PUNHEH)             ; 04ED  3A C2 23
          LD H,A                    ; 04F0  67
          LD A,(PUNHEL)             ; 04F1  3A C3 23
          LD L,A                    ; 04F4  6F
          XOR A                     ; 04F5  AF
          SBC HL,DE                 ; 04F6  ED 52
          INC HL                    ; 04F8  23
          PUSH HL                   ; 04F9  E5
          LD HL,0000H               ; 04FA  21 00 00
          LD B,03H                  ; 04FD  06 03
          EI                        ; 04FF  FB
CCS10A:   HALT                      ; 0500  76
          DEC L                     ; 0501  2D
          JR NZ,CCS10A              ; 0502  20 FC
          DEC H                     ; 0504  25
          JR NZ,CCS10A              ; 0505  20 F9
          DJNZ CCS10A               ; 0507  10 F7
CCS10B:   LD A,3AH                  ; 0509  3E 3A
          CALL OTCHR1               ; 050B  CD F7 06
          XOR A                     ; 050E  AF
          LD BC,0010H               ; 050F  01 10 00
          POP HL                    ; 0512  E1
          SBC HL,BC                 ; 0513  ED 42
          JR NC,CCS10C              ; 0515  30 09
          ADD HL,BC                 ; 0517  09
          ADD A,L                   ; 0518  85
          LD B,A                    ; 0519  47
          LD L,00H                  ; 051A  2E 00
          JR Z,CCS10F               ; 051C  28 3C
          JR CCS10D                 ; 051E  18 01
CCS10C:   LD B,C                    ; 0520  41
CCS10D:   PUSH HL                   ; 0521  E5
          LD C,00H                  ; 0522  0E 00
          LD A,B                    ; 0524  78
          CALL UPACCS               ; 0525  CD D5 06
          LD A,(PUNHSH)             ; 0528  3A C0 23
          LD H,A                    ; 052B  67
          CALL UPACCS               ; 052C  CD D5 06
          LD A,(PUNHSL)             ; 052F  3A C1 23
          LD L,A                    ; 0532  6F
          CALL UPACCS               ; 0533  CD D5 06
          XOR A                     ; 0536  AF
          CALL UPACCS               ; 0537  CD D5 06
CCS10E:   LD A,(HL)                 ; 053A  7E
          CALL UPACCS               ; 053B  CD D5 06
          INC HL                    ; 053E  23
          DJNZ CCS10E               ; 053F  10 F9
          SUB A                     ; 0541  97
          SUB C                     ; 0542  91
          CALL UPACCS               ; 0543  CD D5 06
          LD A,0DH                  ; 0546  3E 0D
          CALL UPACCS               ; 0548  CD D5 06
          LD A,0AH                  ; 054B  3E 0A
          CALL UPACCS               ; 054D  CD D5 06
          LD A,H                    ; 0550  7C
          LD (PUNHSH),A             ; 0551  32 C0 23
          LD A,L                    ; 0554  7D
          LD (PUNHSL),A             ; 0555  32 C1 23
          JR CCS10B                 ; 0558  18 AF
CCS10F:   LD B,03H                  ; 055A  06 03
CCS10G:   XOR A                     ; 055C  AF
          LD C,A                    ; 055D  4F
          CALL UPACCS               ; 055E  CD D5 06
          DJNZ CCS10G               ; 0561  10 F9
          LD A,01H                  ; 0563  3E 01
          CALL UPACCS               ; 0565  CD D5 06
          SUB A                     ; 0568  97
          SUB C                     ; 0569  91
          CALL UPACCS               ; 056A  CD D5 06
CCS10H:   LD HL,0FFFFH              ; 056D  21 FF FF
          EI                        ; 0570  FB
          HALT                      ; 0571  76
CCS10J:   DEC L                     ; 0572  2D
          JR NZ,CCS10J              ; 0573  20 FD
          DEC H                     ; 0575  25
          JR NZ,CCS10J              ; 0576  20 FA
          DI                        ; 0578  F3
          LD A,03H                  ; 0579  3E 03
          OUT (CTC1),A              ; 057B  D3 85
          DI                        ; 057D  F3
          JP RESTR1                 ; 057E  C3 AE 00

; ----------------------------------------------------------------
; LOAD key: read cassette (KC format) into memory
; ----------------------------------------------------------------
CCS11:    IM 2                      ; 0581  ED 5E
          LD HL,0FFFH               ; 0583  21 FF 0F
          LD B,20H                  ; 0586  06 20
CCS11A:   DEC L                     ; 0588  2D
          JR NZ,CCS11A              ; 0589  20 FD
          DEC H                     ; 058B  25
          JR NZ,CCS11A              ; 058C  20 FA
          DJNZ CCS11A               ; 058E  10 F8
CCS11G:   CALL INCHR                ; 0590  CD 58 07
          SUB 3AH                   ; 0593  D6 3A
          JR NZ,CCS11G              ; 0595  20 F9
          LD C,A                    ; 0597  4F
          CALL ULACC                ; 0598  CD DB 06
          LD B,A                    ; 059B  47
          CALL ULACC                ; 059C  CD DB 06
          LD D,A                    ; 059F  57
          CALL ULACC                ; 05A0  CD DB 06
          LD E,A                    ; 05A3  5F
          CALL ULACC                ; 05A4  CD DB 06
          DEC A                     ; 05A7  3D
          PUSH AF                   ; 05A8  F5
          JR Z,CCS11J               ; 05A9  28 07
CCS11H:   CALL ULACC                ; 05AB  CD DB 06
          LD (DE),A                 ; 05AE  12
          INC DE                    ; 05AF  13
          DJNZ CCS11H               ; 05B0  10 F9
CCS11J:   CALL ULACC                ; 05B2  CD DB 06
          XOR A                     ; 05B5  AF
          ADD A,C                   ; 05B6  81
          JR Z,CCS11K               ; 05B7  28 14
          LD IX,DISMEM              ; 05B9  DD 21 F7 23
          LD A,D                    ; 05BD  7A
          CALL UFOR1                ; 05BE  CD 3C 06
          LD IX,DSMEM2              ; 05C1  DD 21 F9 23
          LD A,E                    ; 05C5  7B
          CALL UFOR1                ; 05C6  CD 3C 06
          POP AF                    ; 05C9  F1
          JP DISUP                  ; 05CA  C3 F4 00
CCS11K:   POP AF                    ; 05CD  F1
          JR NZ,CCS11G              ; 05CE  20 C0
          JP RESTR1                 ; 05D0  C3 AE 00

; ----------------------------------------------------------------
; PROG key: program 2716/2758 at 1000H from RAM; byte count in display
; ----------------------------------------------------------------
CCS12:    LD A,01H                  ; 05D3  3E 01
          LD (PRFLG),A              ; 05D5  32 DA 23
          CALL UFOR2                ; 05D8  CD 59 06
          PUSH HL                   ; 05DB  E5
          POP BC                    ; 05DC  C1
          PUSH HL                   ; 05DD  E5
          LD HL,2800H               ; 05DE  21 00 28  !! Mercer change: original is LD HL,2000H (RAM source 2800H)
          LD DE,1000H               ; 05E1  11 00 10  PROM2 socket (U34)
CCS12A:   LD A,25H                  ; 05E4  3E 25
          OUT (CTC2),A              ; 05E6  D3 86
          LD A,0CBH                 ; 05E8  3E CB
          OUT (CTC2),A              ; 05EA  D3 86
          LD A,80H                  ; 05EC  3E 80
          OUT (DIGLH),A             ; 05EE  D3 8C
          LDI                       ; 05F0  ED A0
          LD A,00H                  ; 05F2  3E 00
          OUT (DIGLH),A             ; 05F4  D3 8C
          LD A,03H                  ; 05F6  3E 03
          OUT (CTC2),A              ; 05F8  D3 86
          JP PE,CCS12A              ; 05FA  EA E4 05
          POP BC                    ; 05FD  C1
          LD HL,2800H               ; 05FE  21 00 28  !! Mercer change: original is LD HL,2000H
          LD DE,1000H               ; 0601  11 00 10  PROM2 socket (U34)

; ----------------------------------------------------------------
; Verify PROM against RAM
; ----------------------------------------------------------------
CCS12B:   LD A,(DE)                 ; 0604  1A
          CPI                       ; 0605  ED A1
          JR NZ,CCS12C              ; 0607  20 06
          JP PO,RESTR1              ; 0609  E2 AE 00
          INC DE                    ; 060C  13
          JR CCS12B                 ; 060D  18 F5

; ----------------------------------------------------------------
; Error: show address and data; NEXT steps to the next error
; ----------------------------------------------------------------
CCS12C:   PUSH AF                   ; 060F  F5
          PUSH BC                   ; 0610  C5
          PUSH DE                   ; 0611  D5
          EXX                       ; 0612  D9
          POP DE                    ; 0613  D1
          POP BC                    ; 0614  C1
CCS12E:   LD IX,DISMEM              ; 0615  DD 21 F7 23
          LD A,D                    ; 0619  7A
          CALL UFOR1                ; 061A  CD 3C 06
          LD IX,DSMEM2              ; 061D  DD 21 F9 23
          LD A,E                    ; 0621  7B
          CALL UFOR1                ; 0622  CD 3C 06
          LD IX,DSMEM4              ; 0625  DD 21 FB 23
          POP AF                    ; 0629  F1
          CALL UFOR1                ; 062A  CD 3C 06
          JP DISUP                  ; 062D  C3 F4 00
CCS12D:   EXX                       ; 0630  D9
          INC DE                    ; 0631  13
          JR CCS12B                 ; 0632  18 D0

; ----------------------------------------------------------------
; UTIL module (V1.5): utility package
; UIX3: IX += 3, B -= 1
; ----------------------------------------------------------------
UIX3:     INC IX                    ; 0634  DD 23
          INC IX                    ; 0636  DD 23
          INC IX                    ; 0638  DD 23
          DEC B                     ; 063A  05
          RET                       ; 063B  C9

; ----------------------------------------------------------------
; Write A as two hex digits to (IX) (high) and (IX+1) (low)
; ----------------------------------------------------------------
UFOR1:    LD B,A                    ; 063C  47
          AND 0FH                   ; 063D  E6 0F
          LD (IX+01H),A             ; 063F  DD 77 01
          LD A,B                    ; 0642  78
          SRL A                     ; 0643  CB 3F
          SRL A                     ; 0645  CB 3F
          SRL A                     ; 0647  CB 3F
          SRL A                     ; 0649  CB 3F
          LD (IX+00H),A             ; 064B  DD 77 00
          RET                       ; 064E  C9

; ----------------------------------------------------------------
; Delay 20 ms
; ----------------------------------------------------------------
D20MS:    LD HL,08FFH               ; 064F  21 FF 08
D20MS1:   DEC L                     ; 0652  2D
          JR NZ,D20MS1              ; 0653  20 FD
          DEC H                     ; 0655  25
          JR NZ,D20MS1              ; 0656  20 FA
          RET                       ; 0658  C9

; ----------------------------------------------------------------
; First four DISMEM digits -> address in HL
; ----------------------------------------------------------------
UFOR2:    LD IX,DISMEM              ; 0659  DD 21 F7 23
          LD A,(IX+00H)             ; 065D  DD 7E 00
          SLA A                     ; 0660  CB 27
          SLA A                     ; 0662  CB 27
          SLA A                     ; 0664  CB 27
          SLA A                     ; 0666  CB 27
          OR (IX+01H)               ; 0668  DD B6 01
          LD H,A                    ; 066B  67
          LD A,(IX+02H)             ; 066C  DD 7E 02
          SLA A                     ; 066F  CB 27
          SLA A                     ; 0671  CB 27
          SLA A                     ; 0673  CB 27
          SLA A                     ; 0675  CB 27
          OR (IX+03H)               ; 0677  DD B6 03
          LD L,A                    ; 067A  6F
          RET                       ; 067B  C9

; ----------------------------------------------------------------
; IX = BPTAB, B = A = BFLG (number of breakpoints), status set
; ----------------------------------------------------------------
UFOR3:    LD IX,BPTAB               ; 067C  DD 21 E4 23
          LD A,(BFLG)               ; 0680  3A F4 23
          OR A                      ; 0683  B7
          LD B,A                    ; 0684  47
          RET                       ; 0685  C9

; ----------------------------------------------------------------
; Flag initialisation: KEYPTR = DISMEM, clear all flags
; ----------------------------------------------------------------
UFGCR:    LD HL,DISMEM              ; 0686  21 F7 23
          LD (KEYPTR),HL            ; 0689  22 DB 23
          LD A,00H                  ; 068C  3E 00
          LD (DIG2),A               ; 068E  32 F5 23
          LD (DIG4),A               ; 0691  32 F6 23
          LD (SSFLG),A              ; 0694  32 F3 23
          LD (PRFLG),A              ; 0697  32 DA 23
          LD (PFLG),A               ; 069A  32 DE 23
          LD (MFLG),A               ; 069D  32 E1 23
          LD (RFLG),A               ; 06A0  32 DF 23
          LD (ARFLG),A              ; 06A3  32 E0 23
          RET                       ; 06A6  C9

; ----------------------------------------------------------------
; Blank the display memory
; ----------------------------------------------------------------
UFOR4:    LD B,08H                  ; 06A7  06 08
          LD HL,DISMEM              ; 06A9  21 F7 23
          LD A,10H                  ; 06AC  3E 10
UFOR4A:   LD (HL),A                 ; 06AE  77
          INC HL                    ; 06AF  23
          DJNZ UFOR4A               ; 06B0  10 FC
          RET                       ; 06B2  C9

; ----------------------------------------------------------------
; ASCII hex digit in A -> binary
; ----------------------------------------------------------------
UABIN:    SUB 30H                   ; 06B3  D6 30
          CP 0AH                    ; 06B5  FE 0A
          RET M                     ; 06B7  F8
          SUB 07H                   ; 06B8  D6 07
          RET                       ; 06BA  C9

; ----------------------------------------------------------------
; Binary digit in A -> ASCII
; ----------------------------------------------------------------
UBASC:    AND 0FH                   ; 06BB  E6 0F
          ADD A,90H                 ; 06BD  C6 90
          DAA                       ; 06BF  27
          ADC A,40H                 ; 06C0  CE 40
          DAA                       ; 06C2  27
          RET                       ; 06C3  C9

; ----------------------------------------------------------------
; Punch A as two characters, high nibble first
; ----------------------------------------------------------------
UPACC:    EXX                       ; 06C4  D9
          PUSH AF                   ; 06C5  F5
          RRCA                      ; 06C6  0F
          RRCA                      ; 06C7  0F
          RRCA                      ; 06C8  0F
          RRCA                      ; 06C9  0F
          CALL OTCHR                ; 06CA  CD F4 06
          POP AF                    ; 06CD  F1
          AND 0FH                   ; 06CE  E6 0F
          CALL OTCHR                ; 06D0  CD F4 06
          EXX                       ; 06D3  D9
          RET                       ; 06D4  C9

; ----------------------------------------------------------------
; Punch A and add it to the checksum in C
; ----------------------------------------------------------------
UPACCS:   PUSH AF                   ; 06D5  F5
          ADD A,C                   ; 06D6  81
          LD C,A                    ; 06D7  4F
          POP AF                    ; 06D8  F1
          JR UPACC                  ; 06D9  18 E9

; ----------------------------------------------------------------
; Read two characters from tape -> A; checksum in C
; ----------------------------------------------------------------
ULACC:    PUSH BC                   ; 06DB  C5
          CALL INCHR                ; 06DC  CD 58 07
          CALL UABIN                ; 06DF  CD B3 06
          RLCA                      ; 06E2  07
          RLCA                      ; 06E3  07
          RLCA                      ; 06E4  07
          RLCA                      ; 06E5  07
          LD C,A                    ; 06E6  4F
          CALL INCHR                ; 06E7  CD 58 07
          CALL UABIN                ; 06EA  CD B3 06
          OR C                      ; 06ED  B1
          POP BC                    ; 06EE  C1
          PUSH AF                   ; 06EF  F5
          ADD A,C                   ; 06F0  81
          LD C,A                    ; 06F1  4F
          POP AF                    ; 06F2  F1
          RET                       ; 06F3  C9

; ----------------------------------------------------------------
; Punch one character (KC: 1=4800Hz, 0=2400Hz) via CTC1
; ----------------------------------------------------------------
OTCHR:    CALL UBASC                ; 06F4  CD BB 06
OTCHR1:   EI                        ; 06F7  FB
          LD D,A                    ; 06F8  57
          LD A,10H                  ; 06F9  3E 10
          LD L,0AH                  ; 06FB  2E 0A
          RL D                      ; 06FD  CB 12
OTCHR2:   CP 01H                    ; 06FF  FE 01
          JR NZ,OTCHR2              ; 0701  20 FC
          LD B,A                    ; 0703  47
          LD A,00H                  ; 0704  3E 00
          LD (FLG24),A              ; 0706  32 D9 23
          LD A,B                    ; 0709  78
OTCHR3:   HALT                      ; 070A  76
          SCF                       ; 070B  37
          RR D                      ; 070C  CB 1A
          DEC L                     ; 070E  2D
          JR NZ,OTCHR4              ; 070F  20 07
          LD A,01H                  ; 0711  3E 01
          LD (FLG24),A              ; 0713  32 D9 23
          DI                        ; 0716  F3
          RET                       ; 0717  C9
OTCHR4:   CP 01H                    ; 0718  FE 01
          JR NZ,OTCHR4              ; 071A  20 FC
          BIT 0,D                   ; 071C  CB 42
          JR NZ,OTCHR5              ; 071E  20 09
          LD B,A                    ; 0720  47
          LD A,00H                  ; 0721  3E 00
          LD (FLG24),A              ; 0723  32 D9 23
          LD A,B                    ; 0726  78
          JR OTCHR3                 ; 0727  18 E1
OTCHR5:   LD B,A                    ; 0729  47
          LD A,01H                  ; 072A  3E 01
          LD (FLG24),A              ; 072C  32 D9 23
          LD A,B                    ; 072F  78
          JR OTCHR3                 ; 0730  18 D8

; ----------------------------------------------------------------
; CTC1 interrupt service during punch
; ----------------------------------------------------------------
OTCHR6:   DEC A                     ; 0732  3D
          JR NZ,OTCHR8              ; 0733  20 20
          LD IX,FLG24               ; 0735  DD 21 D9 23
          BIT 0,(IX+00H)            ; 0739  DD CB 00 46
          JR NZ,OTCHR7              ; 073D  20 0C
          LD A,85H                  ; 073F  3E 85
          OUT (CTC1),A              ; 0741  D3 85
          LD A,34H                  ; 0743  3E 34
          OUT (CTC1),A              ; 0745  D3 85
          LD A,08H                  ; 0747  3E 08
          JR OTCHR8                 ; 0749  18 0A
OTCHR7:   LD A,85H                  ; 074B  3E 85
          OUT (CTC1),A              ; 074D  D3 85
          LD A,1AH                  ; 074F  3E 1A
          OUT (CTC1),A              ; 0751  D3 85
          LD A,10H                  ; 0753  3E 10
OTCHR8:   EI                        ; 0755  FB
          RETI                      ; 0756  ED 4D

; ----------------------------------------------------------------
; Read one character from tape (CTC3 bit timing) -> A
; ----------------------------------------------------------------
INCHR:    LD HL,CTC3L               ; 0758  21 FE 07
          LD A,H                    ; 075B  7C
          LD I,A                    ; 075C  ED 47
          LD A,L                    ; 075E  7D
          OUT (CTC0),A              ; 075F  D3 84
INCHR1:   LD B,08H                  ; 0761  06 08
          EI                        ; 0763  FB
          LD A,00H                  ; 0764  3E 00
          LD H,00H                  ; 0766  26 00
INCHR1A:  IN A,(KBSEL)              ; 0768  DB 90
          BIT 7,A                   ; 076A  CB 7F
          JR NZ,INCHR1A             ; 076C  20 FA
          LD A,0A5H                 ; 076E  3E A5
          OUT (CTC3),A              ; 0770  D3 87
          LD A,0DH                  ; 0772  3E 0D
          OUT (CTC3),A              ; 0774  D3 87
          LD A,0A5H                 ; 0776  3E A5
          OUT (CTC3),A              ; 0778  D3 87
          LD A,1AH                  ; 077A  3E 1A
          OUT (CTC3),A              ; 077C  D3 87
          HALT                      ; 077E  76
          BIT 7,A                   ; 077F  CB 7F
          JR NZ,INCHR3              ; 0781  20 14
INCHR2:   HALT                      ; 0783  76
          AND 80H                   ; 0784  E6 80
          OR H                      ; 0786  B4
          LD H,A                    ; 0787  67
          DJNZ INCHR5               ; 0788  10 18
          BIT 7,A                   ; 078A  CB 7F
          JR Z,INCHR3               ; 078C  28 09
          DI                        ; 078E  F3
          LD A,03H                  ; 078F  3E 03
          OUT (CTC3),A              ; 0791  D3 87
          LD A,H                    ; 0793  7C
          AND 7FH                   ; 0794  E6 7F
          RET                       ; 0796  C9
INCHR3:   LD A,03H                  ; 0797  3E 03
          OUT (CTC3),A              ; 0799  D3 87
          JR INCHR1                 ; 079B  18 C4

; ----------------------------------------------------------------
; CTC3 interrupt service during load
; ----------------------------------------------------------------
INCHR4:   IN A,(KBSEL)              ; 079D  DB 90
          EI                        ; 079F  FB
          RETI                      ; 07A0  ED 4D
INCHR5:   RRC H                     ; 07A2  CB 0C
          JR INCHR2                 ; 07A4  18 DD

; ----------------------------------------------------------------
; Seven segment display patterns
; ----------------------------------------------------------------
SEGPT:    DB    40H                 ; 07A6  40  0
          DB    79H                 ; 07A7  79  1
          DB    24H                 ; 07A8  24  2
          DB    30H                 ; 07A9  30  3
          DB    19H                 ; 07AA  19  4
          DB    12H                 ; 07AB  12  5
          DB    02H                 ; 07AC  02  6
          DB    78H                 ; 07AD  78  7
          DB    00H                 ; 07AE  00  8
          DB    18H                 ; 07AF  18  9
          DB    08H                 ; 07B0  08  A
          DB    03H                 ; 07B1  03  B
          DB    46H                 ; 07B2  46  C
          DB    21H                 ; 07B3  21  D
          DB    06H                 ; 07B4  06  E
          DB    0EH                 ; 07B5  0E  F
          DB    7FH                 ; 07B6  7F  blank
          DB    3FH                 ; 07B7  3F  prompt
          DB    7DH                 ; 07B8  7D  prime

; ----------------------------------------------------------------
; Key value lookup table (row/column code -> key value)
; ----------------------------------------------------------------
KYTBL:    DB    0FFH                ; 07B9  FF  key 0
          DB    0EFH                ; 07BA  EF  key 1
          DB    0F7H                ; 07BB  F7  key 2
          DB    0FBH                ; 07BC  FB  key 3
          DB    0DFH                ; 07BD  DF  key 4
          DB    0E7H                ; 07BE  E7  key 5
          DB    0EBH                ; 07BF  EB  key 6
          DB    0CFH                ; 07C0  CF  key 7
          DB    0D7H                ; 07C1  D7  key 8
          DB    0DBH                ; 07C2  DB  key 9
          DB    0DDH                ; 07C3  DD  key A
          DB    0EDH                ; 07C4  ED  key B
          DB    0FDH                ; 07C5  FD  key C
          DB    0DH                 ; 07C6  0D  key D
          DB    0BH                 ; 07C7  0B  key E
          DB    07H                 ; 07C8  07  key F
          DB    0EH                 ; 07C9  0E  key EXEC
          DB    0FEH                ; 07CA  FE  key SS
          DB    0EEH                ; 07CB  EE  key MON
          DB    0DEH                ; 07CC  DE  key NEXT
          DB    0CDH                ; 07CD  CD  key REG' DISP
          DB    0CBH                ; 07CE  CB  key REG DISP
          DB    0C7H                ; 07CF  C7  key PORT EXAM
          DB    0BFH                ; 07D0  BF  key MEM EXAM
          DB    0BDH                ; 07D1  BD  key BP
          DB    0BBH                ; 07D2  BB  key PUNCH
          DB    0B7H                ; 07D3  B7  key LOAD
          DB    0AFH                ; 07D4  AF  key PROG

; ----------------------------------------------------------------
; REGTB: key value -> register offset on user stack
; ----------------------------------------------------------------
REGTB:    DB    25D                 ; 07D5  19  key 0 = --
          DB    2D                  ; 07D6  02  key 1 = PC
          DB    2D                  ; 07D7  02  key 2 = SP
          DB    12D                 ; 07D8  0C  key 3 = IFF
          DB    22D                 ; 07D9  16  key 4 = IX
          DB    24D                 ; 07DA  18  key 5 = IY
          DB    11D                 ; 07DB  0B  key 6 = I
          DB    9D                  ; 07DC  09  key 7 = H
          DB    10D                 ; 07DD  0A  key 8 = L
          DB    25D                 ; 07DE  19  key 9 = --
          DB    3D                  ; 07DF  03  key A = A
          DB    5D                  ; 07E0  05  key B = B
          DB    6D                  ; 07E1  06  key C = C
          DB    7D                  ; 07E2  07  key D = D
          DB    8D                  ; 07E3  08  key E = E
          DB    4D                  ; 07E4  04  key F = F

; ----------------------------------------------------------------
; REGTBP: same for the alternate register set
; ----------------------------------------------------------------
REGTBP:   DB    25D                 ; 07E5  19  key 0 = --
          DB    25D                 ; 07E6  19  key 1 = --
          DB    25D                 ; 07E7  19  key 2 = --
          DB    25D                 ; 07E8  19  key 3 = --
          DB    25D                 ; 07E9  19  key 4 = --
          DB    25D                 ; 07EA  19  key 5 = --
          DB    25D                 ; 07EB  19  key 6 = --
          DB    19D                 ; 07EC  13  key 7 = H'
          DB    20D                 ; 07ED  14  key 8 = L'
          DB    25D                 ; 07EE  19  key 9 = --
          DB    13D                 ; 07EF  0D  key A = A'
          DB    15D                 ; 07F0  0F  key B = B'
          DB    16D                 ; 07F1  10  key C = C'
          DB    17D                 ; 07F2  11  key D = D'
          DB    18D                 ; 07F3  12  key E = E'
          DB    14D                 ; 07F4  0E  key F = F'
FILL:     DB    0,0,0               ; 07F5  00 00 00

; ----------------------------------------------------------------
; CTC interrupt vector table (IM 2, I = 07H)
; ----------------------------------------------------------------
CTCVEC:   DW    CTC0U               ; 07F8  D6 23  CTC ch0 -> RAM (user)
CTC1P:    DW    OTCHR6              ; 07FA  32 07  CTC ch1 -> punch ISR
CTC2V:    DW    23DDH               ; 07FC  DD 23  CTC ch2 (no interrupt used)
CTC3L:    DW    INCHR4              ; 07FE  9D 07  CTC ch3 -> load ISR

          END
