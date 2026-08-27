// stdio.h — minimal freestanding (stubs in riscvsoc_stubs.c)
typedef unsigned long size_t;
#define NULL ((void*)0)
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
typedef void FILE;
extern FILE *fopen(const char*, const char*);
extern size_t fread(void*, size_t, size_t, FILE*);
extern size_t fwrite(const void*, size_t, size_t, FILE*);
extern int fclose(FILE*);
extern int fseek(FILE*, long, int);
extern long ftell(FILE*);
extern int feof(FILE*);
extern int fgetc(FILE*);
extern int fflush(FILE*);
extern int printf(const char*, ...);
extern int sprintf(char*, const char*, ...);
extern int snprintf(char*, unsigned long, const char*, ...);
extern int fprintf(void*, const char*, ...);
extern int vfprintf(void*, const char*, void*);
extern void *stdin;
extern void *stdout;
extern void *stderr;
extern int sscanf(const char*, const char*, ...);
extern int fscanf(void*, const char*, ...);
extern int vsscanf(const char*, const char*, void*);
extern int puts(const char*);
extern int putchar(int);