//====================================================================
// riscvsoc_stubs.c — freestanding libc/stdio/stdlib for doomgeneric
// on the riscv_doom_soc (no OS, no libc headers — types self-defined,
// per the Phase-3 "honest note").
//====================================================================
typedef signed char        int8_t;
typedef unsigned char      uint8_t;
typedef short              int16_t;
typedef unsigned short     uint16_t;
typedef int                int32_t;
typedef unsigned int       uint32_t;
typedef long long          int64_t;
typedef unsigned long long uint64_t;
typedef unsigned long      size_t;
typedef long               ptrdiff_t;
typedef int                wchar_t;

#define NULL ((void*)0)

typedef __builtin_va_list va_list;
#define va_start(ap,last) __builtin_va_start(ap,last)
#define va_arg(ap,type)   __builtin_va_arg(ap,type)
#define va_end(ap)        __builtin_va_end(ap)
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

// ---------------- UART ----------------
#define UART_DATW (*(volatile uint32_t*)0x40020004u)
static void uart_putc(char c) { UART_DATW = (uint32_t)(unsigned char)c; }
static void uart_puts(const char* s) { while (*s) { if (*s=='\n') uart_putc('\r'); uart_putc(*s++); } }

// ---------------- memory ----------------
void *memset(void *d, int c, size_t n)
{ uint8_t *p=(uint8_t*)d; while(n--) *p++=(uint8_t)c; return d; }
void *memcpy(void *d, const void *s, size_t n)
{ uint8_t *pd=(uint8_t*)d; const uint8_t *ps=(const uint8_t*)s;
  while(n--) *pd++=*ps++; return d; }
void *memmove(void *d, const void *s, size_t n)
{ uint8_t *pd=(uint8_t*)d; const uint8_t *ps=(const uint8_t*)s;
  if(pd<ps){while(n--)*pd++=*ps++;}
  else{pd+=n;ps+=n;while(n--)*--pd=*--ps;} return d; }
int memcmp(const void *a, const void *b, size_t n)
{ const uint8_t *pa=a,*pb=b;
  while(n--){ if(*pa!=*pb) return (int)*pa-(int)*pb; pa++;pb++; } return 0; }
void *memchr(const void *s, int c, size_t n)
{ const uint8_t *p=(const uint8_t*)s;
  while(n--){ if(*p==(uint8_t)c) return (void*)p; p++; } return 0; }

// ---------------- string ----------------
size_t strlen(const char *s){ size_t n=0; while(s[n])n++; return n; }
char *strcpy(char *d, const char *s){ char *o=d; while((*d++=*s++)); return o; }
char *strncpy(char *d, const char *s, size_t n)
{ size_t i=0; for(;i<n&&s[i];i++)d[i]=s[i]; for(;i<n;i++)d[i]=0; return d; }
int strcmp(const char *a, const char *b)
{ while(*a&&*a==*b){a++;b++;} return (int)((unsigned char)*a-(unsigned char)*b); }
int strncmp(const char *a, const char *b, size_t n)
{ while(n&&*a&&*a==*b){a++;b++;n--;}
  return n?(int)((unsigned char)*a-(unsigned char)*b):0; }
char *strcat(char *d, const char *s){ char *o=d; while(*d)d++; while((*d++=*s++)); return o; }
char *strncat(char *d, const char *s, size_t n)
{ char *o=d; while(*d)d++; while(n--&&(*d++=*s++)); *d=0; return o; }
char *strchr(const char *s, int c)
{ for(;;s++){ if(*s==(char)c) return (char*)s; if(!*s) return 0; } }
char *strrchr(const char *s, int c)
{ const char *r=0; for(;;s++){ if(*s==(char)c)r=s; if(!*s) return (char*)r; } }
char *strstr(const char *h, const char *n)
{ size_t nl=strlen(n); for(;*h;h++) if(!strncmp(h,n,nl)) return (char*)h; return 0; }
char *strtok_r(char *s, const char *delim, char **save)
{ char *p; if(!s){s=*save; if(!s) return 0;}
  while(*s && strchr(delim,*s)) s++;
  if(!*s){*save=0; return 0;}
  p=s; while(*s && !strchr(delim,*s)) s++;
  if(*s){*s=0; *save=s+1;} else *save=0;
  return p; }

