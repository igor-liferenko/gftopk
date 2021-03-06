% This program is by Tomas Rokicki.  A few routines were borrowed from
% GFtoPXL by Arthur Samuel, who borrowed from GFtype by DRF and DEK,
% who borrowed from DVItype, and so on.

% Version 0.0 (development): started 26 July 1985 TGR.
% Version 1.0: finished 29 July 1985 TGR.
% Version 1.1: revised for new pk format 9 August 1985 TGR.
% Version 1.2: fixed two's complement bug 23 January 1985 TGR.
% Version 1.3: fixed bounding box calculations and some documentation.
%                                     7 September 1986 TGR
% Version 1.4: fixed row to glyph conversion 14 November 1987 TGR
% Version 1.5: eliminated semicolons before endcases 12 July 1988 TGR
% Version 2.0: slightly tuned up for METAFONTware report 17 Apr 1989 DEK/TGR
% Version 2.1: fixed paint0/endrow bug reported by John Hobby 31 Jul 1989 TGR
% Version 2.2: minor tune up; retain previous source info 21 Nov 1989 don
% Version 2.3: fixed a few bugs with selection of preamble types, if
%  gf_ch < 0, or if comp_size = 1016 (both unlikely).  Removed some
%  code that would never get executed since bad_gf terminates.  Also
%  some other nits that don't really affect functionality.  29 Jul 1990  TGR
%  Bugs and fixes reported by Peter Breitenlohner (PEB).
%  Corrected two typos -- 21 Dec 96 (don)
% Version 2.4: fixed cases that might move to negative. 06 January 2014 PEB

\def\versiondate{06 January 2014}

% Here is TeX material that gets inserted after \input webmac
\def\hang{\hangindent 3em\noindent\ignorespaces}
\def\textindent#1{\hangindent2.5em\noindent\hbox to2.5em{\hss#1 }\ignorespaces}
\font\ninerm=cmr9
\let\mc=\ninerm % medium caps for names like SAIL
\font\tenss=cmss10 % for `The METAFONTbook'
\def\PASCAL{Pascal}
\def\ph{{\mc PASCAL-H}}
\font\logo=manfnt % font used for the METAFONT logo
\def\MF{{\logo META}\-{\logo FONT}}
\def\<#1>{$\langle#1\rangle$}
\def\section{\mathhexbox278}
\let\swap=\leftrightarrow
\def\round{\mathop{\rm round}\nolimits}

\def\(#1){} % this is used to make section names sort themselves better
\def\9#1{} % this is used for sort keys in the index via @@:sort key}{entry@@>

\def\title{GFtoPK}
\def\contentspagenumber{201}
\def\topofcontents{\null
  \titlefalse % include headline on the contents page
  \def\rheader{\mainfont\hfil \contentspagenumber}
  \vfill
  \centerline{\titlefont The {\ttitlefont GFtoPK} processor}
  \vskip 15pt
  \centerline{(Version 2.4, \versiondate)}
  \vfill}
\def\botofcontents{\vfill
  \centerline{\hsize 5in\baselineskip9pt
    \vbox{\ninerm\noindent
    The preparation of this report
    was supported in part by the National Science
    Foundation under grants IST-8201926, MCS-8300984, and
    CCR-8610181,
    and by the System Development Foundation. `\TeX' is a
    trademark of the American Mathematical Society.
    `{\logo hijklmnj}\kern1pt' is a trademark of Addison-Wesley
    Publishing Company.}}}
\pageno=\contentspagenumber \advance\pageno by 1

@*Introduction.
This program reads a \.{GF} file and packs it into a \.{PK} file.  \.{PK} files
are significantly smaller than \.{GF} files, and they are much easier to
interpret.  This program is meant to be the bridge between \MF\ and \.{DVI}
drivers that read \.{PK} files.  Here are some statistics comparing typical
input and output file sizes:

$$\vbox{
\halign{#\hfil\quad&\hfil#\qquad&&\hfil#\quad\cr
Font&\omit\hfil Resolution\hfil\quad
 &\.{GF} size&\.{PK} size&Reduction factor\cr
\noalign{\medskip}
cmr10&300&13200&5484&42\char`\%\cr
cmr10&360&15342&6496&42\char`\%\cr
cmr10&432&18120&7808&43\char`\%\cr
cmr10&511&21020&9440&45\char`\%\cr
cmr10&622&24880&11492&46\char`\%\cr
cmr10&746&29464&13912&47\char`\%\cr
cminch&300&48764&22076&45\char`\%\cr
}}$$
It is hoped that the simplicity and small size of the \.{PK} files will make
them widely accepted.

The \.{PK} format was designed and implemented by Tomas Rokicki during
@^Rokicki, Tomas Gerhard Paul@>
the summer of 1985. This program borrows a few routines from \.{GFtoPXL} by
Arthur Samuel.
@^Samuel, Arthur Lee@>

The |banner| string defined here should be changed whenever \.{GFtoPK}
gets modified. The |preamble_comment| macro (near the end of the program)
should be changed too.

@d banner	"This is GFtoPK, Version 2.4" /*printed when the program starts*/ 

@ Some of the diagnostic information is printed using
|d_print_ln|.  When debugging, it should be set the same as
|print_ln|, defined later.
@^debugging@>

@d d_print_ln(...)	

@ This program is written in standard \PASCAL, except where it is
necessary to use extensions; for example, one extension is to use a
default |case| as in \.{TANGLE}, \.{WEAVE}, etc.  All places where
nonstandard constructions are used should be listed in the index under
``system dependencies.''
@!@^system dependencies@>

@ The binary input comes from |gf_file|, and the output font is written
on |pk_file|.  All text output is written on \PASCAL's standard |output|
file.  The term |print| is used instead of |write| when this program writes
on |output|, so that all such output could easily be redirected if desired.

