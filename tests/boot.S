#====================================================================
# boot.S — BootROM content, executed at reset (address 0).
# 1. Keep the UART honest with a 'B' byte.
# 2. Copy APR: 64 words from flash XIP window (0x1000_0000) to
#    SRAM (0x0001_0000).  The QSPI controller stalls the core per
#    load; this exercises the read path end to end.
# 3. Jump to 0x0001_0000.
#====================================================================
        .text
        .option norvc

        .globl _start
_start:
        # ---- UART greeting 'B' ----
        lui     a0, 0x40020              # 0x4002_0000
        li      a1, 'B'
        sw      a1, 0(a0)
        # ---- copy flash -> sram ----
        lui     t0, 0x10000            # flash XIP window
        lui     t1, 0x10               # SRAM 0x0001_0000
        li      t2, 0
1:
        lw      t3, 0(t0)              # flash word read (stalls on qspi)
        sw      t3, 0(t1)
        addi    t0, t0, 4
        addi    t1, t1, 4
        addi    t2, t2, 1
        li      t4, 512
        blt     t2, t4, 1b
        # UART 'J' and jump
        lui     a0, 0x40020
        li      a1, 'J'
        sw      a1, 0(a0)
        j       0x10000