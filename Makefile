all:
	make -C web2w
	tie -m gftopk.w web2w/cgftopk.w web2w/cgftopk.ch >/dev/null
	tie -c gftopk.ch gftopk.w max-row.ch preamble.ch >/dev/null
	ctangle gftopk gftopk
	gcc gftopk.c -o gftopk -lm
