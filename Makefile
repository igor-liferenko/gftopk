all:
	make -C web2w
	cp web2w/cgftopk.w gftopk.w
	ctangle gftopk
	gcc gftopk.c -o gftopk -lm
