#include "platform.h"
#include "sys_regs.h"

#define PSRAM_FB ((volatile uint8_t*)0x10000000u)
unsigned char *DG_ScreenBuffer = (unsigned char*)PSRAM_FB;

static unsigned short doom_pal[256];

static void build_palette(void) {
    for (int i = 0; i < 256; i++) {
        int r = (i < 128) ? (i * 2) : 255;
        int g = (i < 128) ? (i * 2) : (255 - (i-128)*2);
        int b = (i < 128) ? 128 : 255;
        doom_pal[i] = (unsigned short)(((r>>3)<<11) | ((g>>2)<<5) | (b>>3));
    }
}

static void tft_cmd(uint8_t c) { TFT_CTRL=1u; TFT_DATW=c; while(TFT_STAT&1u); }
static void tft_dat(uint8_t d) { TFT_CTRL=3u; TFT_DATW=d; while(TFT_STAT&1u); }
static void tft_rst(void) { TFT_CTRL=0u; delay_ms(5); TFT_CTRL=1u; delay_ms(5); }

static void tft_init(void) {
    tft_rst();
    tft_cmd(0x01); delay_ms(5);
    tft_cmd(0x28);
    tft_cmd(0xCF); tft_dat(0); tft_dat(0xC1); tft_dat(0x30);
    tft_cmd(0xE8); tft_dat(0x85); tft_dat(0); tft_dat(0x78);
    tft_cmd(0xCB); tft_dat(0x39); tft_dat(0x2C); tft_dat(0); tft_dat(0x34); tft_dat(2);
    tft_cmd(0xF7); tft_dat(0x20);
    tft_cmd(0xEA); tft_dat(0); tft_dat(0);
    tft_cmd(0xC0); tft_dat(0x23);
    tft_cmd(0xC1); tft_dat(0x10);
    tft_cmd(0xC5); tft_dat(0x3E); tft_dat(0x28);
    tft_cmd(0xC7); tft_dat(0x86);
    tft_cmd(0x36); tft_dat(0x48);
    tft_cmd(0x3A); tft_dat(0x55);
    tft_cmd(0xB1); tft_dat(0); tft_dat(0x18);
    tft_cmd(0xB6); tft_dat(0x08); tft_dat(0x82); tft_dat(0x27);
    tft_cmd(0x11); delay_ms(120);
    tft_cmd(0x29); delay_ms(20);
}

static void tft_window(void) {
    tft_cmd(0x2A); tft_dat(0); tft_dat(0); tft_dat(0); tft_dat(239);
    tft_cmd(0x2B); tft_dat(0); tft_dat(0); tft_dat(0); tft_dat(319);
    tft_cmd(0x2C);
}

void uart_putc(char c) { while(UART_STAT&1u); UART_TDATA=(unsigned char)c; }
void uart_puts(const char *s) { while(*s) uart_putc(*s++); }
uint32_t mtime_ticks(void) { return MTIME_LO; }
uint32_t millis(void) { return mtime_ticks()/390u; }
void delay_ms(unsigned ms) { uint32_t t=millis(); while((millis()-t)<ms); }
static void tft_wait(void) { while(TFT_STAT&1u); }
void tft_cmd_byte(uint8_t b) { tft_cmd(b); }
void tft_data_byte(uint8_t b) { tft_dat(b); }
void tft_reset(void) { tft_rst(); }
void doom_load_palette(void) { build_palette(); }

void DG_Init(void) { build_palette(); tft_init(); tft_window(); }
void DG_DrawFrame(void) {
    tft_window();
    const uint8_t *fb = (const uint8_t*)PSRAM_FB;
    for (uint32_t i = 0; i < 320u*200u; i++) {
        unsigned short rgb = doom_pal[fb[i]];
        tft_dat((uint8_t)(rgb>>8));
        tft_dat((uint8_t)(rgb&0xFF));
    }
}
void DG_SetWindowTitle(const char *t) { (void)t; }
void DG_SetQuitHandler(void (*q)(void)) { (void)q; }
int DG_GetKey(int *pressed, unsigned char *key) { (void)pressed; (void)key; return 0; }
void DG_SleepMs(uint32_t s) { delay_ms(s); }
uint32_t DG_GetTicksMs(void) { return millis(); }
void hw_screen_setup(void) { }