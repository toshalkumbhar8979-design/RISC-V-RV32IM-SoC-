# Phase 1 — Status Report (RV32IM Core)

**Date:** 2026-08-18 · **State:** COMPLETE — all gate criteria met.

## What was built
RV32IM core, Verilog-2001, Yosys-synthesizable, one module per file (`rtl/rv32/`):

| File | Role |
|---|---|
| `rv32_core.v` | 2-stage pipeline (fetch + single-cycle EX/WB), prefetch depth 1, IRQ on instruction boundary, CSR + trap + mret |
| `rv32_decoder.v` | full RV32I/M decode |
| `rv32_alu.v` | 32-bit ALU + branch comparators |
| `rv32_regfile.v` | 32×32, 2R/1W, x0 hard-wired |
| `rv32_immgen.v` | B/I/S/U/J/Z immediates |
| `rv32_muldiv.v` | multicycle M engine (shift-add mul ~36 cyc; restoring div ~36 cyc; f3 encoding) |
| `rv32_csr.v` | mstatus/mepc/mcause/mtvec + trap/mret state transitions |

Microarchitecture decisions (documented rationale in the file headers):
- 2-stage design chosen over 5-stage: single hazard point, easier to reason about, still ≈1 IPC
  straight-line; M-extension multi-cycle (34–36 cy) keeps timing closure realistic.
- `irq_tmr` level input; traps taken exactly at instruction boundaries; `mret` restores MIE/MPIE;
  exceptions (ecall/ebreak/illegal/misaligned) with spec causes.

## Verification (self-checking tests, all pass)
`tb/tb_muldiv.v` — M-unit unit test: 18 golden vectors (mul/mulh/mulhsu/mulhu, div/divu/rem/remu,
div-by-zero, MIN_INT/−1):

```
MULDIV UNIT TEST: PASS
```

`tb/tb_rv32.v` + `tests/smoke.S` — full core smoke:
```
RESULT: PASS   mailbox=0x600df00d irq_count=1 commits=1107
```
Covers: ADDI/SUB/SLT/SLTI(U)/XORI/ORI/ANDI/SLLI/SRLI/SRAI, reg-reg ops, shifts, lui, auipc,
branch suite, loop control, jal/jalr function call/return, sw/lw/sb/lbu/sh/lhu/lh endianness,
MUL/MULH/MULHSU/MULHU, DIV/DIVU/REM/REMU + spec edge cases, CSR mtvec/mstatus writes, timer IRQ
taken at an instruction boundary, handler runs once, mret resumes correctly.

## Verification commands (exact)

In WSL2 (Kali):
```
cd /mnt/c/Users/tosha/Downloads/RiscV
make run                                      # top Makefile → sim/Makefile
make -C sim waves                             # GTKWave on sim/smoke.vcd
```
Direct (equivalent): 
```
iverilog -g2005 -I rtl/rv32 -o /tmp/md.vvp rtl/rv32/rv32_muldiv.v tb/tb_muldiv.v && vvp /tmp/md.vvp
iverilog -g2005 -I rtl/rv32 -o sim/smoke.vvp -s tb_rv32_core \
    rtl/rv32/{rv32_core,rv32_decoder,rv32_alu,rv32_regfile,rv32_immgen,rv32_muldiv,rv32_csr}.v \
    tb/tb_rv32.v && (cd sim && vvp smoke.vvp)
```

Artifacts: `sim/smoke.vvp`, `sim/smoke.vcd`, `sim/smoke_pc.trace`, `tests/smoke.hex` (196/ux words).

## GTKWave signal list
```
tb_rv32_core.uut.ins_pc      tb_rv32_core.uut.ins
tb_rv32_core.uut.fetch_pc    tb_rv32_core.uut.ins_v
tb_rv32_core.uut.imem_valid  tb_rv32_core.uut.dmem_valid
tb_rv32_core.uut.dmem_wstrb  tb_rv32_core.uut.dmem_we
tb_rv32_core.uut.u_md.*      tb_rv32_core.uut.u_csr.mstatus
irq  inst_commit  trap_active rv32_core.uut.all_stop
```

## Significant bugs found & fixed during this phase (honest log)
1. `rw: JAL/JALR link did not write pc+4` (wrote ALU garbage) — fixed the wb mux.
2. `rv32_muldiv`: original 3-bit MOP couldn't encode REMU (collision with REM); rewrote engine to
   consume raw funct3 and re-sequenced to IDLE/RUN/FIN/DONE so results settle before done.
3. `rv32_csr`: mstatus trap-snapshot concatenated the MIE-clear at the wrong bit index — a trap
   never disabled MIE (observable as an IRQ storm). Fixed with explicit bit placement; mret
   restore re-checked similarly.
4. Test-harness fixes: same-slot TB races (muldiv start pulse, done sample), stale make timestamps
   on /mnt/c, TB needing `-g2005` (SystemVerilog `join_none` removed), little-endian byte ordering
   mistakes in two expected test constants.

## Gates / next
- All Phase-1 gates met: RV32IM + M extension behavior verified in simulation with waveforms
  (smoke.vcd) and self-checking tests.
- Next: Phase 2 — bus + SoC integration; lock memory map and boot ROM; off-core IRQ lane wiring.