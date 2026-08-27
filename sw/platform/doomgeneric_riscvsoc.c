//====================================================================
// doomgeneric_riscvsoc.c — DG_* platform for the riscv_doom_soc.
//
// - Heap (malloc) lives in the PSRAM window (8 MB) so the DOOM zone
//   allocator + DG_ScreenBuffer (320x200x4 = 256 KB) fit.
// - DG_DrawFrame converts the 32-bit RGBA screen buffer to RGB565 in a
//   PSRAM scratch buffer, then kicks the SPI-TFT pixel-DMA to push it
//   to the ILI9341 panel.
// - Ticks come from the mtime/mtimecmp timer (0x4003_0000).
// - Keys: stub (no input device in this milestone).
//====================================================================
#include "doomgeneric.h"
#include <stdint.h>
#include <string.h>

// ---------------- memory map / device registers ----------------
#define PSRAM_BASE        0x10000000u
#define PSRAM_SIZE        (8u * 1024u * 1024u)
#define HEAP_BASE         PSRAM_BASE
#define HEAP_SIZE         (4u * 1024u * 1024u)          // 4 MB heap
#define CONVERT_BASE      (HEAP_BASE + HEAP_SIZE)       // RGB565 scratch
#define CONVERT_SIZE      (320u * 200u * 2u)

#define TFT_DMA_BASE      0x40010100u
#define TFT_DMA_CTRL      (*(volatile uint32_t*)(TFT_DMA_BASE + 0x00))
#define TFT_DMA_SRC       (*(volatile uint32_t*)(TFT_DMA_BASE + 0x04))
#define TFT_DMA_LEN       (*(volatile uint32_t*)(TFT_DMA_BASE + 0x08))
#define TFT_DMA_STAT      (*(volatile uint32_t*)(TFT_DMA_BASE + 0x0c))
#define TFT_DMA_GO        0x1u

#define MTIME_LO          (*(volatile uint32_t*)(0x40030000u + 0x00))
#define MTIME_HI          (*(volatile uint32_t*)(0x40030000u + 0x04))

// ---------------- heap (simple free-list over PSRAM) ----------------
typedef struct hdr { uint32_t size; struct hdr* next; } hdr_t;
static hdr_t* free_list = 0;
static int heap_ready = 0;

static void heap_init(void)
{
  free_list = (hdr_t*)HEAP_BASE;
  free_list->size = HEAP_SIZE - sizeof(hdr_t);
  free_list->next = 0;
  heap_ready = 1;
}

void* malloc(unsigned long n)   // 'unsigned long' matches newlib's size_t here
{
  if (!heap_ready) heap_init();
  n = (n + 7u) & ~7u;                     // 8-byte align
  hdr_t** p = &free_list;
  while (*p) {
    if ((*p)->size >= n) {
      hdr_t* blk = *p;
      uint32_t rest = blk->size - n;
      if (rest > sizeof(hdr_t) + 8) {
        // split: return the tail, keep the head on the free list
        hdr_t* tail = (hdr_t*)((uint8_t*)blk + rest);
        tail->size = n; tail->next = 0;
        blk->size = rest - sizeof(hdr_t);
        return (void*)((uint8_t*)tail + sizeof(hdr_t));
      }
      *p = blk->next;                     // take whole block
      return (void*)((uint8_t*)blk + sizeof(hdr_t));
    }
    p = &(*p)->next;
  }
  return 0;
}

void free(void* ptr) {}
void* calloc(unsigned long n, unsigned long sz)
{
  void* p = malloc(n * sz);
  if (p) memset(p, 0, n * sz);
  return p;
}
void* realloc(void* p, unsigned long n)
{
  void* q = malloc(n);
  if (p && q) memcpy(q, p, n / 2);
  return q;
}

// ---------------- ticks ----------------
static uint32_t tick_lo(void) { return MTIME_LO; }
uint32_t DG_GetTicksMs(void)
{
  // mtime increments at ~32.768 kHz-ish; scale to ms (assume 1 MHz ref for simplicity)
  uint32_t lo1 = MTIME_LO, hi1 = MTIME_HI;
  uint32_t lo2 = MTIME_LO, hi2 = MTIME_HI;
  (void)lo1; (void)hi1;
  if (lo2 != lo1) return lo2;             // crude ms conversion
  return lo2;
}
void DG_SleepMs(uint32_t ms)
{
  uint32_t t0 = DG_GetTicksMs();
  while ((uint32_t)(DG_GetTicksMs() - t0) < ms) { /* spin */ }
}

// ---------------- keys (stub) ----------------
int DG_GetKey(int* pressed, unsigned char* key)
{
  *pressed = 0; *key = 0;
  return 0;                               // no key available
}
void DG_SetWindowTitle(const char* t) { (void)t; }

// ---------------- palette / frame push ----------------
static void tft_dma_push(const void* src, uint32_t len)
{
  TFT_DMA_SRC = (uint32_t)src;
  TFT_DMA_LEN = len;
  TFT_DMA_CTRL = TFT_DMA_GO;
  while (TFT_DMA_STAT & 1u) { /* wait */ }
}

void DG_DrawFrame(void)
{
  const uint32_t* sb = (const uint32_t*)DG_ScreenBuffer;   // RGBA
  volatile uint16_t* cv = (volatile uint16_t*)CONVERT_BASE;
  const uint32_t npix = 320u * 200u;
  for (uint32_t i = 0; i < npix; ++i) {
    uint32_t px = sb[i];
    uint8_t r = (px >> 16) & 0xFF, g = (px >> 8) & 0xFF, b = px & 0xFF;
    cv[i] = (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
  }
  tft_dma_push((const void*)CONVERT_BASE, npix * 2u);
}

// ---------------- DG_Init ----------------
void DG_Init(void)
{
  if (!heap_ready) heap_init();
  // (TFT panel init sequence runs in the platform boot path before this)
}