@d print(...) fprintf(output,__VA_ARGS__)
@d print_ln(X,...) fprintf(output,X"\n",##__VA_ARGS__)

@p@!@!@!
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

@h

#define chr(X) ((unsigned char)(X))
#define get(file) @[fread(&((file).d),sizeof((file).d),1,(file).f)@]
#define read(file,x) @[x=file.d,get(file)@]
#define eof(file) @[(file.f==NULL||feof(file.f))@]
#define set_pos(file,n) @[fseek(file.f,n,SEEK_SET),get(file)@]
#define write(file,...) @[fprintf(file.f,__VA_ARGS__)@]

@<Labels in the outer block@>@;
@<Constants in the outer block@>@;
@<Types in the outer block@>@;
@<Globals in the outer block@>@;
void initialize(void) /*this procedure gets things started properly*/ 
  {@+int i; /*loop index for initializations*/ 
  print_ln(banner);@/
  @<Set initial values@>;@/
  } 

@ If the program has to stop prematurely, it goes to the
`|exit(0)|'.

@<Labels...@>=

@ The following parameters can be changed at compile time to extend or
reduce \.{GFtoPK}'s capacity.  The values given here should be quite
adequate for most uses.  Assuming an average of about three strokes per
raster line, there are six run-counts per line, and therefore |max_row|
will be sufficient for a character 2600 pixels high.

@<Constants...@>=
enum {@+@!line_length=79@+}; /*bracketed lines of output will be at most this long*/ 
enum {@+@!max_row=16000@+}; /*largest index in the main |row| array*/ 

@ Here are some macros for common programming idioms.

@d incr(X)	X=X+1 /*increase a variable by unity*/ 
@d decr(X)	X=X-1 /*decrease a variable by unity*/ 

@ If the \.{GF} file is badly malformed, the whole process must be aborted;
\.{GFtoPK} will give up, after issuing an error message about the symptoms
that were noticed.

Such errors might be discovered inside of subroutines inside of subroutines,
so a procedure called |jump_out| has been introduced. This procedure, which
simply transfers control to the label |exit(0)| at the end of the program,
contains the only non-local |goto| statement in \.{GFtoPK}.
@^system dependencies@>

@d abort(...) {@+print(" "__VA_ARGS__);jump_out();
    } 
@d bad_gf(X,...) abort("Bad GF file: "X"!",##__VA_ARGS__)
@.Bad GF file@>

@p void jump_out(void)
{@+exit(1);
} 

@*The character set.
Like all programs written with the  \.{WEB} system, \.{GFtoPK} can be
used with any character set. But it uses ASCII code internally, because
the programming for portable input-output is easier when a fixed internal
code is used.

The next few sections of \.{GFtoPK} have therefore been copied from the
analogous ones in the \.{WEB} system routines. They have been considerably
simplified, since \.{GFtoPK} need not deal with the controversial
ASCII codes less than 040 or greater than 0176.
If such codes appear in the \.{GF} file,
they will be printed as question marks.

@<Types...@>=
typedef uint8_t ASCII_code; /*a subrange of the integers*/ 

@ The original \PASCAL\ compiler was designed in the late 60s, when six-bit
character sets were common, so it did not make provision for lower case
letters. Nowadays, of course, we need to deal with both upper and lower case
alphabets in a convenient way, especially in a program like \.{GFtoPK}.
So we shall assume that the \PASCAL\ system being used for \.{GFtoPK}
has a character set containing at least the standard visible characters
of ASCII code (|'!'| through |'~'|).

Some \PASCAL\ compilers use the original name |unsigned char| for the data type
associated with the characters in text files, while other \PASCAL s
consider |unsigned char| to be a 64-element subrange of a larger data type that has
some other name.  In order to accommodate this difference, we shall use
the name |text_char| to stand for the data type of the characters in the
output file.  We shall also assume that |text_char| consists of
the elements |chr(first_text_char)| through |chr(last_text_char)|,
inclusive. The following definitions should be adjusted if necessary.
@^system dependencies@>

@d text_char	unsigned char /*the data type of characters in text files*/ 
@d first_text_char	0 /*ordinal number of the smallest element of |text_char|*/ 
@d last_text_char	127 /*ordinal number of the largest element of |text_char|*/ 

@<Types...@>=
typedef struct {@+FILE *f;@+text_char@,d;@+} text_file;

@ The \.{GFtoPK} processor converts between ASCII code and
the user's external character set by means of arrays |xord| and |xchr|
that are analogous to \PASCAL's |ord| and |chr| functions.

@<Globals...@>=
ASCII_code @!xord[256];
   /*specifies conversion of input characters*/ 
uint8_t @!xchr[256];
   /*specifies conversion of output characters*/ 

@ Under our assumption that the visible characters of standard ASCII are
all present, the following assignment statements initialize the
|xchr| array properly, without needing any system-dependent changes.

@<Set init...@>=
for (i=0; i<=037; i++) xchr[i]= '?' ;
xchr[040]= ' ' ;
xchr[041]= '!' ;
xchr[042]= '"' ;
xchr[043]= '#' ;
xchr[044]= '$' ;
xchr[045]= '%' ;
xchr[046]= '&' ;
xchr[047]= '\'' ;@/
xchr[050]= '(' ;
xchr[051]= ')' ;
xchr[052]= '*' ;
xchr[053]= '+' ;
xchr[054]= ',' ;
xchr[055]= '-' ;
xchr[056]= '.' ;
xchr[057]= '/' ;@/
xchr[060]= '0' ;
xchr[061]= '1' ;
xchr[062]= '2' ;
xchr[063]= '3' ;
xchr[064]= '4' ;
xchr[065]= '5' ;
xchr[066]= '6' ;
xchr[067]= '7' ;@/
xchr[070]= '8' ;
xchr[071]= '9' ;
xchr[072]= ':' ;
xchr[073]= ';' ;
xchr[074]= '<' ;
xchr[075]= '=' ;
xchr[076]= '>' ;
xchr[077]= '?' ;@/
xchr[0100]= '@@' ;
xchr[0101]= 'A' ;
xchr[0102]= 'B' ;
xchr[0103]= 'C' ;
xchr[0104]= 'D' ;
xchr[0105]= 'E' ;
xchr[0106]= 'F' ;
xchr[0107]= 'G' ;@/
xchr[0110]= 'H' ;
xchr[0111]= 'I' ;
xchr[0112]= 'J' ;
xchr[0113]= 'K' ;
xchr[0114]= 'L' ;
xchr[0115]= 'M' ;
xchr[0116]= 'N' ;
xchr[0117]= 'O' ;@/
xchr[0120]= 'P' ;
xchr[0121]= 'Q' ;
xchr[0122]= 'R' ;
xchr[0123]= 'S' ;
xchr[0124]= 'T' ;
xchr[0125]= 'U' ;
xchr[0126]= 'V' ;
xchr[0127]= 'W' ;@/
xchr[0130]= 'X' ;
xchr[0131]= 'Y' ;
xchr[0132]= 'Z' ;
xchr[0133]= '[' ;
xchr[0134]= '\\' ;
xchr[0135]= ']' ;
xchr[0136]= '^' ;
xchr[0137]= '_' ;@/
xchr[0140]= '`' ;
xchr[0141]= 'a' ;
xchr[0142]= 'b' ;
xchr[0143]= 'c' ;
xchr[0144]= 'd' ;
xchr[0145]= 'e' ;
xchr[0146]= 'f' ;
xchr[0147]= 'g' ;@/
xchr[0150]= 'h' ;
xchr[0151]= 'i' ;
xchr[0152]= 'j' ;
xchr[0153]= 'k' ;
xchr[0154]= 'l' ;
xchr[0155]= 'm' ;
xchr[0156]= 'n' ;
xchr[0157]= 'o' ;@/
xchr[0160]= 'p' ;
xchr[0161]= 'q' ;
xchr[0162]= 'r' ;
xchr[0163]= 's' ;
xchr[0164]= 't' ;
xchr[0165]= 'u' ;
xchr[0166]= 'v' ;
xchr[0167]= 'w' ;@/
xchr[0170]= 'x' ;
xchr[0171]= 'y' ;
xchr[0172]= 'z' ;
xchr[0173]= '{' ;
xchr[0174]= '|' ;
xchr[0175]= '}' ;
xchr[0176]= '~' ;
for (i=0177; i<=255; i++) xchr[i]= '?' ;

@ The following system-independent code makes the |xord| array contain a
suitable inverse to the information in |xchr|.

@<Set init...@>=
for (i=first_text_char; i<=last_text_char; i++) xord[chr(i)]=040;
for (i=' '; i<='~'; i++) xord[xchr[i]]=i;

@*Generic font file format.
The most important output produced by a typical run of \MF\ is the
``generic font'' (\.{GF}) file that specifies the bit patterns of the
characters that have been drawn. The term {\sl generic\/} indicates that
this file format doesn't match the conventions of any name-brand manufacturer;
but it is easy to convert \.{GF} files to the special format required by
almost all digital phototypesetting equipment. There's a strong analogy
between the \.{DVI} files written by \TeX\ and the \.{GF} files written
by \MF; and, in fact, the file formats have a lot in common.

A \.{GF} file is a stream of 8-bit bytes that may be
regarded as a series of commands in a machine-like language. The first
byte of each command is the operation code, and this code is followed by
zero or more bytes that provide parameters to the command. The parameters
themselves may consist of several consecutive bytes; for example, the
`|boc|' (beginning of character) command has six parameters, each of
which is four bytes long. Parameters are usually regarded as nonnegative
integers; but four-byte-long parameters can be either positive or
negative, hence they range in value from $-2^{31}$ to $2^{31}-1$.
As in \.{TFM} files, numbers that occupy
more than one byte position appear in BigEndian order,
and negative numbers appear in two's complement notation.

A \.{GF} file consists of a ``preamble,'' followed by a sequence of one or
more ``characters,'' followed by a ``postamble.'' The preamble is simply a
|pre| command, with its parameters that introduce the file; this must come
first.  Each ``character'' consists of a |boc| command, followed by any
number of other commands that specify ``black'' pixels,
followed by an |eoc| command. The characters appear in the order that \MF\
generated them. If we ignore no-op commands (which are allowed between any
two commands in the file), each |eoc| command is immediately followed by a
|boc| command, or by a |post| command; in the latter case, there are no
more characters in the file, and the remaining bytes form the postamble.
Further details about the postamble will be explained later.

Some parameters in \.{GF} commands are ``pointers.'' These are four-byte
quantities that give the location number of some other byte in the file;
the first file byte is number~0, then comes number~1, and so on.

@ The \.{GF} format is intended to be both compact and easily interpreted
by a machine. Compactness is achieved by making most of the information
relative instead of absolute. When a \.{GF}-reading program reads the
commands for a character, it keeps track of two quantities: (a)~the current
column number,~|m|; and (b)~the current row number,~|n|.  These are 32-bit
signed integers, although most actual font formats produced from \.{GF}
files will need to curtail this vast range because of practical
limitations. (\MF\ output will never allow $\vert m\vert$ or $\vert
n\vert$ to get extremely large, but the \.{GF} format tries to be more
general.)

How do \.{GF}'s row and column numbers correspond to the conventions
of \TeX\ and \MF? Well, the ``reference point'' of a character, in \TeX's
view, is considered to be at the lower left corner of the pixel in row~0
and column~0. This point is the intersection of the baseline with the left
edge of the type; it corresponds to location $(0,0)$ in \MF\ programs.
Thus the pixel in \.{GF} row~0 and column~0 is \MF's unit square, comprising
the region of the plane whose coordinates both lie between 0 and~1. The
pixel in \.{GF} row~|n| and column~|m| consists of the points whose \MF\
coordinates |(x, y)| satisfy |m <= x <= m+1| and |n <= y <= n+1|.  Negative values of
|m| and~|x| correspond to columns of pixels {\sl left\/} of the reference
point; negative values of |n| and~|y| correspond to rows of pixels {\sl
below\/} the baseline.

Besides |m| and |n|, there's also a third aspect of the current
state, namely the @!|paint_switch|, which is always either \\{black} or
\\{white}. Each \\{paint} command advances |m| by a specified amount~|d|,
and blackens the intervening pixels if |paint_switch==black|; then
the |paint_switch| changes to the opposite state. \.{GF}'s commands are
designed so that |m| will never decrease within a row, and |n| will never
increase within a character; hence there is no way to whiten a pixel that
has been blackened.

@ Here is a list of all the commands that may appear in a \.{GF} file. Each
command is specified by its symbolic name (e.g., |boc|), its opcode byte
(e.g., 67), and its parameters (if any). The parameters are followed
by a bracketed number telling how many bytes they occupy; for example,
`|d[2]|' means that parameter |d| is two bytes long.

\yskip\hang|paint_0| 0. This is a \\{paint} command with |d==0|; it does
nothing but change the |paint_switch| from \\{black} to \\{white} or
vice~versa.

\yskip\hang\\{paint\_1} through \\{paint\_63} (opcodes 1 to 63).
These are \\{paint} commands with |d==1| to~63, defined as follows: If
|paint_switch==black|, blacken |d|~pixels of the current row~|n|,
in columns |m| through |m+d-1| inclusive. Then, in any case,
complement the |paint_switch| and advance |m| by~|d|.

\yskip\hang|paint1| 64 |d[1]|. This is a \\{paint} command with a specified
value of~|d|; \MF\ uses it to paint when |64 <= d < 256|.

\yskip\hang|@!paint2| 65 |d[2]|. Same as |paint1|, but |d|~can be as high
as~65535.

\yskip\hang|@!paint3| 66 |d[3]|. Same as |paint1|, but |d|~can be as high
as $2^{24}-1$. \MF\ never needs this command, and it is hard to imagine
anybody making practical use of it; surely a more compact encoding will be
desirable when characters can be this large. But the command is there,
anyway, just in case.

\yskip\hang|boc| 67 |c[4]| |p[4]| |min_m[4]| |max_m[4]| |min_n[4]|
|max_n[4]|. Beginning of a character:  Here |c| is the character code, and
|p| points to the previous character beginning (if any) for characters having
this code number modulo 256.  (The pointer |p| is |-1| if there was no
prior character with an equivalent code.) The values of registers |m| and |n|
defined by the instructions that follow for this character must
satisfy |min_m <= m <= max_m| and |min_n <= n <= max_n|.  (The values of |max_m| and
|min_n| need not be the tightest bounds possible.)  When a \.{GF}-reading
program sees a |boc|, it can use |min_m|, |max_m|, |min_n|, and |max_n| to
initialize the bounds of an array. Then it sets |m=min_m|, |n=max_n|, and
|paint_switch=white|.

\yskip\hang|boc1| 68 |c[1]| |@!del_m[1]| |max_m[1]| |@!del_n[1]| |max_n[1]|.
Same as |boc|, but |p| is assumed to be~$-1$; also |del_m==max_m-min_m|
and |del_n==max_n-min_n| are given instead of |min_m| and |min_n|.
The one-byte parameters must be between 0 and 255, inclusive.
\ (This abbreviated |boc| saves 19~bytes per character, in common cases.)

\yskip\hang|eoc| 69. End of character: All pixels blackened so far
constitute the pattern for this character. In particular, a completely
blank character might have |eoc| immediately following |boc|.

\yskip\hang|skip0| 70. Decrease |n| by 1 and set |m=min_m|,
|paint_switch=white|. \ (This finishes one row and begins another,
ready to whiten the leftmost pixel in the new row.)

\yskip\hang|skip1| 71 |d[1]|. Decrease |n| by |d+1|, set |m=min_m|, and set
|paint_switch=white|. This is a way to produce |d| all-white rows.

\yskip\hang|@!skip2| 72 |d[2]|. Same as |skip1|, but |d| can be as large
as 65535.

\yskip\hang|@!skip3| 73 |d[3]|. Same as |skip1|, but |d| can be as large
as $2^{24}-1$. \MF\ obviously never needs this command.

\yskip\hang|new_row_0| 74. Decrease |n| by 1 and set |m=min_m|,
|paint_switch=black|. \ (This finishes one row and begins another,
ready to {\sl blacken\/} the leftmost pixel in the new row.)

\yskip\hang|@!new_row_1| through |@!new_row_164| (opcodes 75 to 238). Same as
|new_row_0|, but with |m=min_m+1| through |min_m+164|, respectively.

\yskip\hang|xxx1| 239 |k[1]| |x[k]|. This command is undefined in
general; it functions as a $(k+2)$-byte |no_op| unless special \.{GF}-reading
programs are being used. \MF\ generates \\{xxx} commands when encountering
a \&{special} string; this occurs in the \.{GF} file only between
characters, after the preamble, and before the postamble. However,
\\{xxx} commands might appear within characters,
in \.{GF} files generated by other
processors. It is recommended that |x| be a string having the form of a
keyword followed by possible parameters relevant to that keyword.

\yskip\hang|@!xxx2| 240 |k[2]| |x[k]|. Like |xxx1|, but |0 <= k < 65536|.

\yskip\hang|xxx3| 241 |k[3]| |x[k]|. Like |xxx1|, but |0 <= k < @t$2^{24}$@>|.
\MF\ uses this when sending a \&{special} string whose length exceeds~255.

\yskip\hang|@!xxx4| 242 |k[4]| |x[k]|. Like |xxx1|, but |k| can be
ridiculously large; |k| mustn't be negative.

\yskip\hang|yyy| 243 |y[4]|. This command is undefined in general;
it functions as a 5-byte |no_op| unless special \.{GF}-reading programs
are being used. \MF\ puts |scaled| numbers into |yyy|'s, as a
result of \&{numspecial} commands; the intent is to provide numeric
parameters to \\{xxx} commands that immediately precede.

\yskip\hang|no_op| 244. No operation, do nothing. Any number of |no_op|'s
may occur between \.{GF} commands, but a |no_op| cannot be inserted between
a command and its parameters or between two parameters.

\yskip\hang|char_loc| 245 |c[1]| |dx[4]| |dy[4]| |w[4]| |p[4]|.
This command will appear only in the postamble, which will be explained
shortly.

\yskip\hang|@!char_loc0| 246 |c[1]| |@!dm[1]| |w[4]| |p[4]|.
Same as |char_loc|, except that |dy| is assumed to be zero, and the value
of~|dx| is taken to be |65536*dm|, where |0 <= dm < 256|.

\yskip\hang|pre| 247 |i[1]| |k[1]| |x[k]|.
Beginning of the preamble; this must come at the very beginning of the
file. Parameter |i| is an identifying number for \.{GF} format, currently
131. The other information is merely commentary; it is not given
special interpretation like \\{xxx} commands are. (Note that \\{xxx}
commands may immediately follow the preamble, before the first |boc|.)

\yskip\hang|post| 248. Beginning of the postamble, see below.

\yskip\hang|post_post| 249. Ending of the postamble, see below.

\yskip\noindent Commands 250--255 are undefined at the present time.

@d gf_id_byte	131 /*identifies the kind of \.{GF} files described here*/ 

@ Here are the opcodes that \.{GFtoPK} actually refers to.

@d paint_0	0 /*beginning of the \\{paint} commands*/ 
@d paint1	64 /*move right a given number of columns, then
  black${}\swap{}$white*/ 
@d boc	67 /*beginning of a character*/ 
@d boc1	68 /*abbreviated |boc|*/ 
@d eoc	69 /*end of a character*/ 
@d skip0	70 /*skip no blank rows*/ 
@d skip1	71 /*skip over blank rows*/ 
@d new_row_0	74 /*move down one row and then right*/ 
@d max_new_row	238 /*move down one row and then right*/ 
@d xxx1	239 /*for \&{special} strings*/ 
@d yyy	243 /*for \&{numspecial} numbers*/ 
@d no_op	244 /*no operation*/ 
@d char_loc	245 /*character locators in the postamble*/ 
@d char_loc0	246 /*character locators in the postamble*/ 
@d pre	247 /*preamble*/ 
@d post	248 /*postamble beginning*/ 
@d post_post	249 /*postamble ending*/ 
@d undefined_commands	250, 251, 252, 253, 254, 255

@ The last character in a \.{GF} file is followed by `|post|'; this command
introduces the postamble, which summarizes important facts that \MF\ has
accumulated. The postamble has the form
$$\vbox{\halign{\hbox{#\hfil}\cr
  |post| |p[4]| |@!ds[4]| |@!cs[4]| |@!hppp[4]| |@!vppp[4]|
   |@!min_m[4]| |@!max_m[4]| |@!min_n[4]| |@!max_n[4]|\cr
  $\langle\,$character locators$\,\rangle$\cr
  |post_post| |q[4]| |i[1]| 223's$[{\G}4]$\cr}}$$
Here |p| is a pointer to the byte following the final |eoc| in the file
(or to the byte following the preamble, if there are no characters);
it can be used to locate the beginning of \\{xxx} commands
that might have preceded the postamble. The |ds| and |cs| parameters
@^design size@> @^check sum@>
give the design size and check sum, respectively, which are exactly the
values put into the header of any \.{TFM} file that shares information with
this \.{GF} file. Parameters |hppp| and |vppp| are the ratios of
pixels per point, horizontally and vertically, expressed as |scaled| integers
(i.e., multiplied by $2^{16}$); they can be used to correlate the font
with specific device resolutions, magnifications, and ``at sizes.''  Then
come |min_m|, |max_m|, |min_n|, and |max_n|, which bound the values that
registers |m| and~|n| assume in all characters in this \.{GF} file.
(These bounds need not be the best possible; |max_m| and |min_n| may, on the
other hand, be tighter than the similar bounds in |boc| commands. For
example, some character may have |min_n==-100| in its |boc|, but it might
turn out that |n| never gets lower than |-50| in any character; then
|min_n| can have any value | <= -50|. If there are no characters in the file,
it's possible to have |min_m > max_m| and/or |min_n > max_n|.)

@ Character locators are introduced by |char_loc| commands,
which specify a character residue~|c|, character escapements (|dx, dy|),
a character width~|w|, and a pointer~|p|
to the beginning of that character. (If two or more characters have the
same code~|c| modulo 256, only the last will be indicated; the others can be
located by following backpointers. Characters whose codes differ by a
multiple of 256 are assumed to share the same font metric information,
hence the \.{TFM} file contains only residues of character codes modulo~256.
This convention is intended for oriental languages, when there are many
character shapes but few distinct widths.)
@^oriental characters@>@^Chinese characters@>@^Japanese characters@>

The character escapements (|dx, dy|) are the values of \MF's \&{chardx}
and \&{chardy} parameters; they are in units of |scaled| pixels;
i.e., |dx| is in horizontal pixel units times $2^{16}$, and |dy| is in
vertical pixel units times $2^{16}$.  This is the intended amount of
displacement after typesetting the character; for \.{DVI} files, |dy|
should be zero, but other document file formats allow nonzero vertical
escapement.

The character width~|w| duplicates the information in the \.{TFM} file; it
is $2^{24}$ times the ratio of the true width to the font's design size.

The backpointer |p| points to the character's |boc|, or to the first of
a sequence of consecutive \\{xxx} or |yyy| or |no_op| commands that
immediately precede the |boc|, if such commands exist; such ``special''
commands essentially belong to the characters, while the special commands
after the final character belong to the postamble (i.e., to the font
as a whole). This convention about |p| applies also to the backpointers
in |boc| commands, even though it wasn't explained in the description
of~|boc|. @^backpointers@>

Pointer |p| might be |-1| if the character exists in the \.{TFM} file
but not in the \.{GF} file. This unusual situation can arise in \MF\ output
if the user had |proofing < 0| when the character was being shipped out,
but then made |proofing >= 0| in order to get a \.{GF} file.

@ The last part of the postamble, following the |post_post| byte that
signifies the end of the character locators, contains |q|, a pointer to the
|post| command that started the postamble.  An identification byte, |i|,
comes next; this currently equals~131, as in the preamble.

The |i| byte is followed by four or more bytes that are all equal to
the decimal number 223 (i.e., 0337 in octal). \MF\ puts out four to seven of
these trailing bytes, until the total length of the file is a multiple of
four bytes, since this works out best on machines that pack four bytes per
word; but any number of 223's is allowed, as long as there are at least four
of them. In effect, 223 is a sort of signature that is added at the very end.
@^Fuchs, David Raymond@>

This curious way to finish off a \.{GF} file makes it feasible for
\.{GF}-reading programs to find the postamble first, on most computers,
even though \MF\ wants to write the postamble last. Most operating
systems permit random access to individual words or bytes of a file, so
the \.{GF} reader can start at the end and skip backwards over the 223's
until finding the identification byte. Then it can back up four bytes, read
|q|, and move to byte |q| of the file. This byte should, of course,
contain the value 248 (|post|); now the postamble can be read, so the
\.{GF} reader can discover all the information needed for individual
characters.

Unfortunately, however, standard \PASCAL\ does not include the ability to
@^system dependencies@>
access a random position in a file, or even to determine the length of a file.
Almost all systems nowadays provide the necessary capabilities, so \.{GF}
format has been designed to work most efficiently with modern operating
systems.  \.{GFtoPK} first reads the postamble, and then scans the file from
front to back.

@*Packed file format.
The packed file format is a compact representation of the data contained in a
\.{GF} file.  The information content is the same, but packed (\.{PK}) files
are almost always less than half the size of their \.{GF} counterparts.  They
are also easier to convert into a raster representation because they do not
have a profusion of \\{paint}, \\{skip}, and \\{new\_row} commands to be
separately interpreted.  In addition, the \.{PK} format expressly forbids
\&{special} commands within a character.  The minimum bounding box for each
character is explicit in the format, and does not need to be scanned for as in
the \.{GF} format.  Finally, the width and escapement values are combined with
the raster information into character ``packets'', making it simpler in many
cases to process a character.

A \.{PK} file is organized as a stream of 8-bit bytes.  At times, these bytes
might be split into 4-bit nybbles or single bits, or combined into multiple
byte parameters.  When bytes are split into smaller pieces, the `first' piece
is always the most significant of the byte.  For instance, the first bit of
a byte is the bit with value 128; the first nybble can be found by dividing
a byte by 16.  Similarly, when bytes are combined into multiple byte
parameters, the first byte is the most significant of the parameter.  If the
parameter is signed, it is represented by two's-complement notation.

The set of possible eight-bit values is separated into two sets, those that
introduce a character definition, and those that do not.  The values that
introduce a character definition range from 0 to 239; byte values
above 239 are interpreted as commands.  Bytes that introduce character
definitions are called flag bytes, and various fields within the byte indicate
various things about how the character definition is encoded.  Command bytes
have zero or more parameters, and can never appear within a character
definition or between parameters of another command, where they would be
interpreted as data.

A \.{PK} file consists of a preamble, followed by a sequence of one or more
character definitions, followed by a postamble.  The preamble command must
be the first byte in the file, followed immediately by its parameters.
Any number of character definitions may follow, and any command but the
preamble command and the postamble command may occur between character
definitions.  The very last command in the file must be the postamble.

@ The packed file format is intended to be easy to read and interpret by
device drivers.  The small size of the file reduces the input/output overhead
each time a font is loaded.  For those drivers that load and save each font
file into memory, the small size also helps reduce the memory requirements.
The length of each character packet is specified, allowing the character raster
data to be loaded into memory by simply counting bytes, rather than
interpreting each command; then, each character can be interpreted on a demand
basis.  This also makes it possible for a driver to skip a particular
character quickly if it knows that the character is unused.

@ First, the command bytes will be presented; then the format of the
character definitions will be defined.  Eight of the possible sixteen
commands (values 240 through 255) are currently defined; the others are
reserved for future extensions.  The commands are listed below.  Each command
is specified by its symbolic name (e.g., \\{pk\_no\_op}), its opcode byte,
and any parameters.  The parameters are followed by a bracketed number
telling how many bytes they occupy, with the number preceded by a plus sign if
it is a signed quantity.  (Four byte quantities are always signed, however.)

\yskip\hang|pk_xxx1| 240 |k[1]| |x[k]|.  This command is undefined in general;
it functions as a $(k+2)$-byte \\{no\_op} unless special \.{PK}-reading
programs are being used.  \MF\ generates \\{xxx} commands when encountering
a \&{special} string.  It is recommended that |x| be a string having the form
of a keyword followed by possible parameters relevant to that keyword.

\yskip\hang\\{pk\_xxx2} 241 |k[2]| |x[k]|.  Like |pk_xxx1|, but |0 <= k < 65536|.

\yskip\hang\\{pk\_xxx3} 242 |k[3]| |x[k]|.  Like |pk_xxx1|, but
|0 <= k < @t$2^{24}$@>|.  \MF\ uses this when sending a \&{special} string whose
length exceeds~255.

\yskip\hang\\{pk\_xxx4} 243 |k[4]| |x[k]|.  Like |pk_xxx1|, but |k| can be
ridiculously large; |k| mustn't be negative.

\yskip\hang|pk_yyy| 244 |y[4]|.  This command is undefined in general; it
functions as a five-byte \\{no\_op} unless special \.{PK} reading programs
are being used.  \MF\ puts |scaled| numbers into |yyy|'s, as a result of
\&{numspecial} commands; the intent is to provide numeric parameters to
\\{xxx} commands that immediately precede.

\yskip\hang|pk_post| 245.  Beginning of the postamble.  This command is
followed by enough |pk_no_op| commands to make the file a multiple
of four bytes long.  Zero through three bytes are usual, but any number
is allowed.
This should make the file easy to read on machines that pack four bytes to
a word.

\yskip\hang|pk_no_op| 246.  No operation, do nothing.  Any number of
|pk_no_op|'s may appear between \.{PK} commands, but a |pk_no_op| cannot be
inserted between a command and its parameters, between two parameters, or
inside a character definition.

\yskip\hang|pk_pre| 247 |i[1]| |k[1]| |x[k]| |ds[4]| |cs[4]| |hppp[4]|
|vppp[4]|.  Preamble command.  Here, |i| is the identification byte of the
file, currently equal to 89.  The string |x| is merely a comment, usually
indicating the source of the \.{PK} file.  The parameters |ds| and |cs| are
the design size of the file in $1/2^{20}$ points, and the checksum of the
file, respectively.  The checksum should match the \.{TFM} file and the
\.{GF} files for this font.  Parameters |hppp| and |vppp| are the ratios
of pixels per point, horizontally and vertically, multiplied by $2^{16}$; they
can be used to correlate the font with specific device resolutions,
magnifications, and ``at sizes''.  Usually, the name of the \.{PK} file is
formed by concatenating the font name (e.g., cmr10) with the resolution at
which the font is prepared in pixels per inch multiplied by the magnification
factor, and the letters \.{pk}.  For instance, cmr10 at 300 dots per inch
should be named \.{cmr10.300pk}; at one thousand dots per inch and magstephalf,
it should be named \.{cmr10.1095pk}.

@ We put a few of the above opcodes into definitions for symbolic use by
this program.

@d pk_id	89 /*the version of \.{PK} file described*/ 
@d pk_xxx1	240 /*\&{special} commands*/ 
@d pk_yyy	244 /*\&{numspecial} commands*/ 
@d pk_post	245 /*postamble*/ 
@d pk_no_op	246 /*no operation*/ 
@d pk_pre	247 /*preamble*/ 

@ The \.{PK} format has two conflicting goals: to pack character raster and
size information as compactly as possible, while retaining ease of translation
into raster and other forms.  A suitable compromise was found in the use of
run-encoding of the raster information.  Instead of packing the individual
bits of the character, we instead count the number of consecutive `black' or
`white' pixels in a horizontal raster row, and then encode this number.  Run
counts are found for each row from left to right, traversing rows from the
top to bottom. This is essentially the way the \.{GF} format works.
Instead of presenting each row individually, however, we concatenate all
of the horizontal raster rows into one long string of pixels, and encode this
row.  With knowledge of the width of the bit-map, the original character glyph
can easily be reconstructed.  In addition, we do not need special commands to
mark the end of one row and the beginning of the next.

Next, we place the burden of finding the minimum bounding box on the part
of the font generator, since the characters will usually be used much more
often than they are generated.  The minimum bounding box is the smallest
rectangle that encloses all `black' pixels of a character.  We also
eliminate the need for a special end of character marker, by supplying
exactly as many bits as are required to fill the minimum bounding box, from
which the end of the character is implicit.

Let us next consider the distribution of the run counts.  Analysis of several
dozen pixel files at 300 dots per inch yields a distribution peaking at four,
falling off slowly until ten, then a bit more steeply until twenty, and then
asymptotically approaching the horizontal.  Thus, the great majority of our
run counts will fit in a four-bit nybble.  The eight-bit byte is attractive for
our run-counts, as it is the standard on many systems; however, the wasted four
bits in the majority of cases seem a high price to pay.  Another possibility
is to use a Huffman-type encoding scheme with a variable number of bits for
each run-count; this was rejected because of the overhead in fetching and
examining individual bits in the file.  Thus, the character raster definitions
in the \.{PK} file format are based on the four-bit nybble.

@ An analysis of typical pixel files yielded another interesting statistic:
Fully 37\char`\%\
of the raster rows were duplicates of the previous row.  Thus, the \.{PK}
format allows the specification of repeat counts, which indicate how many times
a horizontal raster row is to be repeated.  These repeated rows are taken out
of the character glyph before individual rows are concatenated into the long
string of pixels.

For elegance, we disallow a run count of zero.  The case of a null raster
description should be gleaned from the character width and height being equal
to zero, and no raster data should be read.  No other zero counts are ever
necessary.  Also, in the absence of repeat counts, the repeat value is set to
be zero (only the original row is sent.)  If a repeat count is seen, it takes
effect on the current row.  The current row is defined as the row on which the
first pixel of the next run count will lie.  The repeat count is set back to
zero when the last pixel in the current row is seen, and the row is sent out.

This poses a problem for entirely black and entirely white rows, however.  Let
us say that the current row ends with four white pixels, and then we have five
entirely empty rows, followed by a black pixel at the beginning of the next
row, and the character width is ten pixels.  We would like to use a repeat
count, but there is no legal place to put it.  If we put it before the white
run count, it will apply to the current row.  If we put it after, it applies
to the row with the black pixel at the beginning.  Thus, entirely white or
entirely black repeated rows are always packed as large run counts (in this
case, a white run count of 54) rather than repeat counts.

@ Now we turn our attention to the actual packing of the run counts and
repeat counts into nybbles.  There are only sixteen possible nybble values.
We need to indicate run counts and repeat counts.  Since the run counts are
much more common, we will devote the majority of the nybble values to them.
We therefore indicate a repeat count by a nybble of 14 followed by a packed
number, where a packed number will be explained later.  Since the repeat
count value of one is so common, we indicate a repeat one command by a single
nybble of 15.  A 14 followed by the packed number 1 is still legal for a
repeat one count.  The run counts are coded directly as packed
numbers.

For packed numbers, therefore, we have the nybble values 0 through 13.  We
need to represent the positive integers up to, say, $2^{31}-1$.  We would
like the more common smaller numbers to take only one or two nybbles, and
the infrequent large numbers to take three or more.  We could therefore
allocate one nybble value to indicate a large run count taking three or more
nybbles.  We do this with the value 0.

@ We are left with the values 1 through 13.  We can allocate some of these, say
|dyn_f|, to be one-nybble run counts.
These will work for the run counts |1 dotdot dyn_f|.  For subsequent run
counts, we will use a nybble greater than |dyn_f|, followed by a second nybble,
whose value can run from 0 through 15.  Thus, the two-nybble values will
run from |dyn_f+1 dotdot(13-dyn_f)*16+dyn_f|.  We have our definition of large run
count values now, being all counts greater than |(13-dyn_f)*16+dyn_f|.

We can analyze our several dozen pixel files and determine an optimal value of
|dyn_f|, and use this value for all of the characters.  Unfortunately, values
of |dyn_f| that pack small characters well tend to pack the large characters
poorly, and values that pack large characters well are not efficient for the
smaller characters.  Thus, we choose the optimal |dyn_f| on a character basis,
picking the value that will pack each individual character in the smallest
number of nybbles.  Legal values of |dyn_f| run from 0 (with no one-nybble run
counts) to 13 (with no two-nybble run counts).

@ Our only remaining task in the coding of packed numbers is the large run
counts.  We use a scheme suggested by D.~E.~Knuth
@^Knuth, Donald Ervin@>
that simply and elegantly represents arbitrarily large values.  The
general scheme to represent an integer |i| is to write its hexadecimal
representation, with leading zeros removed.  Then we count the number of
digits, and prepend one less than that many zeros before the hexadecimal
representation.  Thus, the values from one to fifteen occupy one nybble;
the values sixteen through 255 occupy three, the values 256 through 4095
require five, etc.

For our purposes, however, we have already represented the numbers one
through |(13-dyn_f)*16+dyn_f|.  In addition, the one-nybble values have
already been taken by our other commands, which means that only the values
from sixteen up are available to us for long run counts.  Thus, we simply
normalize our long run counts, by subtracting |(13-dyn_f)*16+dyn_f+1| and
adding 16, and then we represent the result according to the scheme above.

@ The final algorithm for decoding the run counts based on the above scheme
might look like this, assuming that a procedure called \\{get\_nyb} is
available to get the next nybble from the file, and assuming that the global
|repeat_count| indicates whether a row needs to be repeated.  Note that this
routine is recursive, but since a repeat count can never directly follow
another repeat count, it can only be recursive to one level.

@p
#if 0
int pk_packed_num(void)
{@+int i, @!j;

   i=get_nyb;
   if (i==0) {@+
      @/do@+{j=get_nyb;incr(i);}@+ while (!(j!=0));
      while (i > 0) {@+j=j*16+get_nyb;decr(i);} 
      return j-15+(13-dyn_f)*16+dyn_f;
   } else if (i <= dyn_f) 
      return i;
   else if (i < 14) 
      return(i-dyn_f-1)*16+get_nyb+dyn_f+1;
   else{@+
      if (i==14) 
         repeat_count=pk_packed_num();
      else
         repeat_count=1;
      return pk_packed_num();
   } 
} 
#endif


@ For low resolution fonts, or characters with `gray' areas, run encoding can
often make the character many times larger.  Therefore, for those characters
that cannot be encoded efficiently with run counts, the \.{PK} format allows
bit-mapping of the characters.  This is indicated by a |dyn_f| value of
14.  The bits are packed tightly, by concatenating all of the horizontal raster
rows into one long string, and then packing this string eight bits to a byte.
The number of bytes required can be calculated by |(width*height+7)/8|.
This format should only be used when packing the character by run counts takes
more bytes than this, although, of course, it is legal for any character.
Any extra bits in the last byte should be set to zero.

@ At this point, we are ready to introduce the format for a character
descriptor.  It consists of three parts: a flag byte, a character preamble,
and the raster data.  The most significant four bits of the flag byte
yield the |dyn_f| value for that character.  (Notice that only values of
0 through 14 are legal for |dyn_f|, with 14 indicating a bit mapped character;
thus, the flag bytes do not conflict with the command bytes, whose upper nybble
is always 15.)  The next bit (with weight 8) indicates whether the first run
count is a black count or a white count, with a one indicating a black count.
For bit-mapped characters, this bit should be set to a zero.  The next bit
(with weight 4) indicates whether certain later parameters (referred to as size
parameters) are given in one-byte or two-byte quantities, with a one indicating
that they are in two-byte quantities.  The last two bits are concatenated on to
the beginning of the packet-length parameter in the character preamble,
which will be explained below.

However, if the last three bits of the flag byte are all set (normally
indicating that the size parameters are two-byte values and that a 3 should be
prepended to the length parameter), then a long format of the character
preamble should be used instead of one of the short forms.

Therefore, there are three formats for the character preamble; the one that
is used depends on the least significant three bits of the flag byte.  If the
least significant three bits are in the range zero through three, the short
format is used.  If they are in the range four through six, the extended short
format is used.  Otherwise, if the least significant bits are all set, then
the long form of the character preamble is used.  The preamble formats are
explained below.

\yskip\hang Short form: |flag[1]| |pl[1]| |cc[1]| |tfm[3]| |dm[1]| |w[1]|
|h[1]| |hoff[+1]| |voff[+1]|.
If this format of the character preamble is used, the above
parameters must all fit in the indicated number of bytes, signed or unsigned
as indicated.  Almost all of the standard \TeX\ font characters fit; the few
exceptions are fonts such as \.{cminch}.

\yskip\hang Extended short form: |flag[1]| |pl[2]| |cc[1]| |tfm[3]| |dm[2]|
|w[2]| |h[2]| |hoff[+2]| |voff[+2]|.  Larger characters use this extended
format.

\yskip\hang Long form: |flag[1]| |pl[4]| |cc[4]| |tfm[4]| |dx[4]| |dy[4]|
|w[4]| |h[4]| |hoff[4]| |voff[4]|.  This is the general format that
allows all of the
parameters of the \.{GF} file format, including vertical escapement.
\vskip\baselineskip
The |flag| parameter is the flag byte.  The parameter |pl| (packet length)
contains the offset
of the byte following this character descriptor, with respect to the beginning
of the |tfm| width parameter.  This is given so a \.{PK} reading program can,
once it has read the flag byte, packet length, and character code (|cc|), skip
over the character by simply reading this many more bytes.  For the two short
forms of the character preamble, the last two bits of the flag byte should be
considered the two most-significant bits of the packet length.  For the short
format, the true packet length might be calculated as |(flag%4)*256+pl|;
for the short extended format, it might be calculated as
|(flag%4)*65536+pl|.

The |w| parameter is the width and the |h| parameter is the height in pixels
of the minimum bounding box.  The |dx| and |dy| parameters are the horizontal
and vertical escapements, respectively.  In the short formats, |dy| is assumed
to be zero and |dm| is |dx| but in pixels;
in the long format, |dx| and |dy| are both
in pixels multiplied by $2^{16}$.  The |hoff| is the horizontal offset from the
upper left pixel to the reference pixel; the |voff| is the vertical offset.
They are both given in pixels, with right and down being positive.  The
reference pixel is the pixel that occupies the unit square in \MF; the
\MF\ reference point is the lower left hand corner of this pixel.  (See the
example below.)

@ \TeX\ requires all characters that have the same character codes
modulo 256 to have also the same |tfm| widths and escapement values.  The \.{PK}
format does not itself make this a requirement, but in order for the font to
work correctly with the \TeX\ software, this constraint should be observed.
(The standard version of \TeX\ cannot output character codes greater
than 255, but extended versions do exist.)

Following the character preamble is the raster information for the
character, packed by run counts or by bits, as indicated by the flag byte.
If the character is packed by run counts and the required number of nybbles
is odd, then the last byte of the raster description should have a zero
for its least significant nybble.

@ As an illustration of the \.{PK} format, the character \char4\ from the font
amr10 at 300 dots per inch will be encoded.  This character was chosen
because it illustrates some
of the borderline cases.  The raster for the character looks like this (the
row numbers are chosen for convenience, and are not \MF's row numbers.)

\vskip\baselineskip
{\def\smbox{\vrule height 7pt width 7pt depth 0pt \hskip 3pt}%
\catcode`\*=\active \let*=\smbox
\centerline{\vbox{\baselineskip=10pt
\halign{\hfil#\quad&&\hfil#\hfil\cr
0& & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
1& & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
2& & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
3& & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
4& & &*&*& & & & & & & & & & & & & & & & &*&*\cr
5& & &*&*& & & & & & & & & & & & & & & & &*&*\cr
6& & &*&*& & & & & & & & & & & & & & & & &*&*\cr
7\cr
8\cr
9& & & & &*&*& & & & & & & & & & & & &*&*& & \cr
10& & & & &*&*& & & & & & & & & & & & &*&*& & \cr
11& & & & &*&*& & & & & & & & & & & & &*&*& & \cr
12& & & & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*& & \cr
13& & & & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*& & \cr
14& & & & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*& & \cr
15& & & & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*& & \cr
16& & & & &*&*& & & & & & & & & & & & &*&*& & \cr
17& & & & &*&*& & & & & & & & & & & & &*&*& & \cr
18& & & & &*&*& & & & & & & & & & & & &*&*& & \cr
19\cr
20\cr
21\cr
22& & &*&*& & & & & & & & & & & & & & & & &*&*\cr
23& & &*&*& & & & & & & & & & & & & & & & &*&*\cr
24& & &*&*& & & & & & & & & & & & & & & & &*&*\cr
25& & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
26& & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
27& & &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
28&+& &*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*\cr
&\hphantom{*}&\hphantom{*}\cr
}}}}
The width of the minimum bounding box for this character is 20; its height
is 29.  The `+' represents the reference pixel; notice how it lies outside the
minimum bounding box.  The |hoff| value is $-2$, and the |voff| is~28.

The first task is to calculate the run counts and repeat counts.  The repeat
counts are placed at the first transition (black to white or white to black)
in a row, and are enclosed in brackets.  White counts are enclosed in
parentheses.  It is relatively easy to generate the counts list:
\vskip\baselineskip
\centerline{82 [2] (16) 2 (42) [2] 2 (12) 2 (4) [3]}
\centerline{16 (4) [2] 2 (12) 2 (62) [2] 2 (16) 82}
\vskip\baselineskip
Note that any duplicated rows that are not all white or all black are removed
before the run counts are calculated.  The rows thus removed are rows 5, 6,
10, 11, 13, 14, 15, 17, 18, 23, and 24.

@ The next step in the encoding of this character is to calculate the optimal
value of |dyn_f|.  The details of how this calculation is done are not
important here; suffice it to say that there is a simple algorithm that can
determine the best value of |dyn_f| in one pass over the count list.  For this
character, the optimal value turns out to be 8 (atypically low).  Thus, all
count values less than or equal to 8 are packed in one nybble; those from
nine to $(13-8)*16+8$ or 88 are packed in two nybbles.  The run encoded values
now become (in hex, separated according to the above list):
\vskip\baselineskip
\centerline{\tt D9 E2 97 2 B1 E2 2 93 2 4 E3}
\centerline{\tt 97 4 E2 2 93 2 C5 E2 2 97 D9}
\vskip\baselineskip\noindent
which comes to 36 nybbles, or 18 bytes.  This is shorter than the 73 bytes
required for the bit map, so we use the run count packing.

@ The short form of the character preamble is used because all of the
parameters fit in their respective lengths.  The packet length is therefore
18 bytes for the raster, plus
eight bytes for the character preamble parameters following the character
code, or 26.  The |tfm| width for this character is 640796, or {\tt 9C71C} in
hexadecimal.  The horizontal escapement is 25 pixels.  The flag byte is
88 hex, indicating the short preamble, the black first count, and the
|dyn_f| value of 8.  The final total character packet, in hexadecimal, is:
\vskip\baselineskip
$$\vbox{\halign{\hfil #\quad&&{\tt #\ }\cr
Flag byte&88\cr
Packet length&1A\cr
Character code&04\cr
|tfm| width&09&C7&1C\cr
Horizontal escapement (pixels)&19\cr
Width of bit map&14\cr
Height of bit map&1D\cr
Horizontal offset (signed)&FE\cr
Vertical offset&1C\cr
Raster data&D9&E2&97\cr
&2B&1E&22\cr
&93&24&E3\cr
&97&4E&22\cr
&93&2C&5E\cr
&22&97&D9\cr}}$$

@*Input and output for binary files.
We have seen that a \.{GF} file is a sequence of 8-bit bytes. The bytes
appear physically in what is called a `|File 0 dotdot 255|'
in \PASCAL\ lingo.  The \.{PK} file is also a sequence of 8-bit bytes.

