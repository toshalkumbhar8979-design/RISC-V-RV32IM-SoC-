// unistd.h — minimal freestanding
typedef unsigned long size_t;
typedef long ssize_t;
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2
int close(int);
ssize_t read(int, void*, size_t);
ssize_t write(int, const void*, size_t);
unsigned int sleep(unsigned int);
int usleep(unsigned int);
long sysconf(int);
int mkdir(const char*, unsigned int);
int unlink(const char*);
int mkdir(const char*, unsigned int);