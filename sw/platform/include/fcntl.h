// fcntl.h — minimal freestanding (stubs in riscvsoc_stubs.c)
#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR 2
#define O_CREAT 0100
#define O_TRUNC 01000
int open(const char*, int, ...);
int close(int);