// ---------------- conversions / misc ----------------
int atoi(const char *s)
{ int v=0,neg=0;
  while(*s==' '||*s=='\t')s++;
  if(*s=='-'){neg=1;s++;} else if(*s=='+')s++;
  while(*s>='0'&&*s<='9') v=v*10+(*s++-'0');
  return neg?-v:v; }
long atol(const char *s){ return (long)atoi(s); }
long strtol(const char *s, char **end, int base)
{ long v=0; int neg=0;
  while(*s==' ')s++;
  if(*s=='-'){neg=1;s++;} else if(*s=='+')s++;
  for(;;s++){ int d;
    if(*s>='0'&&*s<='9') d=*s-'0';
    else if(*s>='a'&&*s<='f') d=*s-'a'+10;
    else if(*s>='A'&&*s<='F') d=*s-'A'+10;
    else break;
    if(d>=base) break;
    v=v*base+d; }
  if(end)*end=(char*)s;
  return neg?-v:v; }
static unsigned long rs=12345;
void srand(unsigned s){ rs=s; }
int rand(void){ rs=rs*1103515245u+12345u; return (int)((rs>>16)&0x7fff); }
int abs(int x){ return x<0?-x:x; }

// ---------------- printf (UART subset) ----------------
static void vformat(char *out, size_t *o, size_t n,
                    const char *fmt, va_list ap)
{
  for(; *fmt; fmt++){
    if(*fmt!='%'){
      uart_putc(*fmt);
      if(out && *o<n) out[*o]=*fmt;
      if(out) (*o)++;
      continue;
    }
    fmt++;
    int zero=0, lmod=0, width=0;
    if(*fmt=='0'){ zero=1; fmt++; }
    while(*fmt>='0'&&*fmt<='9'){ width=width*10+(*fmt-'0'); fmt++; }
    if(*fmt=='l'){ lmod=1; fmt++; if(*fmt=='l') fmt++; }
    char c=*fmt;
    if(c=='s'){ const char *s=va_arg(ap,const char*); if(!s)s="(null)";
                for(;*s;s++){ uart_putc(*s);
                  if(out && *o<n) out[*o]=*s; if(out)(*o)++; } }
    else if(c=='c'){ char ch=(char)va_arg(ap,int); uart_putc(ch);
                  if(out && *o<n) out[*o]=ch; if(out)(*o)++; }
    else if(c=='d'||c=='i'){ long v=lmod?va_arg(ap,long):va_arg(ap,int);
                int neg=v<0; unsigned long u=neg?(unsigned long)(-v):(unsigned long)v;
                char d[24]; int i=0;
                if(u==0) d[i++]='0';
                while(u){ d[i++]='0'+(u%10); u/=10; }
                int w=(width>i?width:i)-(neg?1:0);
                while(i<w){ if(out&&*o<n) out[*o]=zero?'0':' '; uart_putc(out[*o]); (*o)++; }
                if(neg){ if(out&&*o<n) out[*o]='-'; uart_putc('-'); }
                while(i--){ if(out&&*o<n) out[*o]=d[i]; uart_putc(d[i]); (*o)++; } }
    else if(c=='u'||c=='x'||c=='X'){ unsigned long v=lmod?va_arg(ap,unsigned long):va_arg(ap,unsigned);
                int base=(c=='u')?10:16, up=(c=='X');
                char d[24]; int i=0;
                const char *D=up?"0123456789ABCDEF":"0123456789abcdef";
                if(v==0) d[i++]='0';
                while(v){ d[i++]=D[v%(unsigned)base]; v/=(unsigned)base; }
                int w=(width>i?width:i);
                while(i<w){ if(out&&*o<n) out[*o]='0'; uart_putc('0'); (*o)++; }
                while(i--){ if(out&&*o<n) out[*o]=d[i]; uart_putc(d[i]); (*o)++; } }
    else if(c=='p'){ unsigned long v=(unsigned long)va_arg(ap,void*);
                char d[24]; int i=0;
                const char *D="0123456789abcdef";
                if(v==0) d[i++]='0';
                while(v){ d[i++]=D[v%16]; v/=16; }
                uart_putc('0'); uart_putc('x');
                while(i--){ if(out&&*o<n) out[*o]=d[i]; uart_putc(d[i]); (*o)++; } }
    else if(c=='%'){ uart_putc('%');
                if(out&&*o<n) out[*o]='%'; if(out)(*o)++; }
    else { uart_putc('%'); uart_putc(c);
                if(out&&*o<n){ out[*o]='%'; (*o)++; if(*o<n){out[*o]=c; (*o)++;} } }
  }
}