Packing is system dependent, and many \PASCAL\ systems fail to implement
such files in a sensible way (at least, from the viewpoint of producing
good production software).  For example, some systems treat all
byte-oriented files as text, looking for end-of-line marks and such
things. Therefore some system-dependent code is often needed to deal with
binary files, even though most of the program in this section of
\.{GFtoPK} is written in standard \PASCAL.
@^system dependencies@>

We shall stick to simple \PASCAL\ in this program, for reasons of clarity,
even if such simplicity is sometimes unrealistic.

@<Types...@>=
typedef uint8_t eight_bits; /*unsigned one-byte quantity*/ 
typedef struct {@+FILE *f;@+eight_bits@,d;@+} byte_file; /*files that contain binary data*/ 

@ The program deals with two binary file variables: |gf_file| is the
input file that we are translating into \.{PK} format, to be written
on |pk_file|.

@<Glob...@>=
byte_file @!gf_file; /*the stuff we are \.{GFtoPK}ing*/ 
byte_file @!pk_file; /*the stuff we have \.{GFtoPK}ed*/ 
FILE *output;

@ To prepare the |gf_file| for input, we |reset| it.

@p void open_gf_file(void) /*prepares to read packed bytes in |gf_file|*/ 
{@+get(gf_file);
gf_loc=0;
} 

