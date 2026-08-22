# media — waveform / screenshot images

Drop waveform and layout screenshots here as PNG and they render in the
root `README.md` Visuals section.

Naming (referenced from README):

- `waveform_soc.png`    — full SoC boot: QSPI flash → SRAM → app, UART/TFT/IRQ
- `waveform_smoke.png`  — core smoke: PC trace, IRQ, PASS mailbox
- `waveform_muldiv.png` — M-extension mul/div unit vectors

How to export from GTKWave:

1. `gtkwave sim/soc.vcd` (etc.)
2. Add the signals you want, zoom
3. File → **Write 2bit PNG** → save here as the matching name