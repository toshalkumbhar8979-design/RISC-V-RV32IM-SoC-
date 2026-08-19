/*====================================================================
 * platform.h — hal + doomgeneric binding declarations.
 * ====================================================================*/
#ifndef PLATFORM_H
#define PLATFORM_H

/* freestanding typedefs (this cross-gcc ships no libc headers) */
typedef unsigned int   uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char  uint8_t;

/* --- low-level --- */
void uart_putc(char c);
void uart_puts(const char *s);
uint32_t mtime_ticks(void);          /* raw 64-bit lo counter */
uint32_t millis(void);               /* approximate ms from mtime */
void delay_ms(unsigned ms);

/* --- TFT helpers (ILI9341-style controller) --- */
void tft_cmd_byte(uint8_t b);        /* dc=0, waits idle */
void tft_data_byte(uint8_t b);       /* dc=1, waits idle */
void tft_reset(void);
/* draw a solid colour box in a textual layout (demo / later DMA) */
void tft_fill_region(unsigned x0, unsigned y0, unsigned x1, unsigned y1);

/* --- doomgeneric bindings (contract the port must satisfy) --- */
void DG_Init(void);
void DG_Shutdown(void);
void DG_DrawFrame(void);                 /* copy screen buffer -> display */
void DG_SetWindowTitle(const char *title);
void DG_SetQuitHandler(void (*quit)(void));
int  DG_GetKey(int *pressed, unsigned char *key);
void DG_SleepMs(uint32_t s);
uint32_t DG_GetTicksMs(void);

extern unsigned char DG_ScreenBuffer[320 * 8]; /* scratch strip (see platform.c) */

/* placement: 320x200 -> registers the "screens" pointer */
void hw_screen_setup(void);

#endif