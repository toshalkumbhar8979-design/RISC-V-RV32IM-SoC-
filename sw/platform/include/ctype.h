// ctype.h — minimal freestanding
#define _U 0x01
#define _L 0x02
#define _N 0x04
#define _S 0x08
#define _P 0x10
#define _C 0x20
int isprint(int);
int isspace(int);
int isalpha(int);
int isdigit(int);
int isalnum(int);
int isupper(int);
int islower(int);
int toupper(int);
int tolower(int);