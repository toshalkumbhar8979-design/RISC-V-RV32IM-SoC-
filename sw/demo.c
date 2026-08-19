/*====================================================================
 * demo.c — Phase-3 C application for the riscv_doom_soc.
 * Exercises the toolchain/crt0/linker + hal: UART, mtime delay,
 * TFT byte pump, then writes the PASS mailbox and spins.
 * ====================================================================*/
#include "platform.h"
#include "sys_regs.h"

#define MAILBOX_ADDR   0x000101F4u   /* sram word 125 (matches tb_soc) */

int main(void) {
    uint32_t t0 = mtime_ticks();

    uart_puts("riscv doomsoc start\r\n");
    tft_reset();

    /* push a couple of command bytes + pixels through the TFT */
    tft_cmd_byte(0x28);
    tft_cmd_byte(0x2C);
    tft_data_byte(0xDE);
    tft_data_byte(0xAD);
    tft_data_byte(0xBE);
    tft_data_byte(0xEF);

    /* mtime must have advanced across the TFT pushes */
    uint32_t elapsed = mtime_ticks() - t0;
    *(volatile unsigned int *)0x101F0u = elapsed;   /* scratch: word 124 */

    /* prove the C binary ran: PASS mailbox */
    *(volatile unsigned int *)MAILBOX_ADDR = 0x600DF00Du;

    uart_puts("done\r\n");
    for (;;) ;
}