// _tb_tft_dma.v — mini self-check for the pixel-DMA engine.
`timescale 1ns/1ps
module tb_tft_dma;
  reg clk=0, rst_n=0; always #5 clk=~clk;

  reg        cwe=0, crd=0;
  reg [7:0]  addr=0;
  reg [31:0] wdata=0;
  wire [31:0] rdata;
  wire [31:0] fb_addr;
  reg [31:0] fb_rdata=0;
  reg        fb_rdy=0;
  wire       fb_req;
  wire tft_dc, tft_cs_n, tft_sclk, tft_sdi, tft_busy;

  // tiny framebuffer: 4 bytes at 0x1000_0000..03
  reg [7:0] fbmem [0:3];
  initial begin
    fbmem[0] = 8'hDE; fbmem[1] = 8'hAD; fbmem[2] = 8'hBE; fbmem[3] = 8'hEF;
  end

  tft_dma u (
    .clk(clk), .rst_n(rst_n), .cwe(cwe), .crd(crd), .addr(addr), .wdata(wdata), .rdata(rdata),
    .fb_addr(fb_addr), .fb_rdata(fb_rdata), .fb_rdy(fb_rdy), .fb_req(fb_req),
    .tft_dc(tft_dc), .tft_cs_n(tft_cs_n), .tft_sclk(tft_sclk), .tft_sdi(tft_sdi),
    .tft_busy(tft_busy)
  );

  // framebuffer read model: when req and addr in range, present byte
  always @(*) fb_rdata = {24'h0, fbmem[fb_addr[1:0]]};
  always @(posedge clk) fb_rdy <= fb_req;

  integer cyc;
  reg [7:0] captured [0:3];
  integer nshift; reg [7:0] cur; integer didx=0; reg [2:0] curbit=0;
  reg sck_d=0, sck_r=0;
  always @(posedge clk) sck_d <= tft_sclk;
  always @(posedge clk) begin
    sck_r <= tft_sclk && !sck_d;          // rising edge of TFT sclk
    if (sck_r) begin
      if (curbit==0) cur <= 0;
      cur <= {cur[6:0], tft_sdi};
      curbit <= curbit+1;
      if (curbit==7) begin captured[didx] <= {cur[6:0], tft_sdi}; didx <= didx+1; end
    end
  end

  initial begin
    #10 rst_n=1;
    #10;
    // program: src=0x1000_0000, len=4, go
    addr=4'h4; cwe=1; wdata=32'h10000000; #10; cwe=0;
    addr=4'h8; cwe=1; wdata=32'h00000004; #10; cwe=0;
    addr=4'h0; cwe=1; wdata=32'h00000001; #10; cwe=0;
    #40;                       // let go latch + FSM enter
    // wait for busy to go low again
    for (cyc=0; cyc<2000 && u.tft_busy; cyc=cyc+1) #10;
    $display("busy ended at cyc %0d, captured=%02x %02x %02x %02x",
      cyc, captured[0], captured[1], captured[2], captured[3]);
    if (captured[0]==8'hDE && captured[1]==8'hAD && captured[2]==8'hBE && captured[3]==8'hEF)
      $display("TFT_DMA: OK");
    else
      $display("TFT_DMA: FAIL");
    $finish;
  end
endmodule