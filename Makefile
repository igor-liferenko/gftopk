all:
	make -C web2w
	cp web2w/cgftopk.w gftopk.w
	ctangle gftopk nocomment
	gcc gftopk.c -o gftopk -lm
	cweave -f gftopk
