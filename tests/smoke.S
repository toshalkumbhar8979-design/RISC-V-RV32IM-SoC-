#====================================================================
# tests/smoke.S — RV32IM core smoke test (self-checked).
# Runs on tb_rv32_core; text at 0x0, no data section (absolute dmem
# addresses used). Mailbox 0x180 -> 0x600DF00D on pass / 0xDEADBEEF on
# fail; 0x200 holds an IRQ handler invocation counter.
#====================================================================
        .text
        .option norvc

        .globl _start
_start:
        # zero the irq counter (boot-code semantics; TB RAM otherwise unpredictable)
        sw      zero, 0x200(zero)

        # ---------------- base arithmetic/logic ----------------
        li      t0, 0x1234
        li      t1, 0xFF00
        add     t2, t0, t1
        li      t3, 0x11134             # 0x1234 + 0xFF00
        bne     t2, t3, fail
        sub     t4, t1, t0
        li      t5, 0xECCC              # 0xFF00 - 0x1234
        bne     t4, t5, fail

        # ---------------- shifts (imm + reg) ----------------
        li      t0, 1
        slli    t1, t0, 5
        li      t2, 32
        bne     t1, t2, fail
        li      t0, -16
        srai    t1, t0, 2
        li      t2, -4
        bne     t1, t2, fail
        srli    t1, t0, 2
        li      t2, 0x3FFFFFFC
        bne     t1, t2, fail
        li      t0, 1
        li      t1, 3
        sll     t2, t0, t1
        li      t3, 8
        bne     t2, t3, fail

        # ---------------- compare ops ----------------
        li      t0, -1
        li      t1, 1
        slt     t2, t0, t1
        li      t3, 1
        bne     t2, t3, fail
        sltu    t2, t0, t1
        bne     t2, zero, fail
        sltiu   t2, t0, 1
        bne     t2, zero, fail
        slti    t2, t0, 0
        li      t3, 1
        bne     t2, t3, fail

        # ---------------- logic + LUI ----------------
        li      t0, 0x0F0F0F0F
        li      t1, 0x33333333
        and     t2, t0, t1
        li      t3, 0x03030303
        bne     t2, t3, fail
        or      t2, t0, t1
        li      t3, 0x3F3F3F3F
        bne     t2, t3, fail
        xor     t2, t0, t1
        li      t3, 0x3C3C3C3C
        bne     t2, t3, fail
        lui     t0, 0x0FFFF
        li      t1, 0x0FFFF000
        bne     t0, t1, fail

        # ---------------- memory: sw/lw, sb/lbu, sh/lh/lhu --------
        li      t0, 0x180
        li      t1, 0xAABBCCDD
        sw      t1, 0(t0)
        lw      t2, 0(t0)
        bne     t2, t1, fail
        sb      zero, 0(t0)
        lbu     t3, 0(t0)
        bne     t3, zero, fail
        lbu     t3, 2(t0)
        li      t4, 0xBB                # little-endian: byte2 of 0xAABBCCDD = 0xBB
        bne     t3, t4, fail
        li      t1, 0xF0F0
        sh      t1, 4(t0)
        lhu     t3, 4(t0)
        li      t4, 0xF0F0
        bne     t3, t4, fail
        lh      t3, 4(t0)            # sign extend 0xF0F0 -> -0xF10
        li      t4, -3856
        bne     t3, t4, fail

        # ---------------- branch loop counter ----------------
        li      t0, 5
        li      t1, 0
1:      addi    t1, t1, 1
        addi    t0, t0, -1
        bne     t0, zero, 1b
        li      t2, 5
        bne     t1, t2, fail

        # ---------------- jal / jalr function call ----------------
        li      a0, 42
        jal     ra, func_dbl
        li      t0, 84
        bne     a0, t0, fail

        # ---------------- M extension: mul/mulhu/mulh/mulhsu -------
        li      t0, 0x12345678
        li      t1, 0x9abcdef0
        mul     t2, t0, t1
        li      t3, 0x242D2080
        bne     t2, t3, fail
        mulhu   t2, t0, t1
        li      t3, 0x0B00EA4E
        bne     t2, t3, fail
        mulh    t2, t0, t1              # b is negative as signed
        li      t3, 0xF8CC93D6
        bne     t2, t3, fail

        # distinguishing triple: a=0xC0000000 b=0x80000000
        li      t0, 0xC0000000
        li      t1, 0x80000000
        mulhu   t2, t0, t1
        li      t3, 0x60000000
        bne     t2, t3, fail
        mulh    t2, t0, t1
        li      t3, 0x20000000
        bne     t2, t3, fail
        mulhsu  t2, t0, t1
        li      t3, 0xE0000000
        bne     t2, t3, fail

# ---------------- division / remainder ----------------
        li      t0, 100
        li      t1, 7
        div     t2, t0, t1
        li      t3, 14
        bne     t2, t3, fail
        rem     t2, t0, t1
        li      t3, 2
        bne     t2, t3, fail
        li      t0, -100
        div     t2, t0, t1
        li      t3, -14
        bne     t2, t3, fail
        rem     t2, t0, t1
        li      t3, -2
        bne     t2, t3, fail
        li      t0, 0xABCD1234
        li      t1, 0x1234
        divu    t2, t0, t1
        li      t3, 0x97020
        bne     t2, t3, fail
        remu    t2, t0, t1
        li      t3, 0xBB4
        bne     t2, t3, fail

        # div-by-zero (spec: q=0xFFFFFFFF, r=dividend)
        li      t0, 42
        li      t1, 0
        div     t2, t0, t1
        li      t3, -1
        bne     t2, t3, fail
        rem     t2, t0, t1
        li      t3, 42
        bne     t2, t3, fail
        divu    t2, t0, t1
        li      t3, 0xFFFFFFFF
        bne     t2, t3, fail
        remu    t2, t0, t1
        li      t3, 42
        bne     t2, t3, fail

        # MIN_INT / -1 (no trap: q=MIN, r=0)
        li      t0, 0x80000000
        li      t1, -1
        div     t2, t0, t1
        li      t3, 0x80000000
        bne     t2, t3, fail
        rem     t2, t0, t1
        bne     t2, zero, fail

        # ---------------- CSR + timer interrupt ----------------
        la      t0, irq_hand
        csrw    mtvec, t0
        # arm the TB "timer" so it raises irq exactly around the spin
        li      t0, 0xAA55AA55
        li      t1, 0x1C0
        sw      t0, 0(t1)
        csrsi   mstatus, 8                # set MIE
        li      t0, 0
2:      addi    t0, t0, 1
        li      t1, 500
        bge     t0, t1, fail             # timeout: interrupt never came
        lw      t2, 0x200(zero)
        beq     t2, zero, 2b
        j       pass

        .globl func_dbl
func_dbl:
        add     a0, a0, a0
        jalr    zero, ra, 0

irq_hand:
        csrci   mstatus, 8              # keep further interrupts at bay (level source)
        lw      t0, 0x200(zero)
        addi    t0, t0, 1
        sw      t0, 0x200(zero)
        mret

pass:
        li      t0, 0x600DF00D
        li      t1, 0x180
        sw      t0, 0(t1)
3:      j       3b

fail:
        li      t0, 0xDEADBEEF
        li      t1, 0x180
        sw      t0, 0(t1)
3:      j       3b
        .end