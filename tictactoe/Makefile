# Build tic-tac-toe.plm into an Intel HEX file for the Z80 Starter Kit.
#
#   make          build tic-tac-toe.hex
#   make clean    remove build files
#
# Tools: ISIS-II PL/M-80 V4.0 (plm80), link, locate and objhex from the
# c-ports native builds. Note that /usr/bin/locate is the Linux file
# search command, so the Intel locate is called by its full path.
#
# The tools want ISIS-style names (up to 6 characters, no '-'):
#   - plm80 writes NAME.OBJ / NAME.LST with an upper-case extension
#   - link and locate fold names to lower case on disk
# so the source is compiled as TICTAC.PLM and the object renamed.
#
# Memory: code from RAMSTART, then stack, then variables. The program
# starts at the entry point given in the HEX end record (not RAMSTART,
# because PL/M puts constant tables and strings first); see the map
# printed by locate, or `make entry`.

RAMSTART ?= 3000H

CPORTS   ?= $(HOME)/dev/git/c-ports
PLM80    ?= plm80
LINK     ?= link
LOCATE   ?= $(CPORTS)/Linux/Install/locate
OBJHEX   ?= objhex
PLMLIB   ?= $(CPORTS)/plm80.lib

SRC      = tic-tac-toe.plm
NAME     = tictac
HEX      = tic-tac-toe.hex

all: $(HEX)

$(HEX): $(NAME).abs
	$(OBJHEX) $(NAME).abs TO $(NAME).hex
	mv $(NAME).hex $@
	@$(MAKE) --no-print-directory entry

$(NAME).abs: $(NAME).rel
	$(LOCATE) $(NAME).rel TO $(NAME).abs 'CODE($(RAMSTART))' MAP

$(NAME).rel: $(NAME).obj plm80.lib
	$(LINK) $(NAME).obj,plm80.lib TO $(NAME).rel MAP

$(NAME).obj: $(SRC)
	cp $(SRC) TICTAC.PLM
	$(PLM80) TICTAC.PLM
	@# plm80 exits 0 even on errors, so check the listing
	@grep -q ' 0 PROGRAM ERRORS' TICTAC.LST || \
	  { grep -A1 'ERROR #' TICTAC.LST; rm -f TICTAC.OBJ; echo 'PL/M compile failed'; exit 1; }
	mv TICTAC.OBJ $(NAME).obj

plm80.lib: $(PLMLIB)
	cp $(PLMLIB) plm80.lib

# Print the entry point from the HEX end record
entry: $(HEX)
	@awk '/^:00....01/ { print "Entry point: " substr($$0, 4, 4) "H" }' $(HEX)

clean:
	rm -f TICTAC.PLM TICTAC.LST $(NAME).obj $(NAME).rel $(NAME).abs \
	      $(NAME).hex plm80.lib $(HEX)

.PHONY: all entry clean
