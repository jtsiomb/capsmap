.PHONY: all
all: capsmap.com testkeys.com

capsmap.com: capsmap.asm
testkeys.com: testkeys.asm

%.com: %.asm
	nasm -o $@ -f bin $<

.PHONY: clean
clean:
	rm -f capsmap.com testkeys.com