int vprintf(const char *fmt, va_list ap)
{ vformat(0,0,0,fmt,ap); return 0; }
int printf(const char *fmt, ...)
{ va_list ap; va_start(ap,fmt); vformat(0,0,0,fmt,ap); va_end(ap); return 0; }
int sprintf(char *out, const char *fmt, ...)
{ size_t o=0; va_list ap; va_start(ap,fmt);
  vformat(out,&o,(size_t)-1,fmt,ap); va_end(ap); out[o]=0; return (int)o; }
int snprintf(char *out, size_t n, const char *fmt, ...)
{ size_t o=0; va_list ap; va_start(ap,fmt);
  vformat(out,&o,n,fmt,ap); va_end(ap); if(n) out[o<n?o:n-1]=0; return (int)o; }
int puts(const char *s){ uart_puts(s); uart_putc('\n'); return 0; }
int putchar(int c){ uart_putc((char)c); return c; }
int fputc(int c, void *f){ (void)f; uart_putc((char)c); return c; }
int fputs(const char *s, void *f){ (void)f; uart_puts(s); return 0; }

// ---------------- stdio: memory-backed files (WAD access) ----------------
#define WAD_BASE 0x10400000u
#define WAD_MAX  (4u*1024u*1024u)
typedef struct { const char *name; uint8_t *base; size_t len; size_t pos; } mfile;
static mfile files[4];
static int nfiles = 0;
void *fopen(const char *name, const char *mode)
{ (void)mode;
  if(nfiles>=4) return 0;
  mfile *f=&files[nfiles++];
  f->name=name; f->base=(uint8_t*)WAD_BASE;
  f->len=WAD_MAX; f->pos=0;
  return (void*)f; }
size_t fread(void *p, size_t sz, size_t n, void *fp)
{ mfile *f=(mfile*)fp; size_t bytes=sz*n;
  if(f->pos+bytes>f->len) bytes=f->len-f->pos;
  memcpy(p, f->base+f->pos, bytes); f->pos+=bytes;
  return bytes/sz; }
int fseek(void *fp, long off, int whence)
{ mfile *f=(mfile*)fp;
  if(whence==0) f->pos=(size_t)off;
  else if(whence==1) f->pos+=(size_t)off;
  else f->pos=f->len;
  return 0; }
long ftell(void *fp){ return (long)((mfile*)fp)->pos; }
int fclose(void *fp){ (void)fp; return 0; }
int feof(void *fp){ return ((mfile*)fp)->pos>=((mfile*)fp)->len; }
size_t fwrite(const void *p, size_t sz, size_t n, void *fp)
{ (void)p;(void)sz;(void)n;(void)fp; return 0; }
int fgetc(void *fp)
{ mfile *f=(mfile*)fp; if(f->pos>=f->len) return -1; return f->base[f->pos++]; }
int fflush(void *fp){ (void)fp; return 0; }
int remove(const char *n){ (void)n; return 0; }
int rename(const char *a, const char *b){ (void)a;(void)b; return 0; }

// ---------------- exit / misc ----------------
void exit(int c){ (void)c; uart_puts("\\n[exit]\\n"); for(;;); }
void abort(void){ uart_puts("\\n[abort]\\n"); for(;;); }
int atexit(void (*f)(void)){ (void)f; return 0; }
char *getenv(const char *n){ (void)n; return 0; }
int system(const char *c){ (void)c; return -1; }

// ---------------- qsort / bsearch ----------------
static void swp(char *a, char *b, size_t w)
{ while(w--){ char t=*a; *a=*b; *b=t; a++; b++; } }
static void qsr(char *lo, char *hi, size_t w, int (*c)(const void*,const void*))
{ if(lo>=hi) return;
  char *p=lo, *i=lo;
  for(char *j=lo+w; j<=hi; j+=w)
    if(c(j,p)<0){ i+=w; swp(i,j,w); }
  swp(lo,i,w);
  if(i>lo+w) qsr(lo, i-w, w, c);
  if(i+w<hi) qsr(i+w, hi, w, c); }
