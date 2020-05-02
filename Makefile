AS = ca65
CC = cc65
LD = ld65
IPS = flips.exe

.PHONY: clean

%.o: %.asm
	$(AS) -g --debug-info $< -o $@

smb1-glitchedworlds.zip: patch.ips
	zip $@ patch.ips README.md

patch.ips: main.nes
	$(IPS) --create --ips "original.nes" "main.nes" $@

main.nes: layout main.o
	$(LD)  --dbgfile $@.dbg -C $^ -o $@

clean:
	rm -f smb1-glitchedworlds.zip main*.nes patch.ips *.o
