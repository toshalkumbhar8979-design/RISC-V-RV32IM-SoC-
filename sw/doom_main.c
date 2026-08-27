// doom_main.c — DOOM engine entry point for riscv_doom_soc.
// Calls doomgeneric_Create() which runs D_DoomMain() internally.
// After setup, loops doomgeneric_Tick() forever.
#include "doomgeneric.h"

int main(int argc, char **argv)
{
    (void)argc; (void)argv;
    doomgeneric_Create(0, 0);
    for (;;)
        doomgeneric_Tick();
    return 0;
}