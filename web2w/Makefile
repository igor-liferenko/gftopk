all:
	tie -c web2w.ch web2w.w tab.ch web2w-gftopk.ch at-gftopk.ch >/dev/null
	ctangle web2w web2w
	patch -so web-gftopk.l web.l web-gftopk.patch
	flex -o web.lex.c web-gftopk.l
	patch -so pascal-gftopk.y pascal.y pascal-gftopk.patch
	bison --warnings=none -d -v pascal-gftopk.y
	gcc -o web2w web2w.c web.lex.c pascal-gftopk.tab.c
	cp gftopk.web gftopk-web2w.web
	@sed -i "s/\([,(]\)'\([ !]\|''\)'/\1'\2_'/g" gftopk-web2w.web
	@sed -i '/@d four_cases/,+6s/+/,/g' gftopk-web2w.web
	@sed -i 's/|packed file of 0..255|//' gftopk-web2w.web
	./web2w -o cgftopk.w gftopk-web2w.web
	@sed -i 's/"\(.\)_"/"\1"/g' cgftopk.w
	@sed -i '/@d four_cases/,+6s/: case/+/g' cgftopk.w
	patch -s cgftopk.w cgftopk.patch
