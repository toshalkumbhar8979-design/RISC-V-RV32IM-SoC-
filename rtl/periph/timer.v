//====================================================================
// timer.v — machine timer (mtime / mtimecmp) for the SoC.
// Memory map (base 0x4003_0000):
//   +0x00 MTIME_LO, +0x04 MTIME_HI, +0x08 MTIMECMP_LO, +0x0C MTIMECMP_HI,
//   +0x10 CTRL (bit0 = tick enable)
// IRQ = (mtime >= mtimecmp) && en
//====================================================================
`timescale 1ns/1ps
module rv32_timer_periph #(
  parameter [3:0] SCALE = 4'd8          // 1 tick per 2^SCALE clocks
)(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        cwe,
  input  wire        crd,              // selected read strobe
  input  wire [4:0]  addr,             // low 5 bits of bus offset
  input  wire [31:0] wdata,
  output wire [31:0] rdata,
  output wire        irq
);

  reg [SCALE-1:0] tick;
  reg [63:0] mtime;
  reg [63:0] mtimecmp;
  reg        en;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick     <= {SCALE{1'b0}};
      mtime    <= 64'h0;
      mtimecmp <= ~64'h0;
      en       <= 1'b1;
    end else begin
      if (&tick) begin
        tick  <= {SCALE{1'b0}};
        mtime <= mtime + 64'h1;
      end else begin
        tick <= tick + 1'b1;
      end
      if (cwe) begin
        case (addr[4:0])
          5'h08: mtimecmp[31:0]  <= wdata;
          5'h0C: mtimecmp[63:32] <= wdata;
          5'h00: mtime[31:0]     <= wdata;
          5'h04: mtime[63:32]    <= wdata;
          5'h10: en <= wdata[0];
          default: ;
        endcase
      end
    end
  end

  reg [31:0] rd;
  always @(*) begin
    rd = 32'h0;
    if (crd) begin
      case (addr[4:0])
       5'h00: rd = mtime[31:0];
       5'h04: rd = mtime[63:32];
       5'h08: rd = mtimecmp[31:0];
       5'h0C: rd = mtimecmp[63:32];
       5'h10: rd = {31'h0, en};
       default: rd = 32'h0;
      endcase
    end
  end
  assign rdata = rd;

  assign irq = en && (mtime >= mtimecmp);

endmodule