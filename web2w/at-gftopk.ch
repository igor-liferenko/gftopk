@x
  if (!following_directive(t)) wputs("@@+");
@y
  if (!following_directive(t)) wputs(" ");
@z

@x
  if (t->previous->tag==ATEX) wputs("@@!");
@y
@z

@x
     wputs("enum {@@+"), wid(t), wput('=');
     t=wprint_to(t->link->next,t->link->link);
     wputs("@@+};");
@y
     wputs("enum { "), wid(t), wput('=');
     t=wprint_to(t->link->next,t->link->link);
     wputs(" };");
@z

@x
        winsert_after(t,ATSEMICOLON,"@@;");
@y
        winsert_after(t,ATSEMICOLON," ");
@z