@ To prepare the |pk_file| for output, we |rewrite| it.

@p void open_pk_file(void) /*prepares to write packed bytes in |pk_file|*/ 
{
pk_loc=0;pk_open=true;
} 

@ The variable |pk_loc| contains the number of the byte about to
be written to the |pk_file|, and |gf_loc| is the byte about to be read
from the |gf_file|.  Also, |pk_open| indicates that the packed file has
been opened and is ready for output.

@<Glob...@>=
int @!pk_loc; /*where we are about to write, in |pk_file|*/ 
int @!gf_loc; /*where are we in the |gf_file|*/ 
bool @!pk_open; /*is the packed file open?*/ 

@ We do not open the |pk_file| until after the postamble of the |gf_file|
has been read.  This can be used, for instance, to calculate a resolution
to put in the suffix of the |pk_file| name.  This also means, however, that
specials in the postamble (which \MF\ never generates) do not get sent to
the |pk_file|.

@<Set init...@>=
pk_open=false;

@ We shall use two simple functions to read the next byte or
bytes from |gf_file|.  We either need to get an individual byte or a
set of four bytes.
@^system dependencies@>

@p int gf_byte(void) /*returns the next byte, unsigned*/ 
{@+eight_bits b;
if (eof(gf_file)) bad_gf("Unexpected end of file!")@;
@.Unexpected end of file@>
else{@+read(gf_file, b);
  } 
incr(gf_loc);
return b;
} 
@#
int gf_signed_quad(void) /*returns the next four bytes, signed*/ 
{@+eight_bits a, @!b, @!c, @!d;
int signed_quad;
read(gf_file, a);read(gf_file, b);read(gf_file, c);read(gf_file, d);
if (a < 128) signed_quad=((a*256+b)*256+c)*256+d;
else signed_quad=(((a-256)*256+b)*256+c)*256+d;
gf_loc=gf_loc+4;
return signed_quad;
} 

