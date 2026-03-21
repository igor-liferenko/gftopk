all:
	make -C web2w
	tie -m gftopk.w web2w/cgftopk.w web2w/cgftopk.ch >/dev/null
	ctangle gftopk
	gcc gftopk.c -o gftopk -lm
