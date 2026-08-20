//====================================================================
// uart_lite.v — simple 8N1 UART transmitter + register interface.
// Memory map (base 0x4002_0000):
//   +0x00 TDATA (W) : byte to transmit
//   +0x04 STAT  (R) : bit0 TX_BUSY, bit1 TX_READY
//====================================================================
module uart_lite #(
  parameter [15:0] BAUD_DIV = 16'd434 // clk/(baud)
)(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        cwe,
  input  wire        crd,
  input  wire [3:0]  addr,
  input  wire [31:0] wdata,
  output reg  [31:0] rdata,
  output wire        txd
);

  reg [15:0] bcnt;
  reg [9:0]  shift;     // start + 8 data + stop
  reg [3:0]  biti;
  reg        busy;

  localparam IDLE  = 3'd0,
             START = 3'd1,
             DBIT  = 3'd2,
             STOP  = 3'd3;

  reg [2:0] st;
  reg [15:0] bdiv;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= IDLE; bdiv <= 0; shift <= 0; biti <= 0; busy <= 0;
      bcnt <= 0;
    end else begin
      case (st)
        IDLE: begin
          busy <= 0;
          if (cwe && (addr[3:0]==4'h0)) begin
            shift <= {1'b1, wdata[7:0], 1'b0};  // stop,data,start
            biti  <= 4'h0;
            bdiv  <= 0;
            busy  <= 1;
            st    <= START;
          end
        end
        START: begin
          if (bdiv == BAUD_DIV-1) begin
            bdiv <= 0;
            st <= DBIT;
          end else bdiv <= bdiv + 1;
        end
        DBIT: begin
          if (bdiv == BAUD_DIV-1) begin
            bdiv <= 0;
            shift <= {1'b1, shift[9:1]};
            biti  <= biti + 1;
            if (biti == 4'd8) st <= STOP;
          end else bdiv <= bdiv + 1;
        end
        STOP: begin
          if (bdiv == BAUD_DIV-1) begin
            bdiv <= 0; busy <= 0; st <= IDLE;
          end else bdiv <= bdiv + 1;
        end
        default: st <= IDLE;
      endcase
    end
  end

  assign txd = (st == IDLE) ? 1'b1 : shift[0];

  always @(*) begin
    rdata = 32'h0;
    if (crd && (addr[3:0]==4'h4))
      rdata = {30'b0, busy, ~busy};
  end

endmodule