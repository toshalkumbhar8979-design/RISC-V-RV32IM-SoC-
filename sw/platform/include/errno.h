// errno.h — minimal freestanding
extern int errno;
#define errno (*__errno_location())
static int *__errno_location(void) { static int e; return &e; }
#define ENOENT   2
#define ENOMEM  12
#define EACCES  13
#define EEXIST  17
#define EINVAL  22
#define EMFILE  24