// time.h — minimal freestanding
typedef long time_t;
time_t time(time_t*);
struct tm { int tm_sec,tm_min,tm_hour,tm_mday,tm_mon,tm_year; };
struct tm *localtime(const time_t*);