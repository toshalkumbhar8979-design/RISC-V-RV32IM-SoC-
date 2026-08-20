//====================================================================
// bootrom.v — synthesized code ROM (comb read, Yosys-friendly).
// Content comes from a .hex word file (bytecode assembled with the
// riscv64-unknown-elf toolchain and post-processed by bin2hex.py).
//====================================================================
module bootrom #(
  parameter integer AW = 8              // 256 words → 1 KB
)(
  input  wire [AW-1:0]    addr,
  output wire [31:0]      rdata
);

  reg [31:0] rom [0:(1<<AW)-1];
  // file lives next to the simulator's CWD (sim/)
  initial $readmemh("bootrom.hex", rom);

  assign rdata = rom[addr];

endmodule