;======================================================================
; ZBUG monitor  --  U32 (0000H-07FFH)
; Raw linear-sweep disassembly of zbug-u32.bin (ORG 0000H).
;
; !! WARNING: THIS DUMP IS CORRUPT - DO NOT TRUST THIS LISTING !!
;
; Data bit 6 (D6, pin 16 on a 2716) intermittently reads as 1 when it
; should be 0. Errors only turn 0 into 1, and the same byte value reads
; correctly in some places and wrong in others, which points to a bad
; read (contact/timing), not a damaged ROM. The bad bytes can't be
; repaired in software because many real opcodes have bit 6 set.
;
; Known examples:
;   0000  71 C0 63   should be 31 C0 23   LD SP,23C0H
;   000E  58 43      should be 18 03      JR +3 (RST vectors 08/10/18/20;
;                                         the RST 28H copy at 002E is clean)
;   0008  LD (63E2H),SP vs 0049 LD (23E2H),IX  - same RAM variable 23E2H
;                    (115 refs to 23xx vs 7 to 63xx)
;   0087  CALL 467CH  should be CALL 067CH (65 calls to 06xx vs 4 to 46xx)
;   009C  JP 40F4H    should be JP 00F4H (U33 uses JP 00F4H)
;   00AE  CALL 46C6H  probably CALL 06C6H (U33 jumps to 00AEH)
;
; Memory map (ESoCoP notes): U32 0000-07FF, U33 0800-0FFF, RAM 2000-27FF.
; Any 4xxx/6xxx address below is almost certainly a bit-6 error.
;
; Not labelled, and code/data are not separated: every byte is decoded
; as an instruction (e.g. 07B7-07F7 look like keypad/display tables).
; Re-read U32 (compare several dumps) before relying on this.
;
; Columns: address  bytes  instruction  ; ASCII
;======================================================================

