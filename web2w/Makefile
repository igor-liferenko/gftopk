all:
	ctangle web2w web2w-gftopk
	patch -so web-gftopk.l web.l web-gftopk.patch
	flex -o web.lex.c web-gftopk.l
	patch -so pascal-gftopk.y pascal.y pascal-gftopk.patch
	bison --warnings=none -d -v pascal-gftopk.y
	gcc -o web2w web2w.c web.lex.c pascal-gftopk.tab.c
	@sed '1106s/file/File/;1404,1410s/+/,/g' gftopk.web >gftopk-web2w.web
	./web2w -o cgftopk.w gftopk-web2w.web
	patch -s cgftopk.w cgftopk.patch
	weave gftopk >/dev/null && sed -i 1s/webmac/pwebmac/ gftopk.tex