void qsort(void *b, size_t n, size_t w, int (*c)(const void*,const void*))
{ if(n>1) qsr((char*)b, (char*)b+(n-1)*w, w, c); }
void *bsearch(const void *k, const void *b, size_t n, size_t w,
              int (*c)(const void*,const void*))
{ const char *lo=(const char*)b, *hi=lo+n*w;
  while(lo<hi){ const char *m=lo+((hi-lo)/(2*w))*w;
    int r=c(k,m);
    if(!r) return (void*)m;
    if(r<0) hi=m; else lo=m+w; }
  return 0; }

// ---------------- math (doom mostly uses fixed-point) ----------------
float sqrtf(float x){ float r=x,p=0; if(x<=0) return 0;
  do{p=r;r=(r+x/r)/2;}while(p-r>1e-6f||r-p>1e-6f); return r; }
double sqrt(double x){ return (double)sqrtf((float)x); }
double sin(double x){ (void)x; return 0; }
double cos(double x){ (void)x; return 1; }
double atan2(double y, double x){ (void)y;(void)x; return 0; }
double pow(double a, double b){ (void)b; return a; }
double floor(double x){ return (double)(long)x; }
double fabs(double x){ return x<0?-x:x; }
float fabsf(float x){ return x<0?-x:x; }
long labs(long x){ return x<0?-x:x; }
// ---------------- strings.h ----------------
int tolower(int); int toupper(int);
typedef long time_t;
time_t time(time_t*);
int strcasecmp(const char*a,const char*b)
{ while(*a&&*b){int d=(unsigned char)tolower(*a)-(unsigned char)tolower(*b); if(d)return d; a++;b++;}
  return (int)((unsigned char)tolower(*a)-(unsigned char)tolower(*b)); }
int strncasecmp(const char*a,const char*b,unsigned long n)
{ while(n&&*a&&*b){int d=(unsigned char)tolower(*a)-(unsigned char)tolower(*b); if(d)return d; a++;b++;n--;}
  return n?(int)((unsigned char)tolower(*a)-(unsigned char)tolower(*b)):0; }
int open(const char*p,int f,...){ (void)p;(void)f; return -1; }
int close(int f){ (void)f; return 0; }
int unlink(const char*p){ (void)p; return -1; }
int fprintf(void *f, const char *fmt, ...)
{ va_list ap; va_start(ap,fmt); vformat(0,0,0,fmt,ap); va_end(ap); return 0; }
int vfprintf(void *f, const char *fmt, va_list ap)
{ vformat(0,0,0,fmt,ap); return 0; }
void *stdin = (void*)0;
void *stdout = (void*)1;
void *stderr = (void*)2;
int sscanf(const char *s, const char *fmt, ...)
{ (void)s;(void)fmt; return 0; }
int scanf(const char *fmt, ...){ (void)fmt; return 0; }
int fscanf(void *f, const char *fmt, ...){ (void)f;(void)fmt; return 0; }
struct tm *localtime(const time_t *t){ (void)t; return 0; }
int stat(const char *p, void *s){ (void)p;(void)s; return -1; }
int mkdir(const char*p,unsigned m){ (void)p;(void)m; return -1; }
int usleep(unsigned u){ (void)u; return 0; }
unsigned int sleep(unsigned int s){ for(volatile unsigned i=0;i<s*1000;i++); return 0; }
long sysconf(int n){ (void)n; return 4096; }

// ---------------- strdup (needs malloc from doomgeneric_riscvsoc.c) ----------------
void *malloc(unsigned long n);
char *strdup(const char *s)
{
  size_t n = strlen(s) + 1;
  char *d = (char*)malloc(n);
  if (d) memcpy(d, s, n);
  return d;
}
double atof(const char *s){ return (double)atol(s); }
int vsnprintf(char *out, unsigned long n, const char *fmt, void *ap)
{ size_t o=0; vformat(out,&o,(size_t)n,fmt,*(va_list*)ap); if(n) out[o<n?o:n-1]=0; return (int)o; }


// ---------------- network / joystick stubs (single-player) ----------------
int net_client_connected = 0;
int drone = 0;
int netcmds[12];
void I_BindJoystickVariables(void) { }
void I_InitJoystick(void) { }
void D_ConnectNetGame(void) { }
void D_CheckNetGame(void) { }
int I_ConnectNetGame(void) { return 0; }
