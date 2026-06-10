all:
	make -C web2w
	tie -m gftopk.w web2w/cgftopk.w web2w/cgftopk.ch >/dev/null
	ctangle gftopk max-row
	gcc gftopk.c -o gftopk -lm
