Do not prepend "GFtoPK 2.4 output from " to comment in the beginning of PK file.
If environment variable 'pk_comment' is defined, prepend its value.

@x
if (i==0) k=comm_length-from_length;
else k=i+comm_length;
if (k > 255) pk_byte(255);@+else pk_byte(k);
for (k=1; k<=comm_length; k++)
  if ((i > 0)||(k <= comm_length-from_length)) pk_byte(xord[comment[k]]);
@y
char *pk_comment = getenv("pk_comment");
if (pk_comment) {
k=i+strlen(pk_comment);
if (k > 255) pk_byte(255);@+else pk_byte(k);
for (k=0; k<strlen(pk_comment); k++) pk_byte(*(pk_comment+k));
}
else pk_byte(i);
@z
