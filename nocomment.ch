@x
if (i==0) k=comm_length-from_length;
else k=i+comm_length;
if (k > 255) pk_byte(255);@+else pk_byte(k);
for (k=1; k<=comm_length; k++) 
  if ((i > 0)||(k <= comm_length-from_length)) pk_byte(xord[comment[k]]);
@y
pk_byte(i);
@z
