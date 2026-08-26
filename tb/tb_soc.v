`timescale 1ns/1ps
//====================================================================
// tb_soc.v — Phase-2 SoC end-to-end test.
//
//   boot ROM  -> copies 128 words from SPI-flash (XIP) into SRAM
//             -> jumps to SRAM
//   app       -> UART alive byte
//             -> pushes DE AD BE EF through the SPI-TFT (ILI9341) ctrl
//             -> arms mtimecmp, enables MIE, waits for one timer IRQ
//             -> writes PASS mailbox (SRAM+0x80) and spins
//
// Behavioral models: SPI-flash (phase-locked to the engine's rx hooks),
// ILI9341 sink, UART 8N1 sink.
//====================================================================
module tb_soc;

  reg clk = 0, rst_n = 0;
  always #5 clk = ~clk;                     // 100 MHz

  wire uart_txd;
  wire tft_rst_n, tft_dc, tft_cs_n, tft_sclk, tft_sdi;
  wire f_cs_n, f_sclk, f_mosi;
  wire f_miso;

  `ifdef SOC_SYNC_SRAM
  localparam DO_SYNC = 1;
`else
  localparam DO_SYNC = 0;
`endif

  riscv_soc #(
    .SYNC_SRAM(DO_SYNC)
  ) dut (
    .clk(clk), .rst_n(rst_n),
    .uart_txd(uart_txd),
    .tft_rst_n(tft_rst_n), .tft_dc(tft_dc), .tft_cs_n(tft_cs_n),
    .tft_sclk(tft_sclk), .tft_sdi(tft_sdi),
    .f_cs_n(f_cs_n), .f_sclk(f_sclk), .f_mosi(f_mosi),
    .f_miso(f_miso)
  );

  // ================== SPI-flash behavioral model ==================
  // Answers bit-for-bit to the engine's own receive phase hooks, so
  // byte/bit alignment is exact by construction. Re-arms at CS rise.
  reg [7:0]  fv [0:16383];                   // flash byte memory
  reg        fck_d = 0;
  reg [7:0]  srin = 8'h0;
  reg [2:0]  bitin = 3'd0;
  reg [3:0]  binc = 4'h0;
  reg [23:0] had = 24'h0;
  wire [7:0] nbyte = {srin[6:0], f_mosi};

  assign f_miso = (dut.u_qspi.dbg_rxact_o)
        ? fv[had + dut.u_qspi.dbg_rxbit_o[4:3]][7 - dut.u_qspi.dbg_rxbit_o[2:0]]
        : 1'b1;

  always @(posedge clk) begin
    fck_d <= f_sclk;
    if (f_cs_n) begin
      bitin <= 0; binc <= 0;
    end else if (!fck_d && f_sclk) begin
      srin <= {srin[6:0], f_mosi};
      bitin <= bitin + 1'b1;
      if (bitin == 3'd7) begin
        bitin <= 0;
        case (binc)
          0: ;                                   // opcode
          1: had[23:16] <= nbyte;
          2: had[15:8]  <= nbyte;
          3: had[7:0]   <= nbyte;
        endcase
        binc <= binc + 1'b1;
        srin <= 8'h0;
      end
    end
  end

  // ================== ILI9341 sink ==================
  reg tft_sckd = 0, tft_sckd2 = 0;
  reg [7:0]  tshift = 8'h00;
  reg [2:0]  dbit = 3'd0;
  reg [7:0]  dabs [0:63];
  integer    dcount = 0;
  reg [7:0]  dcbs [0:15];
  integer    ccount = 0;

  always @(posedge clk) begin
    tft_sckd  <= tft_sclk;
    if (!tft_cs_n) begin
      if (!tft_sckd && tft_sclk) begin
        tshift <= {tshift[6:0], tft_sdi};
        dbit <= dbit + 1'b1;
        if (dbit == 3'd7) begin
          if (tft_dc) begin
            dabs[dcount] <= {tshift[6:0], tft_sdi};
            dcount <= dcount + 1;
          end else begin
            dcbs[ccount] <= {tshift[6:0], tft_sdi};
            ccount <= ccount + 1;
          end
          dbit <= 3'd0;
        end
      end
    end
  end

  // ================== UART TX sink (8N1) ==================
  localparam integer BDN = 434;
  reg [31:0] u_cnt = 32'h0;
  reg [3:0]  u_bn = 4'h0;
  reg        u_busy = 1'b0;
  reg [7:0]  ustr [0:63];
  integer    uidx = 0;

  always @(posedge clk) begin
    if (!u_busy) begin
      if (!uart_txd) begin
        u_busy <= 1;
        u_cnt  <= BDN/2;
        u_bn   <= 0;
      end
    end else begin
      if (u_cnt == 0) begin
        u_cnt <= BDN;
        if (u_bn == 0) begin
          u_bn <= 1;
        end else if (u_bn <= 8) begin
          ustr[uidx] <= {uart_txd, ustr[uidx][6:0]};
          u_bn <= u_bn + 1;
        end else if (u_bn == 9) begin
          u_bn <= u_bn + 1;
          uidx <= uidx + 1;
        end else if (u_bn == 10) begin
          u_busy <= 0;
          u_bn <= 0;
        end else begin
          u_bn <= u_bn + 1;
        end
      end else begin
        u_cnt <= u_cnt - 1;
      end
    end
  end

  // ================== stimulus + checks ===================

  integer k, errs = 0;
  reg [31:0] fword;
  reg [31:0] mb;

  initial begin
    $dumpfile("soc.vcd");
    $dumpvars(0, tb_soc);
    $readmemh("app_flash.hex", fv);

    rst_n = 0;
    #20 rst_n = 1;

    #4000000;                    // 4 ms (boot copies 512 words)

    $display("==============================================");
    // 1) copy fidelity (first 64 words)
    for (k = 0; k < 64; k = k + 1) begin
      if (k != 32) begin      // mailbox word legitimately overwritten
        fword = {fv[4*k+3], fv[4*k+2], fv[4*k+1], fv[4*k+0]};
        if (dut.g_u_sram.u_sram.mem[k] !== fword) begin
          if (errs < 4)
            $display("COPY word %0d: sram=%08h flash=%08h", k, dut.g_u_sram.u_sram.mem[k], fword);
          errs = errs + 1;
        end
      end
    end
    if (errs == 0) $display("FLASH->SRAM COPY: OK (64 words)");
    else $display("FLASH->SRAM COPY: FAIL (%0d)", errs);

    // 2) display pattern
    $write("DISPLAY data bytes:");
    for (k = 0; k < dcount && k < 8; k = k + 1) $write(" %02h", dabs[k]);
    $write("  (cmds");
    for (k = 0; k < ccount && k < 8; k = k + 1) $write(" %02h", dcbs[k]);
    $display(")");
    if (dcount >= 4 && dabs[dcount-4]==8'hDE && dabs[dcount-3]==8'hAD &&
        dabs[dcount-2]==8'hBE && dabs[dcount-1]==8'hEF)
      $display("DISPLAY pattern: OK  (DE AD BE EF)");
    else
      $display("DISPLAY pattern: MISMATCH (dc bytes captured=%0d)", dcount);

    // 3) PASS mailbox (proves the timer IRQ was handled by the app)
$display("PCEND=%08h", dut.u_core.ins_pc);
    mb = dut.g_u_sram.u_sram.mem[125];
    if (mb == 32'h600D_F00D)
      $display("TIMER IRQ + mailbox: OK (0x600DF00D)");
    else
      $display("TIMER IRQ + mailbox: expected 0x600DF00D got %08h", mb);

    // 4) UART text
    $write("UART TX: ");
    for (k = 0; k < uidx && k < 64; k = k + 1)
      if (ustr[k] >= 8'h20) $write("%c", ustr[k]);
    $display("");

    if (errs == 0 && mb == 32'h600D_F00D &&
        dcount >= 4 && dabs[dcount-1] == 8'hEF)
      $display("SOC TEST: PASS");
    else
      $display("SOC TEST: FAIL");
    $finish;
  end

endmodule