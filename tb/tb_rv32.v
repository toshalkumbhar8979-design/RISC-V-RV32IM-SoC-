`timescale 1ns/1ps
module tb_rv32_core;

  reg  clk = 1'b0;
  reg  rst_n = 1'b0;
  reg  irq = 1'b0;
  always #5 clk = ~clk;                // 100 MHz

  // ---------------- instruction memory (combinational read) --------
  reg  [31:0] imem [0:8191];
  wire [31:0] iaddr;
  wire        iv;                        // core output
  wire [31:0] idata = imem[iaddr[15:2]];

  // ---------------- data memory (word array, byte-lane writes) -----
  reg  [31:0] dmem [0:2047];
  wire [31:0] daddr;
  wire [31:0] drd = dmem[daddr[13:2]];
  wire        dwen;
  wire        dw_we;
  wire [3:0]  dws;
  wire [31:0] dwd;

  wire [31:0] mask32 = { {8{dws[3]}}, {8{dws[2]}}, {8{dws[1]}}, {8{dws[0]}} };
  always @(posedge clk)
    if (dwen && dw_we)
      dmem[daddr[13:2]] <= (dmem[daddr[13:2]] & ~mask32) | (dwd & mask32);

  // ---------------- DUT -------------------------------------------
  wire inst_commit, trap_active;
  rv32_core #(.RESET_PC(32'h0)) uut (
    .clk         (clk),
    .rst_n       (rst_n),
    .imem_addr   (iaddr),
    .imem_valid  (iv),
    .imem_grant  (1'b1),
    .imem_rdata  (idata),
    .dmem_addr   (daddr),
    .dmem_valid  (dwen),
    .dmem_we     (dw_we),
    .dmem_wstrb  (dws),
    .dmem_wdata  (dwd),
    .dmem_grant  (1'b1),
    .dmem_rdata  (drd),
    .irq_tmr     (irq),
    .inst_commit (inst_commit),
    .trap_active (trap_active)
  );

  integer commits = 0;
  integer tf;
  always @(posedge clk) begin
    if (inst_commit) begin
      commits <= commits + 1;
      if (tf) $fdisplay(tf, "%0t %08X %08X", $time, uut.ins_pc, uut.ins);
    end
  end
  always @(posedge clk)
    if (uut.trap_pulse)
      $display("TRAP t=%0t cause=0x%08X mepc=0x%08X mie=%b ins_v=%b",
               $time, uut.u_csr.mcause, uut.u_csr.mepc,
               uut.mstatus_mie, uut.ins_v);

  // last-8 committed PC history (hierarchical ref into the DUT)
  reg [31:0] pchist [0:63];
  integer pci = 0;
  always @(posedge clk)
    if (inst_commit) begin
      pchist[pci & 63] <= uut.ins_pc;
      pci <= pci + 1;
    end

  reg [31:0] mb;
  integer i;
  initial begin
    $dumpfile("smoke.vcd");
    $dumpvars(0, tb_rv32_core);
    $readmemh("../tests/smoke.hex", imem);
    for (i = 0; i < 2048; i = i + 1) dmem[i] = 32'h0;   // deterministic RAM
    tf = $fopen("smoke_pc.trace", "w");

    rst_n = 0; commits = 0;
    #30 rst_n = 1;

    // wait for the firmware to arm the "timer" trigger, assert the IRQ and
// hold it until the handler services it (the handler disables MIE itself)
    begin : waitarm
      integer k;
      for (k = 0; k < 200000; k = k + 1) begin
        if (dmem[32'h1C0 >> 2] === 32'hAA55AA55) disable waitarm;
        #10;
      end
      $display("TB-TIMEOUT: firmware never armed the timer trigger");
      $finish;
    end
    irq = 1;                          // level: stays pending until acked
    begin : waitack
      integer k;
      for (k = 0; k < 20000; k = k + 1) begin
        if (dmem[32'h200 >> 2] != 32'h0) disable waitack;
        #10;
      end
      $display("TB-TIMEOUT: interrupt handler never serviced");
      $finish;
    end
    irq = 0;

    #18000;
    mb = dmem[32'h180 >> 2];
    $display("========================================================");
    if (mb == 32'h600D_F00D) begin
      $display("RESULT: PASS   mailbox=0x%08X irq_count=%0d commits=%0d",
               mb, dmem[32'h200 >> 2], commits);
    end else begin
      $display("RESULT: FAIL   mailbox=0x%08X (expect 0x600DF00D)", mb);
      $display("  last 8 committed PCs:");
      for (i = 0; i < 8; i = i + 1)
        $display("    pc=0x%08X", pchist[(pci + i) & 7]);
      $display("  irq_count=%0d commits=%0d", dmem[32'h200 >> 2], commits);
    end
    $finish;
  end

endmodule