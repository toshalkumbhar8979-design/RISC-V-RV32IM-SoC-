//====================================================================
// riscv_soc.v — Phase-2 minimal SoC: rv32_core + boot ROM + SRAM +
// QSPI flash XIP + SPI-TFT + UART + mtime timer.
//
// Memory map:
//   0x0000_0000  BootROM        (16 KB logic)
//   0x0001_0000  SRAM           (32 KB)
//   0x1000_0000  Flash XIP      (read-only, via qspi engine)
//   0x4001_0000  SPI-TFT ctrl
//   0x4002_0000  UART
//   0x4003_0000  Timer
//====================================================================
module riscv_soc (
  input  wire        clk,
  input  wire        rst_n,
  output wire        uart_txd,
  output wire        tft_rst_n, tft_dc, tft_cs_n, tft_sclk, tft_sdi,
  output wire        f_cs_n,  f_sclk, f_mosi,
  input  wire        f_miso
);

  // ---------------- core -------------
  wire [31:0] imem_addr, imem_rdata, dmem_addr, dmem_wdata, dmem_rdata;
  wire        imem_valid, dmem_valid, dmem_we, dmem_grant;
  wire [3:0]  dmem_wstrb;
  wire        irq_tmr_core, inst_commit, trap_active;

  rv32_core #(.RESET_PC(32'h0000_0000)) u_core (
    .clk        (clk),
    .rst_n      (rst_n),
    .imem_addr  (imem_addr),
    .imem_valid (imem_valid),
    .imem_grant (1'b1),
    .imem_rdata (imem_rdata),
    .dmem_addr  (dmem_addr),
    .dmem_valid (dmem_valid),
    .dmem_we    (dmem_we),
    .dmem_wstrb (dmem_wstrb),
    .dmem_wdata (dmem_wdata),
    .dmem_grant (dmem_grant),
    .dmem_rdata (dmem_rdata),
    .irq_tmr    (irq_tmr_core),
    .inst_commit(inst_commit),
    .trap_active(trap_active)
  );

  // ---------------- decode -------------
  wire rom_sel_i  = (imem_addr[31:16] == 16'h0000) && (imem_addr[15:14] == 2'b00);
  wire sram_sel_i = (imem_addr[31:16] == 16'h0001);
  wire rom_sel_d  = (dmem_addr[31:16] == 16'h0000) && (dmem_addr[15:14] == 2'b00);
  wire sram_sel_d = (dmem_addr[31:16] == 16'h0001);
  wire flash_sel  = (dmem_addr[31:24] == 8'h10);
  wire tft_sel    = (dmem_addr[31:16] == 16'h4001);
  wire uart_sel   = (dmem_addr[31:16] == 16'h4002);
  wire timer_sel  = (dmem_addr[31:16] == 16'h4003);

  // ---------------- boot ROM (read-only) -------------
  wire [31:0] rom_d_inst, rom_d_data;
  bootrom #(.AW(12)) u_boot (
    .addr (imem_addr[13:2]),
    .rdata(rom_d_inst)
  );
  bootrom #(.AW(12)) u_boot_d (
    .addr (dmem_addr[13:2]),
    .rdata(rom_d_data)
  );

  // ---------------- SRAM (dual read) -------------
  wire [31:0] sram_i, sram_d;
  sram_wrap #(.AW(13)) u_sram (
    .clk     (clk),
    .ra_addr (imem_addr[14:2] - 15'h4000), .ra_data(sram_i),
    .rb_addr (dmem_addr[14:2] - 15'h4000), .rb_data(sram_d),
    .we      (dmem_valid && dmem_we && sram_sel_d),
    .w_addr  (dmem_addr[14:2] - 15'h4000), .w_strb(dmem_wstrb), .w_data(dmem_wdata)
  );

  // ---------------- QSPI flash XIP -------------
  wire [31:0]  qspi_rdata;
  wire         qspi_rdy, qspi_busy;
  qspi_ctrl u_qspi (
    .clk      (clk),
    .rst_n    (rst_n),
    .x_addr_i ({8'h0, dmem_addr[23:0]}),
    .x_req_i  (dmem_valid && flash_sel && !dmem_we),
    .x_rdata_o(qspi_rdata),
    .x_rdy_o  (qspi_rdy),
    .x_busy_o (qspi_busy),
    .q_cs_n   (f_cs_n),
    .q_sclk   (f_sclk),
    .q_mosi   (f_mosi),
    .q_miso   (f_miso)
  );

  // ---------------- SPI-TFT -------------
  wire [31:0] tft_rdata;
  spi_tft u_tft (
    .clk(clk), .rst_n(rst_n),
    .cwe(dmem_valid && dmem_we   && tft_sel),
    .crd(dmem_valid && !dmem_we && tft_sel),
    .addr(dmem_addr[3:0]), .wdata(dmem_wdata), .rdata(tft_rdata),
    .tft_rst_n(tft_rst_n), .tft_dc(tft_dc), .tft_cs_n(tft_cs_n),
    .tft_sclk(tft_sclk), .tft_sdi(tft_sdi)
  );

  // ---------------- UART -------------
  wire [31:0] uart_rdata;
  uart_lite u_uart (
    .clk(clk), .rst_n(rst_n),
    .cwe(dmem_valid && dmem_we   && uart_sel),
    .crd(dmem_valid && !dmem_we && uart_sel),
    .addr(dmem_addr[3:0]), .wdata(dmem_wdata), .rdata(uart_rdata),
    .txd(uart_txd)
  );

  // ---------------- Timer -------------
  wire [31:0] tim_rdata;
  rv32_timer_periph u_tim (
    .clk(clk), .rst_n(rst_n),
    .cwe(dmem_valid && dmem_we    && timer_sel),
    .crd(dmem_valid && !dmem_we && timer_sel),
    .addr(dmem_addr[4:0]), .wdata(dmem_wdata), .rdata(tim_rdata),
    .irq(irq_tmr_core)
  );

  // ---------------- read-back mux -------------
  assign imem_rdata =
              rom_sel_i  ? rom_d_inst :
              sram_sel_i ? sram_i     : 32'h0;

  assign dmem_rdata =
              rom_sel_d  ? rom_d_data :
              sram_sel_d ? sram_d     :
              flash_sel  ? qspi_rdata :
              tft_sel    ? tft_rdata  :
              uart_sel   ? uart_rdata :
              timer_sel  ? tim_rdata  : 32'h0;

  assign dmem_grant = flash_sel ? (dmem_we ? 1'b1 : qspi_rdy) : 1'b1;

endmodule