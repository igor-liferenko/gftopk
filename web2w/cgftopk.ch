@x
{ reset(gf_file, gf_name);
@y
{ reset(gf_file, gf_name); assert(gf_file.f!=NULL); assert(!ferror(gf_file.f));
@z

@x
{ rewrite(pk_file, pk_name);
@y
{ rewrite(pk_file, pk_name); assert(pk_file.f!=NULL);
@z
