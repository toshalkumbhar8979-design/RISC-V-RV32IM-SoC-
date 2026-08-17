`timescale 1ns/1ps
`include "rv32_defs.vh"
module tb_muldiv;

  reg clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  reg        start;
  reg  [31:0] a, b;
  reg  [2:0]  op;                    // funct3
  wire [31:0] res;
  wire        done, busy;

  rv32_muldiv uut (.clk(clk), .rst_n(rst_n), .start_i(start),
                   .a_i(a), .b_i(b), .op_i(op),
                   .res_o(res), .done_o(done), .busy_o(busy));

  integer errs = 0;
  reg [31:0] res_q;

  task run;
    begin : rb
      integer k;
      start = 1;
      #11;                 // hold >1 clock, so the engine samples it cleanly
      start = 0;
      for (k = 0; k < 200; k = k + 1) begin
        if (uut.done_o === 1'b1) begin
          #1;                    // res_o settles at the S_FIN->S_DONE edge
          res_q = uut.res_o;
          disable rb;
        end
        @(posedge clk);
      end
      $display("TIMEOUT st=%0d step=%0d", uut.st, uut.step);
      errs = errs + 1; res_q = 32'hEEEEEEEE;
    end
  endtask

  task chk(input [7:0] name, input [31:0] exp);
    begin
      if (res_q === exp) $display("PASS %s", name);
      else begin
        errs = errs + 1;
        $display("FAIL %s got=0x%08X exp=0x%08X", name, res_q, exp);
      end
    end
  endtask

  initial begin
    $dumpfile("muldiv.vcd");
    $dumpvars(0, tb_muldiv);
    #20 rst_n = 1;

    // multiply
    a = 32'h12345678; b = 32'h9abcdef0;
    op = 3'b000; run; chk("mul  ", 32'h242D2080);   // MUL
    op = 3'b011; run; chk("mulhu", 32'h0B00EA4E);   // MULHU
    op = 3'b001; run; chk("mulh ", 32'hF8CC93D6);   // MULH

    a = 32'hC0000000; b = 32'h80000000;
    op = 3'b011; run; chk("muhu2", 32'h60000000);   // MULHU
    op = 3'b001; run; chk("muh_2", 32'h20000000);   // MULH
    op = 3'b010; run; chk("mhsu2", 32'hE0000000);   // MULHSU

    // divide / remainder
    a = 32'hABCD1234; b = 32'h1234;
    op = 3'b101; run; chk("divu ", 32'h00097020);   // DIVU
    op = 3'b111; run; chk("remu ", 32'h00000BB4);   // REMU

    a = 100; b = 7;
    op = 3'b100; run; chk("div  ", 32'd14);          // DIV
    op = 3'b110; run; chk("rem  ", 32'd2);           // REM
    a = -100; b = 7;
    op = 3'b100; run; chk("divn ", 32'hFFFFFFF2);   // -14
    op = 3'b110; run; chk("remn ", 32'hFFFFFFFE);   // -2

    // div-by-zero + MIN/-1 overflow
    a = 42; b = 0;
    op = 3'b100; run; chk("div0 ", 32'hFFFFFFFF);
    op = 3'b110; run; chk("rem0 ", 32'd42);
    op = 3'b101; run; chk("divu0", 32'hFFFFFFFF);
    op = 3'b111; run; chk("remu0", 32'd42);

    a = 32'h80000000; b = 32'hFFFFFFFF;
    op = 3'b100; run; chk("min1 ", 32'h80000000);
    op = 3'b110; run; chk("minr ", 32'h0);

    $display("============================================");
    if (errs == 0) $display("MULDIV UNIT TEST: PASS");
    else           $display("MULDIV UNIT TEST: FAIL (%0d)", errs);
    $finish;
  end

endmodule