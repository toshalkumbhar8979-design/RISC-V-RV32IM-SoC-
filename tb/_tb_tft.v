`timescale 1ns/1ps
module tb_tft;
  reg clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  reg cwe = 0, crd = 0;
  reg [3:0] addr = 0;
  reg [31:0] wd = 0;
  wire [31:0] rd;
  wire rst, dc, csn, sck, sdi;

  spi_tft u(.clk(clk), .rst_n(rst_n),
    .cwe(cwe), .crd(crd), .addr(addr), .wdata(wd), .rdata(rd),
    .tft_rst_n(rst), .tft_dc(dc), .tft_cs_n(csn),
    .tft_sclk(sck), .tft_sdi(sdi));

  reg  sckd;
  reg  [7:0] bt;
  reg  [2:0] bitn;
  integer bytes = 0;

  always @(posedge clk) begin
    sckd <= sck;
    if (csn == 0) begin
      if (sck && !sckd) begin
        bt <= {bt[6:0], sdi};
        bitn <= bitn + 1;
        if (bitn == 3'd7) begin
          $display("TFT byte dc=%b %02x", dc, {bt[6:0], sdi});
          bytes <= bytes + 1;
          bitn <= 0;
        end
      end
    end
  end

always @(posedge clk)
    if (u.busy)
      $display("B %0t sdiv=%0d bitn=%0d sck=%b csn=%b shift=%10b dc=%b",
               $time, u.sdiv, u.bitno, sck, csn, u.shift, dc);
  task wrB(input [7:0] b);
    begin
      addr <= 4; wd <= {24'h0, b}; cwe <= 1;
      @(posedge clk);
      cwe <= 0; wd <= 0;
      repeat(140) @(posedge clk);   // wait for the 32-clk transfer
    end
  endtask

  integer i;
  initial begin
    #20 rst_n = 1;
    // CTRL: rst=0
    addr <= 0; wd <= 0; cwe <= 1; @(posedge clk); cwe <= 0;
    // CTRL: rst=1
    addr <= 0; wd <= 1; cwe <= 1; @(posedge clk); cwe <= 0;
    // CTRL: rst=1 dc=0 cs=0
    addr <= 0; wd <= 5; cwe <= 1; @(posedge clk); cwe <= 0;
    // two command bytes + one data byte with waits
    wrB(8'h28);
    wrB(8'h2C);
    addr <= 0; wd <= 3; cwe <= 1; @(posedge clk); cwe <= 0;   // dc=1
    wrB(8'hDE);
    $display("captured %0d bytes", bytes);
    $finish;
  end
endmodule