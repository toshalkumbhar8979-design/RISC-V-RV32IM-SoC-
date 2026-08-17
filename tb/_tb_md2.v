`timescale 1ns/1ps
`include "rv32_defs.vh"
module tb_md2;
  reg clk = 0, rst = 0, start = 0;
  reg [31:0] a = 32'h12345678, b = 32'h9abcdef0;
  reg [2:0] op = 3'b000;
  wire [31:0] res; wire done, busy;
  rv32_muldiv u(.clk(clk), .rst_n(rst), .start_i(start),
                .a_i(a), .b_i(b), .op_i(op),
                .res_o(res), .done_o(done), .busy_o(busy));

  always #5 clk = ~clk;

  task runop;
    begin : rb
      start = 1;
      #11;
      start = 0;
      // wait for done (bounded)
      while (u.done_o !== 1'b1) @(posedge clk);
      #1;
      $display("op=%0d res=%08X la_q=%b lb_q=%b acc=%h", op, u.res_o, u.la_q, u.lb_q, u.acc);
    end
  endtask

  initial begin
    #20 rst = 1;
    // op0 = MUL
    runop;
    // op2 = MULHU (same operands), expect 0x0B00EA4E
    op = 3'b011;
    runop;
    $finish;
  end
endmodule