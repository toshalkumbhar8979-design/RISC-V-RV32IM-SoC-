//====================================================================
// qspi_ctrl.v — serial-flash read engine with an XIP window.
// One 32-bit load at a window address = one SPI read:
//   CS# low, 0x03, 24-bit addr, 32 data bits, CS# high.
// 4 system clocks per bit. Little-endian assemble. Read-only.
//====================================================================
module qspi_ctrl (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [31:0] x_addr_i,
  input  wire        x_req_i,
  output wire [31:0] x_rdata_o,
  output reg         x_rdy_o,
  output reg         x_busy_o,
  output reg         q_cs_n,
  output reg         q_sclk,
  output reg         q_mosi,
  input  wire        q_miso,
  // shared-bus chip-select select: 0 = flash (q_cs_n), 1 = PSRAM (q_cs1_n)
  input  wire        cs_sel,
  output reg         q_cs1_n,
  // test hooks for behavioral models
  output wire [4:0]  dbg_rxbit_o,
  output wire        dbg_rxact_o
);

  localparam ST_IDLE=3'd0, ST_XMIT=3'd1, ST_RECV=3'd2, ST_HOLD=3'd3;

  reg [2:0] st;
  reg [1:0] p;            // 4 phases per bit
  reg [2:0] bitc;         // bit 0..7 within byte
  reg [2:0] idx;          // byte index 0..3 within phase
  reg [31:0] laddr;
  reg [7:0]  txb, rxb;
  reg [31:0] rxseq;
  reg        done;
  reg [4:0]  rxbit;
  reg        rxact;

  assign x_rdata_o = rxseq;
  assign dbg_rxbit_o = rxbit;
  assign dbg_rxact_o = rxact;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_IDLE; p <= 2'd0; bitc <= 3'd0; idx <= 3'd0;
      laddr <= 32'h0; txb <= 8'h0; rxb <= 8'h0; rxseq <= 32'h0;
      done  <= 1'b0; rxbit <= 5'd0; rxact <= 1'b0;
      x_rdy_o <= 1'b0; x_busy_o <= 1'b0;
      q_cs_n <= 1'b1; q_cs1_n <= 1'b1; q_sclk <= 1'b0; q_mosi <= 1'b1;
    end else begin
      x_rdy_o <= 1'b0;
      case (st)
        ST_IDLE: begin
          q_cs_n <= 1'b1; q_cs1_n <= 1'b1; q_sclk <= 1'b0; q_mosi <= 1'b1;
          x_busy_o <= 1'b0;
          if (!x_req_i) done <= 1'b0;
          if (x_req_i && !done) begin
            laddr   <= x_addr_i;
            idx     <= 3'd0;
            bitc    <= 3'd0;
            p       <= 2'd0;
            txb     <= 8'h03;
            rxseq   <= 32'h0;
            rxbit   <= 5'd0;   // fresh receive counter per transaction
            if (cs_sel) q_cs1_n <= 1'b0; else q_cs_n <= 1'b0;
            x_busy_o <= 1'b1;
            st      <= ST_XMIT;
          end
        end
        ST_XMIT: begin
          case (p)
            2'd0: begin q_sclk <= 1'b0; q_mosi <= txb[7]; p <= 2'd1; end
            2'd1: begin q_sclk <= 1'b1; p <= 2'd2; end
            2'd2: begin q_sclk <= 1'b0; p <= 2'd3; end
            default: begin
              txb  <= {txb[6:0], 1'b0};
              p    <= 2'd0;
              bitc <= bitc + 1'b1;
              if (bitc == 3'd7) begin
                bitc <= 3'd0;
                if (idx == 3'd3) begin
                  st  <= ST_RECV;
                  idx <= 3'd0;
                  rxb <= 8'h0;
                end else begin
                  case (idx)
                    3'd0: txb <= laddr[23:16];
                    3'd1: txb <= laddr[15:8];
                    default: txb <= laddr[7:0];
                  endcase
                  idx <= idx + 1'b1;
                end
              end
            end
          endcase
        end
        ST_RECV: begin
          rxact <= 1'b1;
          case (p)
            2'd0: begin q_sclk <= 1'b0; p <= 2'd1; end
            2'd1: begin q_sclk <= 1'b1; p <= 2'd2; end
            // sample and pack on the same phase (p2): no skew
            2'd2: begin
              q_sclk <= 1'b0;
              if (bitc == 3'd7) begin
                rxseq <= {{rxb[6:0], q_miso}, rxseq[31:8]};
                bitc  <= 3'd0;
                if (idx == 3'd3) begin
                  st <= ST_HOLD;
                end else begin
                  idx  <= idx + 1'b1;
                  rxbit <= rxbit + 5'd1;
                  rxb  <= 8'h0;
                end
              end else begin
                rxb   <= {rxb[6:0], q_miso};
                rxbit <= rxbit + 5'd1;
                bitc  <= bitc + 1'b1;
              end
              p <= 2'd3;
            end
            default: begin
              p <= 2'd0;
            end
          endcase
        end
        ST_HOLD: begin
          q_cs_n   <= 1'b1;
          q_cs1_n  <= 1'b1;
          rxact    <= 1'b0;
          x_rdy_o   <= 1'b1;
          x_busy_o  <= 1'b0;
          done      <= 1'b1;
          st        <= ST_IDLE;
        end
        default: st <= ST_IDLE;
      endcase
    end
  end

endmodule