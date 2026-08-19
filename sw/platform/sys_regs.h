//====================================================================
// sys_regs.h — SoC register map (matches rtl/soc/riscv_soc.v).
//====================================================================
#ifndef SYS_REGS_H
#define SYS_REGS_H

// UART 0x4002_0000: +0 TDATA (W) +4 STAT (bit0 busy)
#define UART_BASE    0x40020000u
#define UART_TDATA   (*((volatile unsigned int*) (UART_BASE + 0x00)))
#define UART_STAT    (*((volatile unsigned int*) (UART_BASE + 0x04)))

// SPI-TFT 0x4001_0000: +0 CTRL(bit0 RST_N,bit1 DC,bit2 CS_N) +4 DATW +8 STAT
#define TFT_BASE     0x40010000u
#define TFT_CTRL     (*((volatile unsigned int*) (TFT_BASE + 0x00)))
#define TFT_DATW     (*((volatile unsigned int*) (TFT_BASE + 0x04)))
#define TFT_STAT     (*((volatile unsigned int*) (TFT_BASE + 0x08)))

// Timer 0x4003_0000: +0 MTIME_LO +4 MTIME_HI +8 MTIMECMP_LO +0xC MTIMECMP_HI
#define TIMER_BASE   0x40030000u
#define MTIME_LO     (*((volatile unsigned int*) (TIMER_BASE + 0x00)))
#define MTIME_HI     (*((volatile unsigned int*) (TIMER_BASE + 0x04)))
#define MTIMECMP_LO  (*((volatile unsigned int*) (TIMER_BASE + 0x08)))
#define MTIMECMP_HI  (*((volatile unsigned int*) (TIMER_BASE + 0x0C)))

// CPU control (machine CSRs)
#define MSTATUS_MIE (1u << 3)

#endif