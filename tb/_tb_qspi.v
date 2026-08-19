`timescale 1ns/1ps
// tb_qspi — isolated qspi engine vs a deterministic SPI-flash model.
// The flash model parses the engine's command/addr stream on SCLK
// rising edges and then answers with MISO driven directly from the
// engine's own receive-phase state (phase-locked, no edge guessing).
module tb_qspi;

  reg clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  reg [31:0] a = 0; reg req = 0;
  wire [31:0] rd; wire rdy;
  wire cs, sclk, mosi, miso;

  qspi_ctrl uq (.clk(clk), .rst_n(rst_n),
    .x_addr_i(a), .x_req_i(req), .x_rdata_o(rd), .x_rdy_o(rdy),
    .x_busy_o(busyw), .q_cs_n(cs), .q_sclk(sclk), .q_mosi(mosi), .q_miso(miso),
    .dbg_rxbit_o(rxbit_db), .dbg_rxact_o(rxact_db));

  wire [4:0] rxbit_db;
  wire       rxact_db;

  // ---------------- flash model ----------------
  reg [7:0]  fv [0:1023];
  reg        sckd;
  reg [7:0]  srin;
  reg [2:0]  bitin;
  reg [3:0]  binc;
  reg [23:0] had;
  reg [31:0] doutv;
  wire [7:0] curb = {srin[6:0], mosi};

  // MISO: answer from the model's latched word, bit 31..0 in order
  assign miso = rxact_db ?
           fv[had + rxbit_db[4:3]][7 - rxbit_db[2:0]] : 1'b1;

  always @(posedge clk) begin
    sckd <= sclk;
    if (cs) begin
      bitin <= 0; binc <= 0; fmiso_leave <= 1'b1;
    end else begin
      if (!sckd && sclk) begin
        srin <= {srin[6:0], mosi};
        bitin <= bitin + 1'b1;
        if (bitin == 3'd7) begin
          bitin <= 0;
          case (binc)
            0: ;                                       // opcode
            1: had[23:16] <= curb;
            2: had[15:8]  <= curb;
            3: begin
               had[7:0] <= curb;
               doutv <= {fv[{had[23:16], had[15:8], curb}+ 3'd3],
                         fv[{had[23:16], had[15:8], curb}+ 3'd2],
                         fv[{had[23:16], had[15:8], curb}+ 3'd1],
                         fv[{had[23:16], had[15:8], curb}]};
             end
          endcase
          binc <= binc + 1'b1;
          srin <= 8'h0;
        end
      end
    end
  end
  reg fmiso_leave;

always @(posedge clk)
    if (uq.st == 2)
      if (uq.p == 2)
        $display("P2 b%0d/%0d rxb=%02x bit=%0d miso=%b dout=%h rxq=%h",
                 uq.bitc, uq.idx, uq.rxb, uq.rxbit, miso, doutv, uq.rxseq);
reg rxact_d;
  always @(posedge clk) begin
    rxact_d <= rxact_db;
    if (rxact_db && !rxact_d)
      $display("RXSTART %0t doutv=%08h had=%06x srin=%02x curb=%02x", $time,
               doutv, had, srin, curb);
  end
reg rd_d;
  always @(posedge clk) begin
    rd_d <= rdy;
    if (rdy && !rd_d)
      $display("GRANT %0t rd=%08h rxq=%08h", $time, rd, uq.rxseq);
  end
  integer k, errs = 0;
  reg [31:0] expw;

  task rdword(input integer adr, input [31:0] exp);
    begin : rdw
      integer cnt;
      a = adr; req = 1;
      for (cnt = 0; cnt < 400; cnt = cnt + 1) begin
        if (rdy) begin
          #1;
          if (rd === exp) $display("word @%03x = %08h  OK", adr, rd);
          else begin
            errs = errs + 1;
            $display("word @%03x = %08h  expected %08h", adr, rd, exp);
          end
          req = 0;
          #30;                 /* hold idle long enough for done latch */
          disable rdw;
        end
        @(posedge clk);
      end
      $display("word @%03x TIMEOUT", adr);
      errs = errs + 1;
      req = 0;
    end
  endtask

  initial begin
    for (k = 0; k < 64; k = k + 1) begin
      expw = 32'hFACED00D + k;
      fv[4*k+0] = expw[7:0];
      fv[4*k+1] = expw[15:8];
      fv[4*k+2] = expw[23:16];
      fv[4*k+3] = expw[31:24];
    end
    #20 rst_n = 1;
    rdword(0,   32'hFACED00D);
    rdword(4,   32'hFACED00E);
    rdword(64,  32'hFACED011);
    rdword(12,  32'hFACED010);
    if (errs == 0) $display("QSPI UNIT TEST: PASS");
    else $display("QSPI UNIT TEST: FAIL (%0d)", errs);
    $finish;
  end

  wire busyw;
endmodule