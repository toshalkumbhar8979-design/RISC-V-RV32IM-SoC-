//====================================================================
// rv32_regfile.v — 32x32-bit register file, 2 async-read / 1 sync-write.
// Write on posedge; async-clear on reset (sim determinism + synthesis
// via reset muxes — acceptable at 32 words).
// x0 is hard-wired to zero.
//====================================================================
module rv32_regfile #(
    parameter DATA_W = 32
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 we,
    input  wire [4:0]           waddr,
    input  wire [DATA_W-1:0]    wdata,
    input  wire [4:0]           raddr1,
    output wire [DATA_W-1:0]    rdata1,
    input  wire [4:0]           raddr2,
    output wire [DATA_W-1:0]    rdata2
);

  reg [DATA_W-1:0] mem [0:31];

  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 32; i = i + 1)
        mem[i] <= {DATA_W{1'b0}};
    end else if (we && (waddr != 5'd0)) begin
      mem[waddr] <= wdata;
    end
  end

  assign rdata1 = (raddr1 == 5'd0) ? {DATA_W{1'b0}} : mem[raddr1];
  assign rdata2 = (raddr2 == 5'd0) ? {DATA_W{1'b0}} : mem[raddr2];

endmodule