#====================================================================
# crt.S — bare-metal start-up for the riscv_doom_soc application.
#====================================================================
    .section .text.entry
    .globl _start
    .type _start, @function
_start:
    la  sp, __stack_bottom

#   zero .bss
    la  t0, __bss_start
    la  t1, __bss_end
1:  bgeu t0, t1, 2f
    sw  zero, 0(t0)
    addi t0, t0, 4
    j   1b
2:
    call main
    j   2b      # main should not return

    .size _start, .-_start