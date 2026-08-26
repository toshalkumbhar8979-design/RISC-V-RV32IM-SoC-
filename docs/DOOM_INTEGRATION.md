# DOOM Integration Scaffold — how to get the engine rendering

**Status: the hardware it needs is now IN the SoC (PSRAM window `0x1000_0000`
+ SPI-TFT pixel-DMA). The engine (vendored `sw/doomgeneric`) still needs the
software glue in this scaffold. No fake "runs DOOM" claim — this is the exact
to-do list.**

## Hardware that now exists (verified)
| Piece | RTL | Verified |
|---|---|---|
| PSRAM window 8 MB @ 0x1000_0000 | `rtl/soc/riscv_soc.v` (CS1) | SOC TEST: PASS |
| SPI-TFT (ILI9341) controller | `rtl/periph/spi_tft.v` | SOC TEST: PASS |
| **SPI-TFT pixel-DMA** (fb→panel) | `rtl/periph/tft_dma.v` | TFT_DMA: OK |

## Software to add (the actual remaining work — pure SW, no RTL)
1. **Framebuffer in PSRAM**: `doomgeneric` renders to a 320×200×8-bit
   `DG_ScreenBuffer`. Point it at `0x1000_0000` (PSRAM window).
   ```c
   #define DG_SCREENBUFFER ((uint8_t*)0x10000000)
   ```
2. **DG_* bindings** (in `sw/platform/platform.c`):
   - `DG_DrawFrame()` → for each dirty span, write to
     `((volatile uint32_t*)0x40010100)`: set SRC, LEN, GO; poll STAT.
   - `DG_Init()`/`DG_Exit()`, `DG_GetTicksMs()` (mtime), `DG_GetKey`, UART
     helpers — as in the Phase-3 HAL already present.
   - The TFT needs ILI9341 init (already done in `demo.c` path) then we push
     framebuffer bytes in `MADCTL` RGB order.
3. **Math/stdio stubs**: doomgeneric needs `libc`-less `sin/cos/rand`,
   `memcpy/memset` (freestanding compiler) — add `sw/platform/stubs.c`.
4. **Build**: `sw/Makefile` compiles engine sources (exclude platform-specific
   `i_video/doomgeneric_x11.c` etc), links with `-march=rv32im_zicsr
   -mabi=ilp32`, outputs `sw/build/app.bin` → flash hex → SoC/FPGA bench.
5. **WAD**: place a shareware `doom1.wad` in the flash image (or PSRAM) via
   `tests/app.S`-style copy.

## Testbench / FPGA validation path
- Sim: extend `tb/tb_soc.v`-style with a `tft_dma` push and assert DE AD BE EF
  marker (already proven at the DMA level).
- FPGA (board pending): boot → UART banner → display a static frame from
  PSRAM → then animated Doom at measured fps.

## Files
- `rtl/periph/tft_dma.v` (committed)
- `sw/platform/platform.c/.h` (Phase-3, extend with DG_ScreenBuffer/DMA)
- `docs/DOOM_INTEGRATION.md` (this file)