@ We also need a few routines to write data to the \.{PK} file.  We write
data in 4-, 8-, 16-, 24-, and 32-bit chunks, so we define the appropriate
routines. We must be careful not to let the sign bit mess us up, as some
\PASCAL s implement division of a negative integer differently.

@p void pk_byte(int a)
{@+
   if (pk_open) {@+
      if (a < 0) a=a+256;
      write(pk_file, "%c", a);
      incr(pk_loc);
   } 
} 
@#
void pk_halfword(int a)
{@+
   if (a < 0) a=a+65536;
   write(pk_file, "%c", a/256);
   write(pk_file, "%c", a%256);
   pk_loc=pk_loc+2;
} 
@#
void pk_three_bytes(int a)
{@+
   write(pk_file, "%c", a/65536%256);
   write(pk_file, "%c", a/256%256);
   write(pk_file, "%c", a%256);
   pk_loc=pk_loc+3;
} 
@#
void pk_word(int a)
{@+int b;

   if (pk_open) {@+
      if (a < 0) {@+
         a=a+010000000000;
         a=a+010000000000;
         b=128+a/16777216;
      } else b=a/16777216;
      write(pk_file, "%c", b);
      write(pk_file, "%c", a/65536%256);
      write(pk_file, "%c", a/256%256);
      write(pk_file, "%c", a%256);
      pk_loc=pk_loc+4;
   } 
} 
@#
void pk_nyb(int a)
{@+
   if (bit_weight==16) {@+
      output_byte=a*16;
      bit_weight=1;
   } else{@+
      pk_byte(output_byte+a);
      bit_weight=16;
   } 
} 

@ We need the globals |bit_weight| and |output_byte| for buffering.

@<Glob...@>=
int @!bit_weight; /*output bit weight*/ 
int @!output_byte; /*output byte for pk file*/ 

@ Finally we come to the routines that are used for random access of the
|gf_file|.  To correctly find and read the postamble of the file, we need
two routines, one to find the length of the |gf_file|, and one to position
the |gf_file|.  We assume that the first byte of the file is numbered zero.

Such routines are, of course, highly system dependent.  They are implemented
here in terms of two assumed system routines called |set_pos| and |cur_pos|.
The call |set_pos(f, n)| moves to item |n| in file |f|, unless |n| is negative
or larger than the total number of items in |f|; in the latter case,
|set_pos(f, n)| moves to the end of file |f|.  The call |cur_pos(f)| gives the
total number of items in |f|, if |eof(f)| is true; we use |cur_pos| only in
such a situation.
@^system dependencies@>

@p void find_gf_length(void)
{@+
   fseek(gf_file.f,0,SEEK_END);gf_len=ftell(gf_file.f);
} 
@#
void move_to_byte(int @!n)
{@+
   set_pos(gf_file, n);gf_loc=n;
} 

@ The global |gf_len| contains the final total length of the |gf_file|.

@<Glob...@>=
int @!gf_len; /*length of |gf_file|*/ 

@*Plan of attack.
It would seem at first that converting a \.{GF} file to \.{PK} format should
be relatively easy, since they both use a form of run-encoding.  Unfortunately,
several idiosyncrasies of the \.{GF} format make this conversion slightly
cumbersome.
The \.{GF} format separates the raster information from the escapement values
and \.{TFM} widths; the \.{PK} format combines all information about a single
character into one character packet.  The \.{GF} run-encoding is
on a row-by-row basis, and the \.{PK} format is on a glyph basis, as if all
of the raster rows in the glyph were concatenated into one long row.  The
encoding of the run-counts in the \.{GF} files is fixed, whereas the \.{PK}
format uses a dynamic encoding scheme that must be adjusted for each
character.  And,
finally, any repeated rows can be marked and sent with a single command in
the \.{PK} format.

There are four major steps in the conversion process.  First, the postamble
of the |gf_file| is found and read, and the data from the character locators
is stored in memory.  Next, the preamble of the |pk_file| is written.  The
third and by far
the most difficult step reads the raster representation of all of the
characters from the \.{GF} file, packs them, and writes them to the |pk_file|.
Finally, the postamble is written to the |pk_file|.

