// sys/stat.h — minimal freestanding
typedef unsigned long size_t;
typedef long time_t;
struct stat { unsigned long st_size; };
int stat(const char*, struct stat*);