#====================================================================
# app.S — application copied by the bootloader into SRAM@0x0001_0000.
# 1. UART 'A' (alive)
# 2. Push a test pattern through the SPI-TFT (ILI9341) controller
# 3. Arm the machine timer, enable MIE, wait for one IRQ; handler
#    increments the counter at 0x0001_0040
# 4. Write PASS mailbox at 0x0001_0080, spin forever
#====================================================================
        .section .text
        .option norvc
        .globl _start
_start:
        # ---- UART alive ----
        lui     a0, 0x40020
        li      a1, 'A'
        sw      a1, 0(a0)

        # ---- SPI TFT: pattern DE AD BE EF ----
        lui     t2, 0x40010            # 0x4001_0000
        # ctrl reg: reset active
        li      t3, 0
        sw      t3, 0(t2)
        li      t3, 1                  # rst high
        sw      t3, 0(t2)
        li      t3, 5                  # rst=1 dc=0 csn=0
        sw      t3, 0(t2)
        # command 0x28 (display off) - dc=0
        li      t4, 0x28
        sw      t4, 4(t2)
        li      t4, 0x2C               # command write-memory-start
        sw      t4, 4(t2)
        # switch dc=1, keep cs low
        li      t3, 7                  # rst=1 dc=1 csn=0
        sw      t3, 0(t2)
        # push 4 data pixels, waiting for TX idle before each
        li      t4, 0xDE
        sw      t4, 4(t2)
7:      lw      t5, 8(t2)             # wait idle
        andi    t5, t5, 1
        bnez    t5, 7b
        li      t4, 0xAD
        sw      t4, 4(t2)
7:      lw      t5, 8(t2)
        andi    t5, t5, 1
        bnez    t5, 7b
        li      t4, 0xBE
        sw      t4, 4(t2)
7:      lw      t5, 8(t2)
        andi    t5, t5, 1
        bnez    t5, 7b
        li      t4, 0xEF
        sw      t4, 4(t2)
7:      lw      t5, 8(t2)
        andi    t5, t5, 1
        bnez    t5, 7b
        # cs high again
        li      t3, 5
        sw      t3, 0(t2)

        # ---- timer ----
        lui     t0, 0x40030            # 0x4003_0000
        lw      t1, 0(t0)              # mtime lo
        addi    t1, t1, 3              # fire soon after a few ticks
        sw      t1, 8(t0)              # mtimecmp lo
        sw      zero, 12(t0)           # mtimecmp hi = 0
        la      t2, irq_hand
        csrw    mtvec, t2
        li      s0, 0x10040
        sw      zero, 0(s0)
        csrsi   mstatus, 8             # MIE = 1

        # ---- wait for the interrupt ----
3:      lw      t3, 0(s0)
        li      t4, 1
        bne     t3, t4, 3b

        # ---- PASS ----
        li      t5, 0x600DF00D
        li      t6, 0x10080
        sw      t5, 0(t6)
4:      j       4b

irq_hand:
        csrci   mstatus, 8
        li      s0, 0x10040
        lw      t3, 0(s0)
        addi    t3, t3, 1
        sw      t3, 0(s0)
        mret