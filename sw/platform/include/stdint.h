// stdint.h — minimal freestanding (riscv_doom_soc toolchain)
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
typedef long               intptr_t;
typedef unsigned long      uintptr_t;
#define INT32_MIN  (-2147483647-1)
#define INT32_MAX   2147483647
#define UINT32_MAX  4294967295u