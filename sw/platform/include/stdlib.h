// stdlib.h — minimal freestanding (stubs in riscvsoc_stubs.c)
typedef unsigned long size_t;
typedef long ptrdiff_t;
typedef int wchar_t;
#define NULL ((void*)0)
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1
#define RAND_MAX 32767
void *malloc(unsigned long);
void free(void*);
void *calloc(unsigned long, unsigned long);
void *realloc(void*, unsigned long);
void exit(int);
void abort(void);
int atoi(const char*);
long atol(const char*);
long strtol(const char*, char**, int);
double atof(const char*);
void srand(unsigned);
int rand(void);
int abs(int);
long labs(long);
int atexit(void(*)(void));
char *getenv(const char*);
int system(const char*);
void qsort(void*, size_t, size_t, int(*)(const void*,const void*));
void *bsearch(const void*, const void*, size_t, size_t, int(*)(const void*,const void*));