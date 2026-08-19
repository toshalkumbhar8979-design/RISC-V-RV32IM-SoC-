/*====================================================================
 * platform.c — small hardware abstraction layer for riscv_doom_soc.
 *   UART helpers, mtime-based millis, TFT byte pump, and the
 *   doomgeneric binding entry points (screen buffer + ticks).
 * ====================================================================*/
#include "platform.h"
#include "sys_regs.h"

/* The real doom 320x200 (64 KB) render target lives in external PSRAM
   once the PSRAM window is added (Phase 4). On-die SRAM holds only a
   scratch strip for this milestone. DG_DrawFrame will then push the
   PSRAM-resident spans through the TFT pixel DMA. */
unsigned char DG_ScreenBuffer[320 * 8];   // ~2.5 KB scratch

/* ---------------- UART ---------------- */
void uart_putc(char c) {
    while (UART_STAT & 1u) ;          /* wait TX idle */
    UART_TDATA = (unsigned char)c;
}
void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

/* ---------------- timer / delays ---------------- */
uint32_t mtime_ticks(void)  { return MTIME_LO; }

uint32_t millis(void) {
    /* mtime counts every 2^SCALE(=8) sysclk; at 100 MHz sysclk that is
       1 tick = 2.56 us => ~390 ticks/ms. */
    return mtime_ticks() / 390u;
}

void delay_ms(unsigned ms) {
    uint32_t t = millis();
    while ((millis() - t) < ms) ;
}

/* ---------------- TFT (ILI9341-style) ---------------- */
static inline void tft_wait(void) {
    while (TFT_STAT & 1u) ;
}
void tft_cmd_byte(uint8_t b) {
    TFT_CTRL = 1u;                 /* rst=1 dc=0 cs=0 */
    TFT_DATW = b;
    TFT_CTRL = 1u;
    tft_wait();
}
void tft_data_byte(uint8_t b) {
    TFT_CTRL = 3u;                   /* rst=1 dc=1 cs=0 */
    TFT_DATW = b;
    TFT_CTRL = 3u;
    tft_wait();
}
void tft_reset(void) {
    TFT_CTRL = 0u;
    delay_ms(1);
    TFT_CTRL = 1u;
    delay_ms(1);
}

/* ---------------- doomgeneric contract ----------------
 * These are the hooks doom helps back-end; the port layer will fill
 * them once doomgeneric is integrated (Phase 3 pull-in). For now they
 * give the build + a minimal self-check demo something to link.      */
void DG_Init(void) { }
void DG_Shutdown(void) { }
void DG_DrawFrame(void) {
    /* transfer the 8-bit screen to the panel via a palette pass:
       for Phase-3 we push each line pair as RGB565 forming a blur  —
       real DMA lands in Phase 4; kept as a compile-time reference. */
    tft_cmd_byte(0x2C);             /* memory write command */
    int i;
    for (i = 0; i < 8 * 4; i++)     /* sample a few pixels */
        tft_data_byte(DG_ScreenBuffer[i]);
}
void DG_SetWindowTitle(const char *title) { (void)title; }
void DG_SetQuitHandler(void (*q)(void))   { (void)q; }
int  DG_GetKey(int *pressed, unsigned char *key) { (void)pressed; (void)key; return 0; }
void DG_SleepMs(uint32_t s) { delay_ms(s); }
uint32_t DG_GetTicksMs(void) { return millis(); }

void hw_screen_setup(void) {
    /* nothing extra: DG_ScreenBuffer is in .bss (zeroed) */
}