The conversion of the character raster information from the |gf_file| to the
format required by the |pk_file| takes several smaller steps.
The \.{GF} file is read, the commands are interpreted, and the run
counts are stored in the working |row| array.  Each row is terminated by a
|end_of_row| value, and the character glyph is terminated by an
|end_of_char| value.  Then, this representation of the character glyph
is scanned to determine the minimum bounding box in which it will fit,
correcting the |min_m|, |max_m|, |min_n|, and |max_n| values, and calculating
the offset values.  The third sub-step is to restructure the row list from
a list based on rows to a list based on the entire glyph.  Then, an optimal
value of |dyn_f| is calculated, and the final
size of the counts is found for the \.{PK} file format, and compared with
the bit-wise packed glyph.  If the run-encoding scheme is shorter, the
character is written to the |pk_file| as row counts; otherwise, it is written
using a bit-packed scheme.

To save various information while the \.{GF} file is being loaded, we need
several arrays.  The |tfm_width|, |dx|, and |dy| arrays store the obvious
values.  The |status| array contains
the current status of the particular character.  A value of 0 indicates
that the character has never been defined; a 1 indicates that the character
locator for that character was read in; and a 2 indicates that the raster
information for at least
one character was read from the |gf_file| and written to the |pk_file|.
The |row| array contains row counts.  It is filled anew
for each character, and is used as a general workspace.  The \.{GF} counts are
stored starting at location 2 in this array, so that the \.{PK} counts can be
written to the same array, overwriting the \.{GF} counts, without destroying
any counts before they are used.  (A possible repeat count in the first row
might make the first row of the \.{PK} file one count longer; all succeeding
rows are guaranteed to be the same length or shorter because of the
|end_of_row| flags in the \.{GF} format that are unnecessary in the \.{PK}
format.)

@d virgin	0 /*never heard of this character yet*/ 
@d located	1 /*locators read for this character*/ 
@d sent	2 /*at least one of these characters has been sent*/ 

@<Glob...@>=
int @!tfm_width[256]; /*the \.{TFM} widths of characters*/ 
int @!dx[256], @!dy[256]; /*the horizontal and vertical escapements*/ 
uint8_t @!status[256]; /*character status*/ 
int @!row[max_row+1]; /*the row counts for working*/ 

@ Here we initialize all of the character |status| values to |virgin|.

@<Set init...@>=
for (i=0; i<=255; i++) 
   status[i]=virgin;

@ And, finally, we need to define the |end_of_row| and |end_of_char| values.
These cannot be values that can be taken on either by legitimate run counts,
even when wrapping around an entire character.  Nor can they be values that
repeat counts can take on.  Since repeat counts can be arbitrarily large, we
restrict ourselves to negative values whose absolute values are greater than
the largest possible repeat count.

@d end_of_row	(-99999) /*indicates the end of a row*/ 
@d end_of_char	(-99998) /*indicates the end of a character*/ 

@*Reading the generic font file.
There are two major procedures in this program that do all of the work.
The first is |convert_gf_file|, which interprets the \.{GF} commands and
puts row counts into the |row| array.  The second, which we only
anticipate at the moment, actually packs the row counts into nybbles and
writes them to the packed file.

@p@<Packing procedures@>
void convert_gf_file(void)
{@+
   int @!i, @!j, @!k; /*general purpose indices*/ 
   int @!gf_com; /*current gf command*/ 
   @<Locals to |convert_gf_file|@>@;

   open_gf_file();
   if (gf_byte()!=pre) bad_gf("First byte is not preamble");
@.First byte is not preamble@>
   if (gf_byte()!=gf_id_byte) 
        bad_gf("Identification byte is incorrect");
@.Identification byte incorrect@>
   @<Find and interpret postamble@>;
   move_to_byte(2);
   open_pk_file();
   @<Write preamble@>;
   @/do@+{
     gf_com=gf_byte();
     switch (gf_com) {
        case boc: case boc1: @<Interpret character@>@;@+break;
        @<Specials and |no_op| cases@>;@+break;
        case post: ;@+break; /*we will actually do the work for this one later*/ 
     default:bad_gf("Unexpected %d command between characters", gf_com)@;
@.Unexpected command@>
     } 
   }@+ while (!(gf_com==post));
   @<Write postamble@>;
} 

@ We need a few easy macros to expand some case statements:

@d four_cases(X)	case X: case X+1: case X+2: case X+3
@d sixteen_cases(X)	four_cases(X): four_cases(X+4): four_cases(X+8):
         four_cases(X+12)
@d sixty_four_cases(X)	sixteen_cases(X): sixteen_cases(X+16):
         sixteen_cases(X+32): sixteen_cases(X+48)
@d one_sixty_five_cases(X)	sixty_four_cases(X): sixty_four_cases(X+64):
         sixteen_cases(X+128): sixteen_cases(X+144): four_cases(X+160): case X+164

@ In this program, all special commands are passed unchanged and any |no_op|
bytes are ignored, so we write some code to handle these:

@<Specials and |no_op| cases@>=
four_cases(xxx1): {@+
   pk_byte(gf_com-xxx1+pk_xxx1);
   i=0;for (j=0; j<=gf_com-xxx1; j++) {@+
      k=gf_byte();pk_byte(k);i=i*256+k;
   } 
   for (j=1; j<=i; j++) pk_byte(gf_byte());} @+break;
case yyy: {@+pk_byte(pk_yyy);pk_word(gf_signed_quad());} @+break;
case no_op: 

@ Now we need the routine that handles the character commands.  Again,
only a subset of the gf commands are permissible inside character
definitions, so we only look for these.

@<Interpret character@>=
{@+
  if (gf_com==boc) {@+
    gf_ch=gf_signed_quad();
    i=gf_signed_quad(); /*dispose of back pointer*/ 
    min_m=gf_signed_quad();
    max_m=gf_signed_quad();
    min_n=gf_signed_quad();
    max_n=gf_signed_quad();
  } else{@+
    gf_ch=gf_byte();
    i=gf_byte();
    max_m=gf_byte();
    min_m=max_m-i;
    i=gf_byte();
    max_n=gf_byte();
    min_n=max_n-i;
  } 
  d_print_ln("Character ", gf_ch: 1);
  if (gf_ch >= 0) gf_ch_mod_256=gf_ch%256;
  else gf_ch_mod_256=255-((-(1+gf_ch))%256);
  if (status[gf_ch_mod_256]==virgin) 
    bad_gf("no character locator for character %d", gf_ch);
@.no character locator...@>
  @<Convert character to packed form@>;
} 

@ Communication between the procedures |convert_gf_file| and
|pack_and_send_character| is done with a few global variables.

@<Glob...@>=
int @!gf_ch; /*the character we are working with*/ 
int @!gf_ch_mod_256; /*locator pointer*/ 
int @!pred_pk_loc; /*where we predict the end of the character to be.*/ 
int @!max_n, @!min_n; /*the maximum and minimum horizontal rows*/ 
int @!max_m, @!min_m; /*the maximum and minimum vertical rows*/ 
int @!row_ptr; /*where we are in the |row| array.*/ 

@ Now we are at the beginning of a character that we need the raster for.
Before we get into the complexities of decoding the |paint|, |skip|, and
|new_row| commands, let's define a macro that will help us fill up the
|row| array.  Note that we check that |row_ptr| never exceeds |max_row|;
Instead of
calling |bad_gf| directly, as this macro is repeated eight times, we simply
set the |bad| flag true.

@d put_in_rows(X)	{@+if (row_ptr > max_row) bad=true;else{@+
row[row_ptr]=X;incr(row_ptr);} } 

@ Now we have the procedure that decodes the various commands and puts counts
into the |row| array.  This would be a trivial procedure, except for
the |paint_0| command.  Because the |paint_0| command exists, it is possible
to have a sequence like |paint| 42, |paint_0|, |paint| 38, |paint_0|,
|paint_0|, |paint_0|, |paint| 33, |skip_0|.  This would be an entirely empty
row, but if we left the zeros in the |row| array, it would be difficult
to recognize the row as empty.

This type of situation probably would never
occur in practice, but it is defined by the \.{GF} format, so we must be able
to handle it.  The extra code is really quite simple, just difficult to
understand; and it does not cut down the speed appreciably.  Our goal is
this: to collapse sequences like |paint| 42, |paint_0|, |paint| 32 to a single
count of 74, and to insure that the last count of a row is a black count rather
than a white count.  A buffer variable |extra|, and two state flags, |on| and
|state|, enable us to accomplish this.

The |on| variable is essentially the |paint_switch| described in the \.{GF}
description.  If it is true, then we are currently painting black pixels.
The |extra| variable holds a count that is about to be placed into the
|row| array.  We hold it in this array until we get a |paint| command
of the opposite color that is greater than 0.  If we get a |paint_0| command,
then the |state| flag is turned on, indicating that the next count we receive
can be added to the |extra| variable as it is the same color.

@<Convert character to packed form@>=
{@+
  bad=false;
  row_ptr=2;
  on=false;
  extra=0;
  state=true;
  @/do@+{
    gf_com=gf_byte();
    switch (gf_com) {
@t\4@>@<Cases for |paint| commands@>@;@+break;
four_cases(skip0): {@+
  i=0;for (j=1; j<=gf_com-skip0; j++) i=i*256+gf_byte();
  if (on==state) put_in_rows(extra);
  for (j=0; j<=i; j++) put_in_rows(end_of_row);
  on=false;extra=0;state=true;
} @+break;
one_sixty_five_cases(new_row_0): {@+
  if (on==state) put_in_rows(extra);
  put_in_rows(end_of_row);
  on=true;extra=gf_com-new_row_0;state=false;
} @+break;
@t\4@>@<Specials and |no_op| cases@>;@+break;
case eoc: {@+
  if (on==state) put_in_rows(extra);
  if ((row_ptr > 2)&&(row[row_ptr-1]!=end_of_row)) 
    put_in_rows(end_of_row);
  put_in_rows(end_of_char);
  if (bad) abort("Ran out of internal memory for row counts!");
@.Ran out of memory@>
  pack_and_send_character();
  status[gf_ch_mod_256]=sent;
  if (pk_loc!=pred_pk_loc) 
    abort("Internal error while writing character!");
@.Internal error@>
} @+break;
default:bad_gf("Unexpected %d command in character definition", gf_com)@;
@.Unexpected command@>
    } 
  }@+ while (!(gf_com==eoc));
} 

@ A few more locals used above and below:

@<Locals to |convert_gf_file|@>=
bool @!on; /*indicates whether we are white or black*/ 
bool @!state; /*a state variable---is the next count the same race as
   the one in the |extra| buffer?*/ 
int @!extra; /*where we pool our counts*/ 
bool @!bad; /*did we run out of space?*/ 

@ @<Cases for |paint| commands@>=
case paint_0: {@+
  state=!state;
  on=!on;
} @+break;
sixty_four_cases(paint_0+1): case paint1+1: case paint1+2: {@+
  if (gf_com < paint1) i=gf_com-paint_0;
  else{@+
    i=0;for (j=0; j<=gf_com-paint1; j++) i=i*256+gf_byte();
  } 
  if (state) {@+
    extra=extra+i;
    state=false;
  } else{@+
    put_in_rows(extra);
    extra=i;
  } 
  on=!on;
} 

@ Our last remaining task is to interpret the postamble commands.  The only
things that may appear in the postamble are |post_post|, |char_loc|,
|char_loc0|, and the special commands.
Note that any special commands that might appear in the postamble are
not written to the |pk_file|.  Since \MF\ does not generate special commands
in the postamble, this should not be a major difficulty.

