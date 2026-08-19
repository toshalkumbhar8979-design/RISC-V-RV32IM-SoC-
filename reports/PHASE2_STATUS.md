# Phase 2 — Status Report (Minimal SoC Integration)

**Date:** 2026 · **State:** IN PROGRESS — all RTL built and compiling; one verification
gate (SoC end-to-end) is blocked by a behavioral-model re-sync artifact, precisely described
below. This is an honest partial; nothing is claimed as passing that does not.

## What was built (all compiles clean with `iverilog -g2005`)

| Block | File | Status |
|---|---|---|
| SoC top + address decode + bus | `rtl/soc/riscv_soc.v` | compiles; SRAM base-relative indexing fixed |
| Boot ROM (logic, AW=12) | `rtl/soc/bootrom.v` | compiles; loads `sim/bootrom.hex` |
| SRAM wrapper (32 KB) | `rtl/soc/sram_wrap.v` | compiles (removed an out-of-range index bug) |
| QSPI flash XIP engine | `rtl/periph/qspi_ctrl.v` | compiles; **read data verified on one transaction** |
| SPI-TFT (ILI9341) ctrl | `rtl/periph/spi_tft.v` | compiles |
| UART (8N1 TX) | `rtl/periph/uart_lite.v` | compiles |
| Timer mtime/mtimecmp | `rtl/periph/timer.v` | compiles (bit-exact mstatus already done in P1) |
| Boot loader | `tests/boot.S` → 17 words | assembles |
| App (TFT pattern + timer IRQ + PASS) | `tests/app.S` | assembles, linked at 0x10000 |
| SoC testbench | `tb/tb_soc.v` | exists, needs final model fix |
| QSPI unit test | `tb/_tb_qspi.v` | **one read PASS**, multi-read re-sync OPEN |

## Verified (evidence)
- Full RTL list compiles with zero errors (`iverilog -g2005 ...`), only the expected
  width-pruning warnings.
- **QSPI engine — word integrity on a single transaction is proven**:
  `word @0 = faced00d OK` (golden fill byte{0D,00,CE,FA} → word 0xFACED00D).
- Phase-1 core still PASSES (`RESULT: PASS mailbox=0x600df00d ...`).

## Hard blocker / scope change (stated plainly)
- **Blocked:** SoC end-to-end test (boot copy → display pattern → timer IRQ → PASS).
  The QSPI **behavioral SPI-flash model** fails to re-synchronize after the first
  transaction: read #0 returns exact data, reads #1.. return residuals (e.g.
  `0x7D676807`). All root causes found during debugging were model-end (byte residue,
  endianness, bit-order); the ENGINE was shown correct (golden word intact). I did not
  achieve the final model re-arm fix within this session and will not claim a passing
  end-to-end test.

## Next actions (concrete)
1. Re-arm the model's parse/drive state on the `dq = cs` rising edge after EACH
   transaction (currently relies on one CS-high cycle inside IDLE).
2. Re-run `QSPI UNIT TEST` → expect 4 reads OK, then re-run `SOC TEST` for a full PASS.
3. Then: commit Phase 2 as complete and proceed to Phase 3 (toolchain/doomgeneric).