0000  71            LD (HL),C                ; q
0001  C0            RET NZ                   ; .
0002  63            LD H,E                   ; c
0003  C3 DF 40      JP 40DFH                 ; ..@
0006  FF            RST 38H                  ; .
0007  FF            RST 38H                  ; .
0008  ED 73 E2 63   LD (63E2H),SP            ; .s.c
000C  F5            PUSH AF                  ; .
000D  C5            PUSH BC                  ; .
000E  58            LD E,B                   ; X
000F  43            LD B,E                   ; C
0010  C3 C4 63      JP 63C4H                 ; ..c
0013  ED 57         LD A,I                   ; .W
0015  F3            DI                       ; .
0016  58            LD E,B                   ; X
0017  43            LD B,E                   ; C
0018  C3 C7 63      JP 63C7H                 ; ..c
001B  D5            PUSH DE                  ; .
001C  E5            PUSH HL                  ; .
001D  F5            PUSH AF                  ; .
001E  58            LD E,B                   ; X
001F  43            LD B,E                   ; C
0020  C3 CA 63      JP 63CAH                 ; ..c
0023  48            LD C,B                   ; H
0024  D9            EXX                      ; .
0025  F5            PUSH AF                  ; .
0026  58            LD E,B                   ; X
0027  43            LD B,E                   ; C
0028  C3 CD 23      JP 23CDH                 ; ..#
002B  C5            PUSH BC                  ; .
002C  D5            PUSH DE                  ; .
002D  E5            PUSH HL                  ; .
002E  18 03         JR 0033H                 ; ..
0030  C3 D0 23      JP 23D0H                 ; ..#
0033  DD E5         PUSH IX                  ; ..
0035  40            LD B,B                   ; @
0036  58            LD E,B                   ; X
0037  43            LD B,E                   ; C
0038  C3 D3 63      JP 63D3H                 ; ..c
003B  FD E5         PUSH IY                  ; ..
003D  7E            LD A,(HL)                ; ~
003E  43            LD B,E                   ; C
003F  D3 C6         OUT (0C6H),A             ; ..
0041  DD 6A         LD IXL,D                 ; .j
0043  E2 63 DD      JP PO,0DD63H             ; .c.
0046  23            INC HL                   ; #
0047  DD 23         INC IX                   ; .#
0049  DD 22 E2 23   LD (23E2H),IX            ; .".#
004D  DD 7E FE      LD A,(IX-02H)            ; .~.
0050  B7            OR A                     ; .
0051  20 03         JR NZ,0056H              ;  .
0053  DD 35 FF      DEC (IX-01H)             ; .5.
0056  DD 75 FE      LD (IX-02H),L            ; .u.
0059  DD 7E F4      LD A,(IX-0CH)            ; .~.
005C  E6 44         AND 44H                  ; .D
005E  72            LD (HL),D                ; r
005F  DD 63         LD IXH,E                 ; .c
0061  CD 7C 06      CALL 067CH               ; .|.
0064  58            LD E,B                   ; X
0065  43            LD B,E                   ; C
0066  C3 CB 41      JP 41CBH                 ; ..A
0069  68            LD L,B                   ; h
006A  53            LD D,E                   ; S
006B  DD 7E 42      LD A,(IX+42H)            ; .~B
006E  FE CF         CP 0CFH                  ; ..
0070  28 07         JR Z,0079H               ; (.
0072  DD 6E 01      LD L,(IX+01H)            ; .n.
0075  DD 66 00      LD H,(IX+00H)            ; .f.
0078  77            LD (HL),A                ; w
0079  CD 34 06      CALL 0634H               ; .4.
007C  20 ED         JR NZ,006BH              ;  .
007E  DD 21 F7 23   LD IX,23F7H              ; .!.#
0082  2A E2 63      LD HL,(63E2H)            ; *.c
0085  6B            LD L,E                   ; k
0086  7E            LD A,(HL)                ; ~
0087  CD 7C 46      CALL 467CH               ; .|F
008A  DD 23         INC IX                   ; .#
008C  DD 23         INC IX                   ; .#
008E  2B            DEC HL                   ; +
008F  7E            LD A,(HL)                ; ~
0090  CD 7C 46      CALL 467CH               ; .|F
0093  DD 63         LD IXH,E                 ; .c
0095  DD 63         LD IXH,E                 ; .c
0097  6B            LD L,E                   ; k
0098  7E            LD A,(HL)                ; ~
0099  CD 7C 46      CALL 467CH               ; .|F
009C  C3 F4 40      JP 40F4H                 ; ..@
009F  ED 73 E2 63   LD (63E2H),SP            ; .s.c
00A3  71            LD (HL),C                ; q
00A4  E8            RET PE                   ; .
00A5  23            INC HL                   ; #
00A6  7E            LD A,(HL)                ; ~
00A7  00            NOP                      ; .
00A8  32 F4 63      LD (63F4H),A             ; 2.c
00AB  32 DD 63      LD (63DDH),A             ; 2.c
00AE  CD C6 46      CALL 46C6H               ; ..F
00B1  3E 51         LD A,51H                 ; >Q
00B3  32 F7 23      LD (23F7H),A             ; 2.#
00B6  3E 10         LD A,10H                 ; >.
00B8  32 F8 23      LD (23F8H),A             ; 2.#
00BB  32 F9 23      LD (23F9H),A             ; 2.#
00BE  18 02         JR 00C2H                 ; ..
00C0  18 13         JR 00D5H                 ; ..
00C2  32 FA 23      LD (23FAH),A             ; 2.#
00C5  72            LD (HL),D                ; r
00C6  FB            EI                       ; .
00C7  63            LD H,E                   ; c
00C8  72            LD (HL),D                ; r
00C9  FC 23 DB      CALL M,0DB23H            ; .#.
00CC  D0            RET NC                   ; .
00CD  CB 6F         BIT 5,A                  ; .o
00CF  C2 F4 40      JP NZ,40F4H              ; ..@
00D2  C3 40 48      JP 4840H                 ; .@H
00D5  13            INC DE                   ; .
00D6  D5            PUSH DE                  ; .
00D7  DD E1         POP IX                   ; ..
00D9  53            LD D,E                   ; S
00DA  7D            LD A,L                   ; }
00DB  D3 6F         OUT (6FH),A              ; .o
00DD  DD 77 00      LD (IX+00H),A            ; .w.
00E0  7C            LD A,H                   ; |
00E1  9A            SBC A,D                  ; .
00E2  DD 21 F7 23   LD IX,23F7H              ; .!.#
00E6  CD 3C 06      CALL 063CH               ; .<.
00E9  DD 21 F9 23   LD IX,23F9H              ; .!.#
00ED  7D            LD A,L                   ; }
00EE  CD 7C 06      CALL 067CH               ; .|.
00F1  C3 F4 40      JP 40F4H                 ; ..@
00F4  21 F7 23      LD HL,23F7H              ; !.#
00F7  06 20         LD B,20H                 ; . 
00F9  5E            LD E,(HL)                ; ^
00FA  56            LD D,(HL)                ; V
00FB  00            NOP                      ; .
00FC  3E 00         LD A,00H                 ; >.
00FE  D3 8C         OUT (8CH),A              ; ..
0100  DD 21 A6 07   LD IX,07A6H              ; .!..
0104  DD 19         ADD IX,DE                ; ..
0106  DD 7E 00      LD A,(IX+00H)            ; .~.
0109  D3 88         OUT (88H),A              ; ..
010B  78            LD A,B                   ; x
010C  D3 8C         OUT (8CH),A              ; ..
010E  1E 2D         LD E,2DH                 ; .-
0110  1D            DEC E                    ; .
0111  3E 00         LD A,00H                 ; >.
0113  BB            CP E                     ; .
0114  20 FA         JR NZ,0110H              ;  .
0116  3E 01         LD A,01H                 ; >.
0118  B8            CP B                     ; .
0119  28 05         JR Z,0120H               ; (.
011B  23            INC HL                   ; #
011C  CB 38         SRL B                    ; .8
011E  18 D9         JR 00F9H                 ; ..
0120  C3 23 01      JP 0123H                 ; .#.
0123  3E 7F         LD A,7FH                 ; >.
0125  D3 88         OUT (88H),A              ; ..
0127  3E 3F         LD A,3FH                 ; >?
0129  D3 8C         OUT (8CH),A              ; ..
012B  DB 90         IN A,(90H)               ; ..
012D  E6 1F         AND 1FH                  ; ..
012F  FE 1F         CP 1FH                   ; ..
0131  CA F4 00      JP Z,00F4H               ; ...
0134  CD 4F 06      CALL 064FH               ; .O.
0137  0E 8C         LD C,8CH                 ; ..
0139  06 01         LD B,01H                 ; ..
013B  ED 41         OUT (C),B                ; .A
013D  DB 90         IN A,(90H)               ; ..
013F  E6 1F         AND 1FH                  ; ..
0141  FE 1F         CP 1FH                   ; ..
0143  20 0A         JR NZ,014FH              ;  .
0145  CB 60         BIT 4,B                  ; .`
0147  3E 40         LD A,40H                 ; >@
0149  B8            CP B                     ; .
014A  20 EF         JR NZ,013BH              ;  .
014C  C3 F4 00      JP 00F4H                 ; ...
014F  0E 00         LD C,00H                 ; ..
0151  0D            DEC C                    ; .
0152  CB 38         SRL B                    ; .8
0154  20 FB         JR NZ,0151H              ;  .
0156  CB 21         SLA C                    ; .!
0158  CB 21         SLA C                    ; .!
015A  CB 21         SLA C                    ; .!
015C  CB 21         SLA C                    ; .!
015E  81            ADD A,C                  ; .
015F  21 B9 07      LD HL,07B9H              ; !..
0162  BE            CP (HL)                  ; .
0163  28 04         JR Z,0169H               ; (.
0165  23            INC HL                   ; #
0166  04            INC B                    ; .
0167  18 F9         JR 0162H                 ; ..
0169  DB 90         IN A,(90H)               ; ..
016B  E6 1F         AND 1FH                  ; ..
016D  FE 1F         CP 1FH                   ; ..
016F  20 F8         JR NZ,0169H              ;  .
0171  CD 4F 06      CALL 064FH               ; .O.
0174  78            LD A,B                   ; x
0175  FE 10         CP 10H                   ; ..
0177  30 45         JR NC,01BEH              ; 0E
0179  2A DB 23      LD HL,(23DBH)            ; *.#
017C  70            LD (HL),B                ; p
017D  B7            OR A                     ; .
017E  01 F8 23      LD BC,23F8H              ; ..#
0181  ED 42         SBC HL,BC                ; .B
0183  28 20         JR Z,01A5H               ; ( 
0185  B7            OR A                     ; .
0186  01 FA 23      LD BC,23FAH              ; ..#
0189  2A DB 23      LD HL,(23DBH)            ; *.#
018C  ED 42         SBC HL,BC                ; .B
018E  28 1B         JR Z,01ABH               ; (.
0190  B7            OR A                     ; .
0191  01 FE 23      LD BC,23FEH              ; ..#
0194  2A DB 23      LD HL,(23DBH)            ; *.#
0197  ED 42         SBC HL,BC                ; .B
0199  28 16         JR Z,01B1H               ; (.
019B  2A DB 23      LD HL,(23DBH)            ; *.#
019E  23            INC HL                   ; #
019F  22 DB 23      LD (23DBH),HL            ; ".#
01A2  C3 F4 00      JP 00F4H                 ; ...
01A5  21 F5 23      LD HL,23F5H              ; !.#
01A8  34            INC (HL)                 ; 4
01A9  18 F0         JR 019BH                 ; ..
01AB  21 F6 23      LD HL,23F6H              ; !.#
01AE  34            INC (HL)                 ; 4
01AF  18 EA         JR 019BH                 ; ..
01B1  CD B4 03      CALL 03B4H               ; ...
01B4  2A DB 23      LD HL,(23DBH)            ; *.#
01B7  2B            DEC HL                   ; +
01B8  22 DB 23      LD (23DBH),HL            ; ".#
01BB  C3 F4 00      JP 00F4H                 ; ...
01BE  D6 10         SUB 10H                  ; ..
01C0  4F            LD C,A                   ; O
01C1  81            ADD A,C                  ; .
01C2  81            ADD A,C                  ; .
01C3  4F            LD C,A                   ; O
01C4  06 00         LD B,00H                 ; ..
01C6  21 0C 02      LD HL,020CH              ; !..
01C9  09            ADD HL,BC                ; .
01CA  E9            JP (HL)                  ; .
01CB  ED 73 E2 23   LD (23E2H),SP            ; .s.#
01CF  F5            PUSH AF                  ; .
01D0  3E 03         LD A,03H                 ; >.
01D2  D3 86         OUT (86H),A              ; ..
01D4  ED 57         LD A,I                   ; .W
01D6  C5            PUSH BC                  ; .
01D7  D5            PUSH DE                  ; .
01D8  E5            PUSH HL                  ; .
01D9  F5            PUSH AF                  ; .
01DA  08            EX AF,AF'                ; .
01DB  D9            EXX                      ; .
01DC  F5            PUSH AF                  ; .
01DD  C5            PUSH BC                  ; .
01DE  D5            PUSH DE                  ; .
01DF  E5            PUSH HL                  ; .
01E0  DD E5         PUSH IX                  ; ..
01E2  FD E5         PUSH IY                  ; ..
01E4  DD 2A E2 23   LD IX,(23E2H)            ; .*.#
01E8  DD 23         INC IX                   ; .#
01EA  DD 23         INC IX                   ; .#
01EC  DD 7E F4      LD A,(IX-0CH)            ; .~.
01EF  E6 04         AND 04H                  ; ..
01F1  32 DD 23      LD (23DDH),A             ; 2.#
01F4  DD 22 E2 23   LD (23E2H),IX            ; .".#
01F8  3A F3 23      LD A,(23F3H)             ; :.#
01FB  B7            OR A                     ; .
01FC  CA 23 01      JP Z,0123H               ; .#.
01FF  3E 00         LD A,00H                 ; >.
0201  32 F3 23      LD (23F3H),A             ; 2.#
0204  CD 7C 06      CALL 067CH               ; .|.
0207  CA 7E 00      JP Z,007EH               ; .~.
020A  18 42         JR 024EH                 ; .B
020C  C3 30 02      JP 0230H                 ; .0.
020F  C3 72 02      JP 0272H                 ; .r.
0212  C3 A1 02      JP 02A1H                 ; ...
0215  C3 A4 02      JP 02A4H                 ; ...
0218  C3 ED 02      JP 02EDH                 ; ...
021B  C3 08 03      JP 0308H                 ; ...
021E  C3 6B 03      JP 036BH                 ; .k.
0221  C3 95 03      JP 0395H                 ; ...
0224  C3 97 04      JP 0497H                 ; ...
0227  C3 CA 04      JP 04CAH                 ; ...
022A  C3 81 05      JP 0581H                 ; ...
022D  C3 D3 05      JP 05D3H                 ; ...
0230  3E 00         LD A,00H                 ; >.
0232  D3 8C         OUT (8CH),A              ; ..
0234  3A F6 23      LD A,(23F6H)             ; :.#
0237  B7            OR A                     ; .
0238  28 0D         JR Z,0247H               ; (.
023A  CD 59 06      CALL 0659H               ; .Y.
023D  DD 2A E2 23   LD IX,(23E2H)            ; .*.#
0241  DD 75 FE      LD (IX-02H),L            ; .u.
0244  DD 74 FF      LD (IX-01H),H            ; .t.
0247  CD 7C 06      CALL 067CH               ; .|.
024A  20 2B         JR NZ,0277H              ;  +
024C  18 16         JR 0264H                 ; ..
024E  DD 21 E4 23   LD IX,23E4H              ; .!.#
0252  DD 66 00      LD H,(IX+00H)            ; .f.
0255  DD 6E 01      LD L,(IX+01H)            ; .n.
0258  7E            LD A,(HL)                ; ~
0259  0E CF         LD C,0CFH                ; ..
025B  71            LD (HL),C                ; q
025C  DD 77 02      LD (IX+02H),A            ; .w.
025F  CD 34 06      CALL 0634H               ; .4.
0262  20 EE         JR NZ,0252H              ;  .
0264  3E 04         LD A,04H                 ; >.
0266  D3 8C         OUT (8CH),A              ; ..
0268  3E 45         LD A,45H                 ; >E
026A  D3 86         OUT (86H),A              ; ..
026C  3E 01         LD A,01H                 ; >.
026E  D3 86         OUT (86H),A              ; ..
0270  18 12         JR 0284H                 ; ..
0272  3E 00         LD A,00H                 ; >.
0274  32 F4 23      LD (23F4H),A             ; 2.#
0277  3E 01         LD A,01H                 ; >.
0279  32 F3 23      LD (23F3H),A             ; 2.#
027C  3E 07         LD A,07H                 ; >.
027E  D3 86         OUT (86H),A              ; ..
0280  3E 0B         LD A,0BH                 ; >.
0282  D3 86         OUT (86H),A              ; ..
0284  FD E1         POP IY                   ; ..
0286  DD E1         POP IX                   ; ..
0288  E1            POP HL                   ; .
0289  D1            POP DE                   ; .
028A  C1            POP BC                   ; .
028B  F1            POP AF                   ; .
028C  08            EX AF,AF'                ; .
028D  D9            EXX                      ; .
028E  F1            POP AF                   ; .
028F  ED 47         LD I,A                   ; .G
0291  E1            POP HL                   ; .
0292  D1            POP DE                   ; .
0293  C1            POP BC                   ; .
0294  3A DD 23      LD A,(23DDH)             ; :.#
0297  B7            OR A                     ; .
0298  C2 9E 02      JP NZ,029EH              ; ...
029B  F1            POP AF                   ; .
029C  F3            DI                       ; .
029D  C9            RET                      ; .
029E  F1            POP AF                   ; .
029F  FB            EI                       ; .
02A0  C9            RET                      ; .
02A1  C3 AE 00      JP 00AEH                 ; ...
02A4  3A E1 23      LD A,(23E1H)             ; :.#
02A7  FE 01         CP 01H                   ; ..
02A9  28 12         JR Z,02BDH               ; (.
02AB  3A DE 23      LD A,(23DEH)             ; :.#
02AE  FE 01         CP 01H                   ; ..
02B0  28 26         JR Z,02D8H               ; (&
02B2  3A DA 23      LD A,(23DAH)             ; :.#
02B5  FE 01         CP 01H                   ; ..
02B7  C2 AE 00      JP NZ,00AEH              ; ...
02BA  C3 30 06      JP 0630H                 ; .0.
02BD  CD 59 06      CALL 0659H               ; .Y.
02C0  23            INC HL                   ; #
02C1  7C            LD A,H                   ; |
02C2  CD 3C 06      CALL 063CH               ; .<.
02C5  DD 23         INC IX                   ; .#
02C7  DD 23         INC IX                   ; .#
02C9  7D            LD A,L                   ; }
02CA  CD 3C 06      CALL 063CH               ; .<.
02CD  DD 23         INC IX                   ; .#
02CF  DD 23         INC IX                   ; .#
02D1  7E            LD A,(HL)                ; ~
02D2  CD 3C 06      CALL 063CH               ; .<.
02D5  C3 F4 00      JP 00F4H                 ; ...
02D8  CD 59 06      CALL 0659H               ; .Y.
02DB  4C            LD C,H                   ; L
02DC  0C            INC C                    ; .
02DD  ED 78         IN A,(C)                 ; .x
02DF  79            LD A,C                   ; y
02E0  CD 3C 06      CALL 063CH               ; .<.
02E3  DD 21 FB 23   LD IX,23FBH              ; .!.#
02E7  CD 3C 06      CALL 063CH               ; .<.
02EA  C3 F4 00      JP 00F4H                 ; ...
02ED  3E 01         LD A,01H                 ; >.
02EF  32 E0 23      LD (23E0H),A             ; 2.#
02F2  DD 21 F7 23   LD IX,23F7H              ; .!.#
02F6  3E 12         LD A,12H                 ; >.
02F8  DD 77 01      LD (IX+01H),A            ; .w.
02FB  CD 55 04      CALL 0455H               ; .U.
02FE  7E            LD A,(HL)                ; ~
02FF  DD 21 FB 23   LD IX,23FBH              ; .!.#
0303  CD 3C 06      CALL 063CH               ; .<.
0306  18 5A         JR 0362H                 ; .Z
0308  3E 01         LD A,01H                 ; >.
030A  32 DF 23      LD (23DFH),A             ; 2.#
030D  CD 6E 04      CALL 046EH               ; .n.
0310  38 0A         JR C,031CH               ; 8.
0312  7E            LD A,(HL)                ; ~
0313  DD 21 FB 23   LD IX,23FBH              ; .!.#
0317  CD 3C 06      CALL 063CH               ; .<.
031A  18 46         JR 0362H                 ; .F
031C  FE 03         CP 03H                   ; ..
031E  28 35         JR Z,0355H               ; (5
0320  FE 02         CP 02H                   ; ..
0322  28 17         JR Z,033BH               ; (.
0324  7E            LD A,(HL)                ; ~
0325  DD 21 FB 23   LD IX,23FBH              ; .!.#
0329  DD 22 DB 23   LD (23DBH),IX            ; .".#
032D  CD 3C 06      CALL 063CH               ; .<.
0330  23            INC HL                   ; #
0331  7E            LD A,(HL)                ; ~
0332  DD 21 F9 23   LD IX,23F9H              ; .!.#
0336  CD 3C 06      CALL 063CH               ; .<.
0339  18 2D         JR 0368H                 ; .-
033B  3A E3 23      LD A,(23E3H)             ; :.#
033E  DD 21 F9 23   LD IX,23F9H              ; .!.#
0342  CD 3C 06      CALL 063CH               ; .<.
0345  3A E2 23      LD A,(23E2H)             ; :.#
0348  DD 21 FB 23   LD IX,23FBH              ; .!.#
034C  CD 3C 06      CALL 063CH               ; .<.
034F  DD 22 DB 23   LD (23DBH),IX            ; .".#
0353  18 13         JR 0368H                 ; ..
0355  DD 21 FB 23   LD IX,23FBH              ; .!.#
0359  3A DD 23      LD A,(23DDH)             ; :.#
035C  CD 3C 06      CALL 063CH               ; .<.
035F  21 FE 23      LD HL,23FEH              ; !.#
0362  21 FD 23      LD HL,23FDH              ; !.#
0365  22 DB 23      LD (23DBH),HL            ; ".#
0368  C3 F4 00      JP 00F4H                 ; ...
036B  3A F5 23      LD A,(23F5H)             ; :.#
036E  FE 01         CP 01H                   ; ..
0370  20 20         JR NZ,0392H              ;   
0372  32 DE 23      LD (23DEH),A             ; 2.#
0375  3E 10         LD A,10H                 ; >.
0377  32 F9 23      LD (23F9H),A             ; 2.#
037A  32 FA 23      LD (23FAH),A             ; 2.#
037D  CD 59 06      CALL 0659H               ; .Y.
0380  4C            LD C,H                   ; L
0381  ED 78         IN A,(C)                 ; .x
0383  DD 21 FB 23   LD IX,23FBH              ; .!.#
0387  CD 3C 06      CALL 063CH               ; .<.
038A  DD 23         INC IX                   ; .#
038C  DD 23         INC IX                   ; .#
038E  DD 22 DB 23   LD (23DBH),IX            ; .".#
0392  C3 F4 00      JP 00F4H                 ; ...
0395  3A F6 23      LD A,(23F6H)             ; :.#
0398  B7            OR A                     ; .
0399  28 16         JR Z,03B1H               ; (.
039B  32 E1 23      LD (23E1H),A             ; 2.#
039E  CD 59 06      CALL 0659H               ; .Y.
03A1  7E            LD A,(HL)                ; ~
03A2  DD 21 FB 23   LD IX,23FBH              ; .!.#
03A6  CD 3C 06      CALL 063CH               ; .<.
03A9  DD 23         INC IX                   ; .#
03AB  DD 23         INC IX                   ; .#
03AD  DD 22 DB 23   LD (23DBH),IX            ; .".#
03B1  C3 F4 00      JP 00F4H                 ; ...
03B4  DD 21 F7 23   LD IX,23F7H              ; .!.#
03B8  3A DE 23      LD A,(23DEH)             ; :.#
03BB  B7            OR A                     ; .
03BC  20 2A         JR NZ,03E8H              ;  *
03BE  3A DF 23      LD A,(23DFH)             ; :.#
03C1  B7            OR A                     ; .
03C2  20 35         JR NZ,03F9H              ;  5
03C4  3A E0 23      LD A,(23E0H)             ; :.#
03C7  B7            OR A                     ; .
03C8  C2 41 04      JP NZ,0441H              ; .A.
03CB  3A E1 23      LD A,(23E1H)             ; :.#
03CE  B7            OR A                     ; .
03CF  CA AE 00      JP Z,00AEH               ; ...
03D2  CD 59 06      CALL 0659H               ; .Y.
03D5  DD 7E 06      LD A,(IX+06H)            ; .~.
03D8  CD 8E 04      CALL 048EH               ; ...
03DB  DD B6 07      OR (IX+07H)              ; ...
03DE  77            LD (HL),A                ; w
03DF  7E            LD A,(HL)                ; ~
03E0  DD 21 FB 23   LD IX,23FBH              ; .!.#
03E4  CD 3C 06      CALL 063CH               ; .<.
03E7  C9            RET                      ; .
03E8  CD 59 06      CALL 0659H               ; .Y.
03EB  DD 7E 06      LD A,(IX+06H)            ; .~.
03EE  CD 8E 04      CALL 048EH               ; ...
03F1  DD B6 07      OR (IX+07H)              ; ...
03F4  4C            LD C,H                   ; L
03F5  ED 79         OUT (C),A                ; .y
03F7  18 E7         JR 03E0H                 ; ..
03F9  CD 6E 04      CALL 046EH               ; .n.
03FC  38 0D         JR C,040BH               ; 8.
03FE  DD 7E 06      LD A,(IX+06H)            ; .~.
0401  CD 8E 04      CALL 048EH               ; ...
0404  DD B6 07      OR (IX+07H)              ; ...
0407  77            LD (HL),A                ; w
0408  C3 E0 03      JP 03E0H                 ; ...
040B  FE 03         CP 03H                   ; ..
040D  28 24         JR Z,0433H               ; ($
040F  FE 02         CP 02H                   ; ..
0411  28 2A         JR Z,043DH               ; (*
0413  DD 7E 04      LD A,(IX+04H)            ; .~.
0416  CD 8E 04      CALL 048EH               ; ...
0419  DD B6 05      OR (IX+05H)              ; ...
041C  23            INC HL                   ; #
041D  77            LD (HL),A                ; w
041E  DD 21 F9 23   LD IX,23F9H              ; .!.#
0422  CD 3C 06      CALL 063CH               ; .<.
0425  DD 7E 04      LD A,(IX+04H)            ; .~.
0428  CD 8E 04      CALL 048EH               ; ...
042B  DD B6 05      OR (IX+05H)              ; ...
042E  2B            DEC HL                   ; +
042F  77            LD (HL),A                ; w
0430  C3 E0 03      JP 03E0H                 ; ...
0433  3A FE 23      LD A,(23FEH)             ; :.#
0436  32 DD 23      LD (23DDH),A             ; 2.#
0439  32 FC 23      LD (23FCH),A             ; 2.#
043C  C9            RET                      ; .
043D  E1            POP HL                   ; .
043E  C3 AE 00      JP 00AEH                 ; ...
0441  DD 21 F7 23   LD IX,23F7H              ; .!.#
0445  CD 55 04      CALL 0455H               ; .U.
0448  DD 7E 06      LD A,(IX+06H)            ; .~.
044B  CD 8E 04      CALL 048EH               ; ...
044E  DD B6 07      OR (IX+07H)              ; ...
0451  77            LD (HL),A                ; w
0452  C3 E0 03      JP 03E0H                 ; ...
0455  DD 5E 00      LD E,(IX+00H)            ; .^.
0458  06 00         LD B,00H                 ; ..
045A  16 00         LD D,00H                 ; ..
045C  21 E5 07      LD HL,07E5H              ; !..
045F  19            ADD HL,DE                ; .
0460  4E            LD C,(HL)                ; N
0461  79            LD A,C                   ; y
0462  FE 19         CP 19H                   ; ..
0464  CA AE 00      JP Z,00AEH               ; ...
0467  2A E2 23      LD HL,(23E2H)            ; *.#
046A  B7            OR A                     ; .
046B  ED 42         SBC HL,BC                ; .B
046D  C9            RET                      ; .
046E  DD 21 F7 23   LD IX,23F7H              ; .!.#
0472  DD 5E 00      LD E,(IX+00H)            ; .^.
0475  06 00         LD B,00H                 ; ..
0477  16 00         LD D,00H                 ; ..
0479  21 D5 07      LD HL,07D5H              ; !..
047C  19            ADD HL,DE                ; .
047D  4E            LD C,(HL)                ; N
047E  79            LD A,C                   ; y
047F  FE 19         CP 19H                   ; ..
0481  CA AE 00      JP Z,00AEH               ; ...
0484  2A E2 23      LD HL,(23E2H)            ; *.#
0487  7B            LD A,E                   ; {
0488  B7            OR A                     ; .
0489  ED 42         SBC HL,BC                ; .B
048B  FE 06         CP 06H                   ; ..
048D  C9            RET                      ; .
048E  CB 27         SLA A                    ; .'
0490  CB 27         SLA A                    ; .'
0492  CB 27         SLA A                    ; .'
0494  CB 27         SLA A                    ; .'
0496  C9            RET                      ; .
0497  3A F6 23      LD A,(23F6H)             ; :.#
049A  B7            OR A                     ; .
049B  20 05         JR NZ,04A2H              ;  .
049D  32 F4 23      LD (23F4H),A             ; 2.#
04A0  18 10         JR 04B2H                 ; ..
04A2  CD 59 06      CALL 0659H               ; .Y.
04A5  CD 7C 06      CALL 067CH               ; .|.
04A8  28 10         JR Z,04BAH               ; (.
04AA  78            LD A,B                   ; x
04AB  FE 05         CP 05H                   ; ..
04AD  20 06         JR NZ,04B5H              ;  .
04AF  C3 AE 00      JP 00AEH                 ; ...
04B2  C3 F4 00      JP 00F4H                 ; ...
04B5  CD 34 06      CALL 0634H               ; .4.
04B8  20 FB         JR NZ,04B5H              ;  .
04BA  3A F4 23      LD A,(23F4H)             ; :.#
04BD  3C            INC A                    ; <
04BE  32 F4 23      LD (23F4H),A             ; 2.#
04C1  DD 74 00      LD (IX+00H),H            ; .t.
04C4  DD 75 01      LD (IX+01H),L            ; .u.
04C7  C3 F4 00      JP 00F4H                 ; ...
04CA  CD A7 06      CALL 06A7H               ; ...
04CD  3E 01         LD A,01H                 ; >.
04CF  32 D9 23      LD (23D9H),A             ; 2.#
04D2  ED 5E         IM 2                     ; .^
04D4  01 FA 07      LD BC,07FAH              ; ...
04D7  78            LD A,B                   ; x
04D8  ED 47         LD I,A                   ; .G
04DA  79            LD A,C                   ; y
04DB  D3 84         OUT (84H),A              ; ..
04DD  3E 85         LD A,85H                 ; >.
04DF  D3 85         OUT (85H),A              ; ..
04E1  3E 1A         LD A,1AH                 ; >.
04E3  D3 85         OUT (85H),A              ; ..
04E5  3A C0 23      LD A,(23C0H)             ; :.#
04E8  57            LD D,A                   ; W
04E9  3A C1 23      LD A,(23C1H)             ; :.#
04EC  5F            LD E,A                   ; _
04ED  3A C2 23      LD A,(23C2H)             ; :.#
04F0  67            LD H,A                   ; g
04F1  3A C3 23      LD A,(23C3H)             ; :.#
04F4  6F            LD L,A                   ; o
04F5  AF            XOR A                    ; .
04F6  ED 52         SBC HL,DE                ; .R
04F8  23            INC HL                   ; #
04F9  E5            PUSH HL                  ; .
04FA  21 00 00      LD HL,0000H              ; !..
04FD  06 03         LD B,03H                 ; ..
04FF  FB            EI                       ; .
0500  76            HALT                     ; v
0501  2D            DEC L                    ; -
0502  20 FC         JR NZ,0500H              ;  .
0504  25            DEC H                    ; %
0505  20 F9         JR NZ,0500H              ;  .
0507  10 F7         DJNZ 0500H               ; ..
0509  3E 3A         LD A,3AH                 ; >:
050B  CD F7 06      CALL 06F7H               ; ...
050E  AF            XOR A                    ; .
050F  01 10 00      LD BC,0010H              ; ...
0512  E1            POP HL                   ; .
0513  ED 42         SBC HL,BC                ; .B
0515  30 09         JR NC,0520H              ; 0.
0517  09            ADD HL,BC                ; .
0518  85            ADD A,L                  ; .
0519  47            LD B,A                   ; G
051A  2E 00         LD L,00H                 ; ..
051C  28 3C         JR Z,055AH               ; (<
051E  18 01         JR 0521H                 ; ..
0520  41            LD B,C                   ; A
0521  E5            PUSH HL                  ; .
0522  0E 00         LD C,00H                 ; ..
0524  78            LD A,B                   ; x
0525  CD D5 06      CALL 06D5H               ; ...
0528  3A C0 23      LD A,(23C0H)             ; :.#
052B  67            LD H,A                   ; g
052C  CD D5 06      CALL 06D5H               ; ...
052F  3A C1 23      LD A,(23C1H)             ; :.#
0532  6F            LD L,A                   ; o
0533  CD D5 06      CALL 06D5H               ; ...
0536  AF            XOR A                    ; .
0537  CD D5 06      CALL 06D5H               ; ...
053A  7E            LD A,(HL)                ; ~
053B  CD D5 06      CALL 06D5H               ; ...
053E  23            INC HL                   ; #
053F  10 F9         DJNZ 053AH               ; ..
0541  97            SUB A                    ; .
0542  91            SUB C                    ; .
0543  CD D5 06      CALL 06D5H               ; ...
0546  3E 0D         LD A,0DH                 ; >.
0548  CD D5 06      CALL 06D5H               ; ...
054B  3E 0A         LD A,0AH                 ; >.
054D  CD D5 06      CALL 06D5H               ; ...
0550  7C            LD A,H                   ; |
0551  32 C0 23      LD (23C0H),A             ; 2.#
0554  7D            LD A,L                   ; }
0555  32 C1 23      LD (23C1H),A             ; 2.#
0558  18 AF         JR 0509H                 ; ..
055A  06 03         LD B,03H                 ; ..
055C  AF            XOR A                    ; .
055D  4F            LD C,A                   ; O
055E  CD D5 06      CALL 06D5H               ; ...
0561  10 F9         DJNZ 055CH               ; ..
0563  3E 01         LD A,01H                 ; >.
0565  CD D5 06      CALL 06D5H               ; ...
0568  97            SUB A                    ; .
0569  91            SUB C                    ; .
056A  CD D5 06      CALL 06D5H               ; ...
056D  21 FF FF      LD HL,0FFFFH             ; !..
0570  FB            EI                       ; .
0571  76            HALT                     ; v
0572  2D            DEC L                    ; -
0573  20 FD         JR NZ,0572H              ;  .
0575  25            DEC H                    ; %
0576  20 FA         JR NZ,0572H              ;  .
0578  F3            DI                       ; .
0579  3E 03         LD A,03H                 ; >.
057B  D3 85         OUT (85H),A              ; ..
057D  F3            DI                       ; .
057E  C3 AE 00      JP 00AEH                 ; ...
0581  ED 5E         IM 2                     ; .^
0583  21 FF 0F      LD HL,0FFFH              ; !..
0586  06 20         LD B,20H                 ; . 
0588  2D            DEC L                    ; -
0589  20 FD         JR NZ,0588H              ;  .
058B  25            DEC H                    ; %
058C  20 FA         JR NZ,0588H              ;  .
058E  10 F8         DJNZ 0588H               ; ..
0590  CD 58 07      CALL 0758H               ; .X.
0593  D6 3A         SUB 3AH                  ; .:
0595  20 F9         JR NZ,0590H              ;  .
0597  4F            LD C,A                   ; O
0598  CD DB 06      CALL 06DBH               ; ...
059B  47            LD B,A                   ; G
059C  CD DB 06      CALL 06DBH               ; ...
059F  57            LD D,A                   ; W
05A0  CD DB 06      CALL 06DBH               ; ...
05A3  5F            LD E,A                   ; _
05A4  CD DB 06      CALL 06DBH               ; ...
05A7  3D            DEC A                    ; =
05A8  F5            PUSH AF                  ; .
05A9  28 07         JR Z,05B2H               ; (.
05AB  CD DB 06      CALL 06DBH               ; ...
05AE  12            LD (DE),A                ; .
05AF  13            INC DE                   ; .
05B0  10 F9         DJNZ 05ABH               ; ..
05B2  CD DB 06      CALL 06DBH               ; ...
05B5  AF            XOR A                    ; .
05B6  81            ADD A,C                  ; .
05B7  28 14         JR Z,05CDH               ; (.
05B9  DD 21 F7 23   LD IX,23F7H              ; .!.#
05BD  7A            LD A,D                   ; z
05BE  CD 3C 06      CALL 063CH               ; .<.
05C1  DD 21 F9 23   LD IX,23F9H              ; .!.#
05C5  7B            LD A,E                   ; {
05C6  CD 3C 06      CALL 063CH               ; .<.
05C9  F1            POP AF                   ; .
05CA  C3 F4 00      JP 00F4H                 ; ...
05CD  F1            POP AF                   ; .
05CE  20 C0         JR NZ,0590H              ;  .
05D0  C3 AE 00      JP 00AEH                 ; ...
05D3  3E 01         LD A,01H                 ; >.
05D5  32 DA 23      LD (23DAH),A             ; 2.#
05D8  CD 59 06      CALL 0659H               ; .Y.
05DB  E5            PUSH HL                  ; .
05DC  C1            POP BC                   ; .
05DD  E5            PUSH HL                  ; .
05DE  21 00 28      LD HL,2800H              ; !.(
05E1  11 00 10      LD DE,1000H              ; ...
05E4  3E 25         LD A,25H                 ; >%
05E6  D3 86         OUT (86H),A              ; ..
05E8  3E CB         LD A,0CBH                ; >.
05EA  D3 86         OUT (86H),A              ; ..
05EC  3E 80         LD A,80H                 ; >.
05EE  D3 8C         OUT (8CH),A              ; ..
05F0  ED A0         LDI                      ; ..
05F2  3E 00         LD A,00H                 ; >.
05F4  D3 8C         OUT (8CH),A              ; ..
05F6  3E 03         LD A,03H                 ; >.
05F8  D3 86         OUT (86H),A              ; ..
05FA  EA E4 05      JP PE,05E4H              ; ...
05FD  C1            POP BC                   ; .
05FE  21 00 28      LD HL,2800H              ; !.(
0601  11 00 10      LD DE,1000H              ; ...
0604  1A            LD A,(DE)                ; .
0605  ED A1         CPI                      ; ..
0607  20 06         JR NZ,060FH              ;  .
0609  E2 AE 00      JP PO,00AEH              ; ...
060C  13            INC DE                   ; .
060D  18 F5         JR 0604H                 ; ..
060F  F5            PUSH AF                  ; .
0610  C5            PUSH BC                  ; .
0611  D5            PUSH DE                  ; .
0612  D9            EXX                      ; .
0613  D1            POP DE                   ; .
0614  C1            POP BC                   ; .
0615  DD 21 F7 23   LD IX,23F7H              ; .!.#
0619  7A            LD A,D                   ; z
061A  CD 3C 06      CALL 063CH               ; .<.
061D  DD 21 F9 23   LD IX,23F9H              ; .!.#
0621  7B            LD A,E                   ; {
0622  CD 3C 06      CALL 063CH               ; .<.
0625  DD 21 FB 23   LD IX,23FBH              ; .!.#
0629  F1            POP AF                   ; .
062A  CD 3C 06      CALL 063CH               ; .<.
062D  C3 F4 00      JP 00F4H                 ; ...
0630  D9            EXX                      ; .
0631  13            INC DE                   ; .
0632  18 D0         JR 0604H                 ; ..
0634  DD 23         INC IX                   ; .#
0636  DD 23         INC IX                   ; .#
0638  DD 23         INC IX                   ; .#
063A  05            DEC B                    ; .
063B  C9            RET                      ; .
063C  47            LD B,A                   ; G
063D  E6 0F         AND 0FH                  ; ..
063F  DD 77 01      LD (IX+01H),A            ; .w.
0642  78            LD A,B                   ; x
0643  CB 3F         SRL A                    ; .?
0645  CB 3F         SRL A                    ; .?
0647  CB 3F         SRL A                    ; .?
0649  CB 3F         SRL A                    ; .?
064B  DD 77 00      LD (IX+00H),A            ; .w.
064E  C9            RET                      ; .
064F  21 FF 08      LD HL,08FFH              ; !..
0652  2D            DEC L                    ; -
0653  20 FD         JR NZ,0652H              ;  .
0655  25            DEC H                    ; %
0656  20 FA         JR NZ,0652H              ;  .
0658  C9            RET                      ; .
0659  DD 21 F7 23   LD IX,23F7H              ; .!.#
065D  DD 7E 00      LD A,(IX+00H)            ; .~.
0660  CB 27         SLA A                    ; .'
0662  CB 27         SLA A                    ; .'
0664  CB 27         SLA A                    ; .'
0666  CB 27         SLA A                    ; .'
0668  DD B6 01      OR (IX+01H)              ; ...
066B  67            LD H,A                   ; g
066C  DD 7E 02      LD A,(IX+02H)            ; .~.
066F  CB 27         SLA A                    ; .'
0671  CB 27         SLA A                    ; .'
0673  CB 27         SLA A                    ; .'
0675  CB 27         SLA A                    ; .'
0677  DD B6 03      OR (IX+03H)              ; ...
067A  6F            LD L,A                   ; o
067B  C9            RET                      ; .
067C  DD 21 E4 23   LD IX,23E4H              ; .!.#
0680  3A F4 23      LD A,(23F4H)             ; :.#
0683  B7            OR A                     ; .
0684  47            LD B,A                   ; G
0685  C9            RET                      ; .
0686  21 F7 23      LD HL,23F7H              ; !.#
0689  22 DB 23      LD (23DBH),HL            ; ".#
068C  3E 00         LD A,00H                 ; >.
068E  32 F5 23      LD (23F5H),A             ; 2.#
0691  32 F6 23      LD (23F6H),A             ; 2.#
0694  32 F3 23      LD (23F3H),A             ; 2.#
0697  32 DA 23      LD (23DAH),A             ; 2.#
069A  32 DE 23      LD (23DEH),A             ; 2.#
069D  32 E1 23      LD (23E1H),A             ; 2.#
06A0  32 DF 23      LD (23DFH),A             ; 2.#
06A3  32 E0 23      LD (23E0H),A             ; 2.#
06A6  C9            RET                      ; .
06A7  06 08         LD B,08H                 ; ..
06A9  21 F7 23      LD HL,23F7H              ; !.#
06AC  3E 10         LD A,10H                 ; >.
06AE  77            LD (HL),A                ; w
06AF  23            INC HL                   ; #
06B0  10 FC         DJNZ 06AEH               ; ..
06B2  C9            RET                      ; .
06B3  D6 30         SUB 30H                  ; .0
06B5  FE 0A         CP 0AH                   ; ..
06B7  F8            RET M                    ; .
06B8  D6 07         SUB 07H                  ; ..
06BA  C9            RET                      ; .
06BB  E6 0F         AND 0FH                  ; ..
06BD  C6 90         ADD A,90H                ; ..
06BF  27            DAA                      ; '
06C0  CE 40         ADC A,40H                ; .@
06C2  27            DAA                      ; '
06C3  C9            RET                      ; .
06C4  D9            EXX                      ; .
06C5  F5            PUSH AF                  ; .
06C6  0F            RRCA                     ; .
06C7  0F            RRCA                     ; .
06C8  0F            RRCA                     ; .
06C9  0F            RRCA                     ; .
06CA  CD F4 06      CALL 06F4H               ; ...
06CD  F1            POP AF                   ; .
06CE  E6 0F         AND 0FH                  ; ..
06D0  CD F4 06      CALL 06F4H               ; ...
06D3  D9            EXX                      ; .
06D4  C9            RET                      ; .
06D5  F5            PUSH AF                  ; .
06D6  81            ADD A,C                  ; .
06D7  4F            LD C,A                   ; O
06D8  F1            POP AF                   ; .
06D9  18 E9         JR 06C4H                 ; ..
06DB  C5            PUSH BC                  ; .
06DC  CD 58 07      CALL 0758H               ; .X.
06DF  CD B3 06      CALL 06B3H               ; ...
06E2  07            RLCA                     ; .
06E3  07            RLCA                     ; .
06E4  07            RLCA                     ; .
06E5  07            RLCA                     ; .
06E6  4F            LD C,A                   ; O
06E7  CD 58 07      CALL 0758H               ; .X.
06EA  CD B3 06      CALL 06B3H               ; ...
06ED  B1            OR C                     ; .
06EE  C1            POP BC                   ; .
06EF  F5            PUSH AF                  ; .
06F0  81            ADD A,C                  ; .
06F1  4F            LD C,A                   ; O
06F2  F1            POP AF                   ; .
06F3  C9            RET                      ; .
06F4  CD BB 06      CALL 06BBH               ; ...
06F7  FB            EI                       ; .
06F8  57            LD D,A                   ; W
06F9  3E 10         LD A,10H                 ; >.
06FB  2E 0A         LD L,0AH                 ; ..
06FD  CB 12         RL D                     ; ..
06FF  FE 01         CP 01H                   ; ..
0701  20 FC         JR NZ,06FFH              ;  .
0703  47            LD B,A                   ; G
0704  3E 00         LD A,00H                 ; >.
0706  32 D9 23      LD (23D9H),A             ; 2.#
0709  78            LD A,B                   ; x
070A  76            HALT                     ; v
070B  37            SCF                      ; 7
070C  CB 1A         RR D                     ; ..
070E  2D            DEC L                    ; -
070F  20 07         JR NZ,0718H              ;  .
0711  3E 01         LD A,01H                 ; >.
0713  32 D9 23      LD (23D9H),A             ; 2.#
0716  F3            DI                       ; .
0717  C9            RET                      ; .
0718  FE 01         CP 01H                   ; ..
071A  20 FC         JR NZ,0718H              ;  .
071C  CB 42         BIT 0,D                  ; .B
071E  20 09         JR NZ,0729H              ;  .
0720  47            LD B,A                   ; G
0721  3E 00         LD A,00H                 ; >.
0723  32 D9 23      LD (23D9H),A             ; 2.#
0726  78            LD A,B                   ; x
0727  18 E1         JR 070AH                 ; ..
0729  47            LD B,A                   ; G
072A  3E 01         LD A,01H                 ; >.
072C  32 D9 23      LD (23D9H),A             ; 2.#
072F  78            LD A,B                   ; x
0730  18 D8         JR 070AH                 ; ..
0732  3D            DEC A                    ; =
0733  20 20         JR NZ,0755H              ;   
0735  DD 21 D9 23   LD IX,23D9H              ; .!.#
0739  DD CB 00 46   BIT 0,(IX+00H)           ; ...F
073D  20 0C         JR NZ,074BH              ;  .
073F  3E 85         LD A,85H                 ; >.
0741  D3 85         OUT (85H),A              ; ..
0743  3E 34         LD A,34H                 ; >4
0745  D3 85         OUT (85H),A              ; ..
0747  3E 08         LD A,08H                 ; >.
0749  18 0A         JR 0755H                 ; ..
074B  3E 85         LD A,85H                 ; >.
074D  D3 85         OUT (85H),A              ; ..
074F  3E 1A         LD A,1AH                 ; >.
0751  D3 85         OUT (85H),A              ; ..
0753  3E 10         LD A,10H                 ; >.
0755  FB            EI                       ; .
0756  ED 4D         RETI                     ; .M
0758  21 FE 07      LD HL,07FEH              ; !..
075B  7C            LD A,H                   ; |
075C  ED 47         LD I,A                   ; .G
075E  7D            LD A,L                   ; }
075F  D3 84         OUT (84H),A              ; ..
0761  06 08         LD B,08H                 ; ..
0763  FB            EI                       ; .
0764  3E 00         LD A,00H                 ; >.
0766  26 00         LD H,00H                 ; &.
0768  DB 90         IN A,(90H)               ; ..
076A  CB 7F         BIT 7,A                  ; ..
076C  20 FA         JR NZ,0768H              ;  .
076E  3E A5         LD A,0A5H                ; >.
0770  D3 87         OUT (87H),A              ; ..
0772  3E 0D         LD A,0DH                 ; >.
0774  D3 87         OUT (87H),A              ; ..
0776  3E A5         LD A,0A5H                ; >.
0778  D3 87         OUT (87H),A              ; ..
077A  3E 1A         LD A,1AH                 ; >.
077C  D3 87         OUT (87H),A              ; ..
077E  76            HALT                     ; v
077F  CB 7F         BIT 7,A                  ; ..
0781  20 14         JR NZ,0797H              ;  .
0783  76            HALT                     ; v
0784  E6 80         AND 80H                  ; ..
0786  B4            OR H                     ; .
0787  67            LD H,A                   ; g
0788  10 18         DJNZ 07A2H               ; ..
078A  CB 7F         BIT 7,A                  ; ..
078C  28 09         JR Z,0797H               ; (.
078E  F3            DI                       ; .
078F  3E 03         LD A,03H                 ; >.
0791  D3 87         OUT (87H),A              ; ..
0793  7C            LD A,H                   ; |
0794  E6 7F         AND 7FH                  ; ..
0796  C9            RET                      ; .
0797  3E 03         LD A,03H                 ; >.
0799  D3 87         OUT (87H),A              ; ..
079B  18 C4         JR 0761H                 ; ..
079D  DB 90         IN A,(90H)               ; ..
079F  FB            EI                       ; .
07A0  ED 4D         RETI                     ; .M
07A2  CB 0C         RRC H                    ; ..
07A4  18 DD         JR 0783H                 ; ..
07A6  40            LD B,B                   ; @
07A7  79            LD A,C                   ; y
07A8  24            INC H                    ; $
07A9  30 19         JR NC,07C4H              ; 0.
07AB  12            LD (DE),A                ; .
07AC  02            LD (BC),A                ; .
07AD  78            LD A,B                   ; x
07AE  00            NOP                      ; .
07AF  18 08         JR 07B9H                 ; ..
07B1  03            INC BC                   ; .
07B2  46            LD B,(HL)                ; F
07B3  21 06 0E      LD HL,0E06H              ; !..
07B6  7F            LD A,A                   ; .
07B7  3F            CCF                      ; ?
07B8  7D            LD A,L                   ; }
07B9  FF            RST 38H                  ; .
07BA  EF            RST 28H                  ; .
07BB  F7            RST 30H                  ; .
07BC  FB            EI                       ; .
07BD  DF            RST 18H                  ; .
07BE  E7            RST 20H                  ; .
07BF  EB            EX DE,HL                 ; .
07C0  CF            RST 08H                  ; .
07C1  D7            RST 10H                  ; .
07C2  DB DD         IN A,(0DDH)              ; ..
07C4  ED FD         DB 0EDH,0FDH	; invalid ED ; ..
07C6  0D            DEC C                    ; .
07C7  0B            DEC BC                   ; .
07C8  07            RLCA                     ; .
07C9  0E FE         LD C,0FEH                ; ..
07CB  EE DE         XOR 0DEH                 ; ..
07CD  CD CB C7      CALL 0C7CBH              ; ...
07D0  BF            CP A                     ; .
07D1  BD            CP L                     ; .
07D2  BB            CP E                     ; .
07D3  B7            OR A                     ; .
07D4  AF            XOR A                    ; .
07D5  19            ADD HL,DE                ; .
07D6  02            LD (BC),A                ; .
07D7  02            LD (BC),A                ; .
07D8  0C            INC C                    ; .
07D9  16 18         LD D,18H                 ; ..
07DB  0B            DEC BC                   ; .
07DC  09            ADD HL,BC                ; .
07DD  0A            LD A,(BC)                ; .
07DE  19            ADD HL,DE                ; .
07DF  03            INC BC                   ; .
07E0  05            DEC B                    ; .
07E1  06 07         LD B,07H                 ; ..
07E3  08            EX AF,AF'                ; .
07E4  04            INC B                    ; .
07E5  19            ADD HL,DE                ; .
07E6  19            ADD HL,DE                ; .
07E7  19            ADD HL,DE                ; .
07E8  19            ADD HL,DE                ; .
07E9  19            ADD HL,DE                ; .
07EA  19            ADD HL,DE                ; .
07EB  19            ADD HL,DE                ; .
07EC  13            INC DE                   ; .
07ED  14            INC D                    ; .
07EE  19            ADD HL,DE                ; .
07EF  0D            DEC C                    ; .
07F0  0F            RRCA                     ; .
07F1  10 11         DJNZ 0804H               ; ..
07F3  12            LD (DE),A                ; .
07F4  0E 00         LD C,00H                 ; ..
07F6  00            NOP                      ; .
07F7  00            NOP                      ; .
07F8  D6 23         SUB 23H                  ; .#
07FA  32 07 DD      LD (0DD07H),A            ; 2..
07FD  23            INC HL                   ; #
07FE  9D            SBC A,L                  ; .
07FF  07            RLCA                     ; .