@<Find and interpret postamble@>=
find_gf_length();
if (gf_len < 8) bad_gf("only %d bytes long", gf_len);
@.only n bytes long@>
post_loc=gf_len-4;
@/do@+{
   if (post_loc==0) bad_gf("all 223's");
@.all 223\char39s@>
   move_to_byte(post_loc);k=gf_byte();decr(post_loc);
}@+ while (!(k!=223));
if (k!=gf_id_byte) bad_gf("ID byte is %d", k);
@.ID byte is wrong@>
if (post_loc < 5) bad_gf("post location is %d", post_loc);
@.post location is@>
move_to_byte(post_loc-3);
q=gf_signed_quad();
if ((q < 0)||(q > post_loc-3)) bad_gf("post pointer is %d", q);
@.post pointer is wrong@>
move_to_byte(q);k=gf_byte();
if (k!=post) bad_gf("byte at %d is not post", q);
@.byte is not post@>
i=gf_signed_quad(); /*skip over junk*/ 
design_size=gf_signed_quad();
check_sum=gf_signed_quad();
hppp=gf_signed_quad();
h_mag=round(hppp*72.27/(double)65536);
vppp=gf_signed_quad();
if (hppp!=vppp) print_ln("Odd aspect ratio!");
@.Odd aspect ratio@>
i=gf_signed_quad();i=gf_signed_quad(); /*skip over junk*/ 
i=gf_signed_quad();i=gf_signed_quad();
@/do@+{
  gf_com=gf_byte();
  switch (gf_com) {
case char_loc: case char_loc0: {@+
  gf_ch=gf_byte();
  if (status[gf_ch]!=virgin) 
    bad_gf("Locator for this character already found.");
@.Locator...already found@>
  if (gf_com==char_loc) {@+
    dx[gf_ch]=gf_signed_quad();
    dy[gf_ch]=gf_signed_quad();
  } else{@+
    dx[gf_ch]=gf_byte()*65536;
    dy[gf_ch]=0;
  } 
  tfm_width[gf_ch]=gf_signed_quad();
  i=gf_signed_quad();
  status[gf_ch]=located;
} @+break;
@<Specials and |no_op| cases@>;@+break;
case post_post: ;@+break;
default:bad_gf("Unexpected %d in postamble", gf_com)@;
@.Unexpected command@>
  } 
}@+ while (!(gf_com==post_post))

@ Just a few more locals:

@<Locals to |convert_gf_file|@>=
int @!hppp, @!vppp; /*horizontal and vertical pixels per point*/ 
int @!q; /*quad temporary*/ 
int @!post_loc; /*where the postamble was*/ 

@*Converting the counts to packed format.
This procedure is passed the set of row counts from the \.{GF} file.  It
writes the character to the \.{PK} file.  First, the minimum bounding box
is determined.  Next, the row-oriented count list is converted to a count
list based on the entire glyph.  Finally, we calculate
the optimal |dyn_f| and send the character.

@<Packing procedures@>=
void pack_and_send_character(void)
{@+int i, @!j, @!k; /*general indices*/ 
@<Locals to |pack_and_send_character|@>@;

  @<Scan for bounding box@>;
  @<Convert row-list to glyph-list@>;
  @<Calculate |dyn_f| and packed size and write character@>;
} 

@ Now we have the row counts in our |row| array.  To find the real |max_n|,
we look for
the first non-|end_of_row| value in the |row|.  If it is an |end_of_char|,
the entire character is blank.  Otherwise, we first eliminate all of the blank
rows at the end of the character.  Next, for each remaining row, we check the
first white count for a new |min_m|, and the total length of the row
for a new |max_m|.

@<Scan for bounding box@>=
i=2;decr(row_ptr);
while (row[i]==end_of_row) incr(i);
if (row[i]!=end_of_char) {@+
  max_n=max_n-i+2;
  while (row[row_ptr-2]==end_of_row) {@+
    decr(row_ptr);row[row_ptr]=end_of_char;
  } 
  min_n=max_n+1;
  extra=max_m-min_m+1;
  max_m=0;
  j=i;
  while (row[j]!=end_of_char) {@+
    decr(min_n);
    if (row[j]!=end_of_row) {@+
      k=row[j];
      if (k < extra) extra=k;
      incr(j);
      while (row[j]!=end_of_row) {@+
        k=k+row[j];incr(j);
      } 
      if (max_m < k) max_m=k;
    } 
    incr(j);
  } 
  min_m=min_m+extra;
  max_m=min_m+max_m-1-extra;
  height=max_n-min_n+1;
  width=max_m-min_m+1;
  x_offset=-min_m;
  y_offset=max_n;
  d_print_ln("W ", width: 1," H ", height: 1," X ", x_offset: 1," Y ", y_offset: 1);
} else{@+
  height=0;width=0;x_offset=0;y_offset=0;
  d_print_ln("Empty raster.");
} 

@ We must convert the run-count array from a row orientation to a glyph
orientation, with repeat counts for repeated rows.  We separate this task
into two smaller tasks, on a per row basis.  But first, we define a new
macro to help us fill up this new array.  Here, we have no fear that we will
run out of space, as the glyph representation is provably smaller than the
rows representation.

@d put_count(X)	{@+row[put_ptr]=X;incr(put_ptr);
if (repeat_flag > 0) {@+
   row[put_ptr]=-repeat_flag;repeat_flag=0;incr(put_ptr);} 
} 

@<Convert row-list to glyph-list@>=
put_ptr=0;row_ptr=2;repeat_flag=0;
state=true;buff=0;
while (row[row_ptr]==end_of_row) incr(row_ptr);
while (row[row_ptr]!=end_of_char) {@+
   @<Skip over repeated rows@>;
   @<Reformat count list@>;
} 
if (buff > 0) 
   put_count(buff);
put_count(end_of_char)

@ Some more locals for |pack_and_send_character| used above:

@<Locals to |pack_and_send_character|@>=
int @!extra; /*little buffer for count values*/ 
int @!put_ptr; /*next location to fill in |row|*/ 
int @!repeat_flag; /*how many times the current row is repeated*/ 
int @!h_bit; /*horizontal bit count for each row*/ 
int @!buff; /*our count accumulator*/ 

@ In this short section of code, we are at the beginning of a new row.
We scan forward, looking for repeated rows.  If there are any, |repeat_flag|
gets the count, and the |row_ptr| points to the beginning of the last of the
repeated rows.  Two points must be made here.  First, we do not count all-black
or all-white rows as repeated, as a large ``paint'' count will take care of
them, and also there is no black to white or white to black transition in the
row where we could insert a repeat count.  That is the meaning of the big
if statement that conditions this section.  Secondly, the |while row[i]==
row[j]do| loop is guaranteed to terminate, as $|j| > |i|$ and the character
is terminated by a unique |end_of_char| value.

@<Skip over repeated rows@>=
i=row_ptr;
if ((row[i]!=end_of_row)&&((row[i]!=extra)||(row[i+1]!=
   width))) {@+
   j=i+1;
   while (row[j-1]!=end_of_row) incr(j);
   while (row[i]==row[j]) {@+
      if (row[i]==end_of_row) {@+
         incr(repeat_flag);
         row_ptr=i+1;
      } 
      incr(i);incr(j);
   } 
} 

@ Here we actually spit out a row.  The routine is somewhat similar to the
routine where we actually interpret the \.{GF} commands in the count buffering.
We must make sure to keep track of how many bits have actually been sent, so
when we hit the end of a row, we can send a white count for the remaining
bits, and possibly add the white count of the next row to it.  And, finally,
we must not forget to subtract the |extra| white space at the beginning of
each row from the first white count.

@<Reformat count list@>=
if (row[row_ptr]!=end_of_row) row[row_ptr]=row[row_ptr]-extra;
h_bit=0;
while (row[row_ptr]!=end_of_row) {@+
   h_bit=h_bit+row[row_ptr];
   if (state) {@+
      buff=buff+row[row_ptr];
      state=false;
   } else if (row[row_ptr] > 0) {@+
      put_count(buff);
      buff=row[row_ptr];
   } else state=true;
   incr(row_ptr);
} 
if (h_bit < width) 
   if (state) 
      buff=buff+width-h_bit;
   else{@+
      put_count(buff);
      buff=width-h_bit;
      state=true;
   } 
else state=false;
incr(row_ptr)

@ Here is another piece of rather intricate code.  We determine the
smallest size in which we can pack the data, calculating |dyn_f| in the
process.  To do this, we calculate the size required if |dyn_f| is 0, and put
this in |comp_size|.  Then, we calculate the changes in the size for each
increment of |dyn_f|, and stick these values in the |deriv| array.  Finally,
we scan through this array and find the final minimum value, which we then
use to send the character data.

@<Calculate |dyn_f| and packed size and write character@>=
for (i=1; i<=13; i++) deriv[i]=0;
i=0;
first_on=row[i]==0;
if (first_on) incr(i);
comp_size=0;
while (row[i]!=end_of_char) 
   @<Process count for best |dyn_f| value@>;
b_comp_size=comp_size;
dyn_f=0;
for (i=1; i<=13; i++) {@+
   comp_size=comp_size+deriv[i];
   if (comp_size <= b_comp_size) {@+
      b_comp_size=comp_size;
      dyn_f=i;
   } 
} 
comp_size=(b_comp_size+1)/2;
if ((comp_size > (height*width+7)/8)||(height*width==0)) {@+
   comp_size=(height*width+7)/8;
   dyn_f=14;
} 
d_print_ln("Best packing is dyn_f of ", dyn_f: 1," with length "
    , comp_size: 1);
@<Write character preamble@>;
if (dyn_f!=14) 
   @<Send compressed format@>@;
else if (height > 0) 
   @<Send bit map@>@;

@ When we enter this module, we have a count at |row[i]|.  First, we add to
the |comp_size| the number of
nybbles that this count would require, assuming |dyn_f| to be zero.  When
|dyn_f| is zero, there are no one nybble counts, so we simply choose between
two-nybble and extensible counts and add the appropriate value.

Next, we take the count value and determine the value of |dyn_f| (if any) that
would cause this count to take either more or less nybbles.  If a valid value
for |dyn_f| exists in this range, we accumulate this change in the |deriv|
array.

One special case handled here is a repeat count of one.
A repeat count of one will never change the length of the raster
representation, no matter what |dyn_f| is, because it is always
represented by the nybble value 15.

@<Process count for best |dyn_f| value@>=
{@+
   j=row[i];
   if (j==-1) incr(comp_size);
   else{@+
      if (j < 0) {@+
         incr(comp_size);
         j=-j;
      } 
      if (j < 209) comp_size=comp_size+2;
      else{@+
         k=j-193;
         while (k >= 16) {@+
            k=k/16;
            comp_size=comp_size+2;
         } 
         incr(comp_size);
      } 
      if (j < 14) decr(deriv[j]);
      else if (j < 209) incr(deriv[(223-j)/15]);
      else{@+
         k=16;
         while ((k*16 < j+3)) k=k*16;
         if (j-k <= 192) deriv[(207-j+k)/15]=deriv[(207-j+k)/15]
            +2;
       } 
   } 
   incr(i);
} 

@ We need a handful of locals:

@<Locals to |pack_and_send_character|@>=
int @!dyn_f; /*packing value*/ 
int @!height, @!width; /*height and width of character*/ 
int @!x_offset, @!y_offset; /*offsets*/ 
int @!deriv0[13], *const @!deriv = @!deriv0-1; /*derivative*/ 
int @!b_comp_size; /*best size*/ 
bool @!first_on; /*indicates that the first bit is on*/ 
int @!flag_byte; /*flag byte for character*/ 
bool @!state; /*state variable*/ 
bool @!on; /*white or black?*/ 

@ Now we write the character preamble information.  First we need to determine
which of the three formats we should use.

@<Write character preamble@>=
flag_byte=dyn_f*16;
if (first_on) flag_byte=flag_byte+8;
if ((gf_ch!=gf_ch_mod_256)||(tfm_width[gf_ch_mod_256] > 16777215)||
      (tfm_width[gf_ch_mod_256] < 0)||(dy[gf_ch_mod_256]!=0)||
      (dx[gf_ch_mod_256] < 0)||(dx[gf_ch_mod_256]%65536!=0)||
      (comp_size > 196594)||(width > 65535)||
      (height > 65535)||(x_offset > 32767)||(y_offset > 32767)||
      (x_offset < -32768)||(y_offset < -32768)) 
   @<Write long character preamble@>@;
else if ((dx[gf_ch] > 16777215)||(width > 255)||(height > 255)||
      (x_offset > 127)||(y_offset > 127)||(x_offset < -128)||
      (y_offset < -128)||(comp_size > 1015)) 
   @<Write two-byte short character preamble@>@;
else
   @<Write one-byte short character preamble@>@;

@ If we must write a long character preamble, we
adjust a few parameters, then write the data.

