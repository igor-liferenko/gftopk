Do not prepend "GFtoPK 2.4 output from " to PK comment.

@x
if (i==0) k=comm_length-from_length;
else k=i+comm_length;
if (k > 255) pk_byte(255); else pk_byte(k);
for (k=1; k<=comm_length; k++)
  if ((i > 0)||(k <= comm_length-from_length)) pk_byte(xord[comment[k]]);
print("'");
for (k=1; k<=i; k++)
  { if (k > 1) j=gf_byte();
  print("%c",xchr[j]);
  if (k < 256-comm_length) pk_byte(j);
  }
@y
if (i==0) k=comm_length-from_length;
else k=i;
pk_byte(k);
if (i==0)
  for (k=1; k<=comm_length-from_length; k++)
    pk_byte(xord[comment[k]]);
print("'");
for (k=1; k<=i; k++)
  { if (k > 1) j=gf_byte();
  print("%c",xchr[j]);
  pk_byte(j);
  }
@z
