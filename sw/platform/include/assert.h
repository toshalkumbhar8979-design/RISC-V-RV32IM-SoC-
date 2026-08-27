// assert.h — minimal freestanding (disabled in release)
#define assert(x) ((void)0)
#define static_assert(c,msg) _Static_assert(c,msg)