@<Write long character preamble@>=
{@+
   flag_byte=flag_byte+7;
   pk_byte(flag_byte);
   comp_size=comp_size+28;
   pk_word(comp_size);
   pk_word(gf_ch);
   pred_pk_loc=pk_loc+comp_size;
   pk_word(tfm_width[gf_ch_mod_256]);
   pk_word(dx[gf_ch_mod_256]);
   pk_word(dy[gf_ch_mod_256]);
   pk_word(width);
   pk_word(height);
   pk_word(x_offset);
   pk_word(y_offset);
} 

@ Here we write a short short character preamble, with one-byte size
parameters.

@<Write one-byte short character preamble@>=
{@+
   comp_size=comp_size+8;
   flag_byte=flag_byte+comp_size/256;
   pk_byte(flag_byte);
   pk_byte(comp_size%256);
   pk_byte(gf_ch);
   pred_pk_loc=pk_loc+comp_size;
   pk_three_bytes(tfm_width[gf_ch_mod_256]);
   pk_byte(dx[gf_ch_mod_256]/65536);
   pk_byte(width);
   pk_byte(height);
   pk_byte(x_offset);
   pk_byte(y_offset);
} 

@ Here we write an extended short character preamble, with two-byte
size parameters.

@<Write two-byte short character preamble@>=
{@+
   comp_size=comp_size+13;
   flag_byte=flag_byte+comp_size/65536+4;
   pk_byte(flag_byte);
   pk_halfword(comp_size%65536);
   pk_byte(gf_ch);
   pred_pk_loc=pk_loc+comp_size;
   pk_three_bytes(tfm_width[gf_ch_mod_256]);
   pk_halfword(dx[gf_ch_mod_256]/65536);
   pk_halfword(width);
   pk_halfword(height);
   pk_halfword(x_offset);
   pk_halfword(y_offset);
} 

@ At this point, we have decided that the run-encoded format is smaller.  (This
is almost always the case.)  We send out the data, a nybble at a time.

@<Send compressed format@>=
{@+
   bit_weight=16;
   max_2=208-15*dyn_f;
   i=0;
   if (row[i]==0) incr(i);
   while (row[i]!=end_of_char) {@+
      j=row[i];
      if (j==-1) 
         pk_nyb(15);
      else{@+
         if (j < 0) {@+
            pk_nyb(14);
            j=-j;
         } 
         if (j <= dyn_f) pk_nyb(j);
         else if (j <= max_2) {@+
            j=j-dyn_f-1;
            pk_nyb(j/16+dyn_f+1);
            pk_nyb(j%16);
         } else{@+
            j=j-max_2+15;
            k=16;
            while (k <= j) {@+
               k=k*16;
               pk_nyb(0);
            } 
            while (k > 1) {@+
               k=k/16;
               pk_nyb(j/k);
               j=j%k;
            } 
         } 
      } 
      incr(i);
   } 
   if (bit_weight!=16) pk_byte(output_byte);
} 

@ This code is for the case where we have decided to send the character raster
packed by bits.  It uses the bit counts as well, sending eight at a time.
Here we have a miniature packed format interpreter, as we must repeat any rows
that are repeated.  The algorithm to do this was a lot of fun to generate.  Can
you figure out how it works?

@<Send bit map@>=
{@+
   buff=0;
   p_bit=8;
   i=1;
   h_bit=width;
   on=false;
   state=false;
   count=row[0];
   repeat_flag=0;
   while ((row[i]!=end_of_char)||state||(count > 0)) {@+
      if (state) {@+
         count=r_count;i=r_i;on=r_on;
         decr(repeat_flag);
      } else{@+
         r_count=count;r_i=i;r_on=on;
      } 
      @<Send one row by bits@>;
      if (state&&(repeat_flag==0)) {@+
         count=s_count;i=s_i;on=s_on;
         state=false;
      } else if (!state&&(repeat_flag > 0)) {@+
         s_count=count;s_i=i;s_on=on;
         state=true;
      } 
   } 
   if (p_bit!=8) pk_byte(buff);
} 

@ All of the remaining locals:

@<Locals to |pack_and_send_character|@>=
int @!comp_size; /*length of the packed representation in bytes*/ 
int @!count; /*number of bits in current state to send*/ 
int @!p_bit; /*what bit are we about to send out?*/ 
bool @!r_on, @!s_on; /*state saving variables*/ 
int @!r_count, @!s_count; /*ditto*/ 
int @!r_i, @!s_i; /*and again.*/ 
int @!max_2; /*the highest count that fits in two bytes*/ 

@ We make the |power| array global.

@<Glob...@>=
int @!power[9]; /*easy powers of two*/ 

@ We initialize the power array.

@<Set init...@>=
power[0]=1;
for (i=1; i<=8; i++) power[i]=power[i-1]+power[i-1];

@ Here we are at the beginning of a row and simply output the next |width| bits.
We break the possibilities up into three cases: we finish a byte but not
the row, we finish a row, and we finish neither a row nor a byte.  But,
first, we insure that we have a |count| value.

@<Send one row by bits@>=
@/do@+{
   if (count==0) {@+
      if (row[i] < 0) {@+
         if (!state) repeat_flag=-row[i];
         incr(i);
      } 
      count=row[i];
      incr(i);
      on=!on;
   } 
   if ((count >= p_bit)&&(p_bit < h_bit)) {@+
 /* we end a byte, we don't end the row */ 
      if (on) buff=buff+power[p_bit]-1;
      pk_byte(buff);buff=0;
      h_bit=h_bit-p_bit;count=count-p_bit;p_bit=8;
   } else if ((count < p_bit)&&(count < h_bit)) {@+
 /* we end neither the row nor the byte */ 
      if (on) buff=buff+power[p_bit]-power[p_bit-count];
      p_bit=p_bit-count;h_bit=h_bit-count;count=0;
   } else{@+
 /* we end a row and maybe a byte */ 
      if (on) buff=buff+power[p_bit]-power[p_bit-h_bit];
      count=count-h_bit;p_bit=p_bit-h_bit;h_bit=width;
      if (p_bit==0) {@+
         pk_byte(buff);buff=0;p_bit=8;
      } 
   } 
}@+ while (!(h_bit==width))

@ Now we are ready for the routine that writes the preamble of the packed
file.

@d preamble_comment	"GFtoPK 2.4 output from "
@d comm_length	23 /*length of |preamble_comment|*/ 
@d from_length	6 /*length of its |" from "| part*/ 

@<Write preamble@>=
pk_byte(pk_pre);
pk_byte(pk_id);
i=gf_byte(); /*get length of introductory comment*/ 
@/do@+{if (i==0) j='.';@+else j=gf_byte();
decr(i); /*some people think it's wise to avoid |goto| statements*/ 
}@+ while (!(j!=' ')); /*remove leading blanks*/ 
incr(i); /*this many bytes to copy*/ 
if (i==0) k=comm_length-from_length;
else k=i+comm_length;
if (k > 255) pk_byte(255);@+else pk_byte(k);
for (k=1; k<=comm_length; k++) 
  if ((i > 0)||(k <= comm_length-from_length)) pk_byte(xord[comment[k]]);
print("'");
for (k=1; k<=i; k++) 
  {@+if (k > 1) j=gf_byte();
  print("%c",xchr[j]);
  if (k < 256-comm_length) pk_byte(j);
  } 
print_ln("'");@/
pk_word(design_size);
pk_word(check_sum);
pk_word(hppp);
pk_word(vppp)

@ Of course, we need an array to hold the comment.

@<Glob...@>=
uint8_t @!comment0[comm_length+1], *const @!comment = @!comment0-1;

@ @<Set init...@>=
strcpy(comment+1, preamble_comment);

@ Writing the postamble is even easier.

@<Write postamble@>=
pk_byte(pk_post);
while ((pk_loc%4!=0)) pk_byte(pk_no_op)

@ Once we are finished with the \.{GF} file, we check the status of each
character to insure that each character that had a locator also had raster
information.

@<Check for unrasterized locators@>=
for (i=0; i<=255; i++) 
   if (status[i]==located) 
      print_ln("Character %d missing raster information!", i)
@.missing raster information@>

@ Finally, the main program.

@p int main(int argc, char **argv) { if (argc != 4) return 2;
  if ((gf_file.f=fopen(argv[1],"r"))==NULL) return 2;
  if ((pk_file.f=fopen(argv[2],"w"))==NULL) return 2;
  if ((output=fopen(argv[3],"w"))==NULL) return 2;
  initialize();
  convert_gf_file();
  @<Check for unrasterized locators@>;
  print_ln("%d bytes packed to %d bytes.", gf_len, pk_loc);
return 0; }

@ A few more globals.

@<Glob...@>=
int @!check_sum; /*the checksum of the file*/ 
int @!design_size; /*the design size of the font*/ 
int @!h_mag; /*the pixel magnification in pixels per inch*/ 
int @!i;

@*System-dependent changes.
This section should be replaced, if necessary, by changes to the program
that are necessary to make \.{GFtoPK} work at a particular installation.
It is usually best to design your change file so that all changes to
previous sections preserve the section numbering; then everybody's version
will be consistent with the printed program. More extensive changes,
which introduce new sections, can be inserted here; then only the index
itself will get a new section number.
@^system dependencies@>

@*Index.
Pointers to error messages appear here together with the section numbers
where each ident\-i\-fier is used.

@ Appendix: Replacement of the string pool file.
@d str_0_255 	"^^@@^^A^^B^^C^^D^^E^^F^^G^^H^^I^^J^^K^^L^^M^^N^^O"@/
	"^^P^^Q^^R^^S^^T^^U^^V^^W^^X^^Y^^Z^^[^^\\^^]^^^^^_"@/
	" !\"#$%&'()*+,-./"@/
	"0123456789:;<=>?"@/
	"@@ABCDEFGHIJKLMNO"@/
	"PQRSTUVWXYZ[\\]^_"@/
	"`abcdefghijklmno"@/
	"pqrstuvwxyz{|}~^^?"@/
	"^^80^^81^^82^^83^^84^^85^^86^^87^^88^^89^^8a^^8b^^8c^^8d^^8e^^8f"@/
	"^^90^^91^^92^^93^^94^^95^^96^^97^^98^^99^^9a^^9b^^9c^^9d^^9e^^9f"@/
	"^^a0^^a1^^a2^^a3^^a4^^a5^^a6^^a7^^a8^^a9^^aa^^ab^^ac^^ad^^ae^^af"@/
	"^^b0^^b1^^b2^^b3^^b4^^b5^^b6^^b7^^b8^^b9^^ba^^bb^^bc^^bd^^be^^bf"@/
	"^^c0^^c1^^c2^^c3^^c4^^c5^^c6^^c7^^c8^^c9^^ca^^cb^^cc^^cd^^ce^^cf"@/
	"^^d0^^d1^^d2^^d3^^d4^^d5^^d6^^d7^^d8^^d9^^da^^db^^dc^^dd^^de^^df"@/
	"^^e0^^e1^^e2^^e3^^e4^^e5^^e6^^e7^^e8^^e9^^ea^^eb^^ec^^ed^^ee^^ef"@/
	"^^f0^^f1^^f2^^f3^^f4^^f5^^f6^^f7^^f8^^f9^^fa^^fb^^fc^^fd^^fe^^ff"@/
@d str_start_0_255	0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45,@/
	48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93,@/
	96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,@/
	112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,@/
	128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,@/
	144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,@/
	160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,@/
	176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191,@/
	194, 198, 202, 206, 210, 214, 218, 222, 226, 230, 234, 238, 242, 246, 250, 254,@/
	258, 262, 266, 270, 274, 278, 282, 286, 290, 294, 298, 302, 306, 310, 314, 318,@/
	322, 326, 330, 334, 338, 342, 346, 350, 354, 358, 362, 366, 370, 374, 378, 382,@/
	386, 390, 394, 398, 402, 406, 410, 414, 418, 422, 426, 430, 434, 438, 442, 446,@/
	450, 454, 458, 462, 466, 470, 474, 478, 482, 486, 490, 494, 498, 502, 506, 510,@/
	514, 518, 522, 526, 530, 534, 538, 542, 546, 550, 554, 558, 562, 566, 570, 574,@/
	578, 582, 586, 590, 594, 598, 602, 606, 610, 614, 618, 622, 626, 630, 634, 638,@/
	642, 646, 650, 654, 658, 662, 666, 670, 674, 678, 682, 686, 690, 694, 698, 702,@/
