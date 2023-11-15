AS = ca65
CC = cc65
LD = ld65
IPS = flips

.PHONY: clean

build: smb1-glitchedworlds.zip

%.o: %.asm
	$(AS) -g --create-dep "$@.dep" --debug-info $< -o $@

smb1-glitchedworlds.zip: patch.ips
	zip patch.zip patch.ips README.md

patch.ips: main.nes
	python3 scripts/ips.py create --output patch.ips "Super Mario Bros. (World).nes" main.nes

main.nes: layout main.o
	$(LD) --dbgfile main.dbg -C $^ -o $@

clean:
	rm -f main.nes *.dep *.o *.dbg *.ips *.zip

include $(wildcard *.dep)

