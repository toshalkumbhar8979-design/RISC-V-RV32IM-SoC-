//====================================================================
// spi_tft.v — simple SPI master for an ILI9341-class TFT panel.
// Software drives CTRL (RST/DC/CS) and pushes raw bytes via DAT; the
// engine serializes each byte MSB-first on its own slow SCLK.
// Memory map (base 0x4001_0000):
//   +0x00 CTRL (RW) : bit0 RST_N, bit1 DC, bit2 CS_N (active low)
//   +0x04 DATW (W)  : byte[7:0] queued for transfer
//   +0x08 STAT (R)  : bit0 TX_BUSY
//====================================================================
module spi_tft (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        cwe,
  input  wire        crd,
  input  wire [3:0]  addr,
  input  wire [31:0] wdata,
  output reg  [31:0] rdata,

  output reg         tft_rst_n,
  output reg         tft_dc,
  output reg         tft_cs_n,
  output reg         tft_sclk,
  output reg         tft_sdi
);

  reg [9:0] shift;
  reg       busy;
  reg [1:0] sdiv;
  reg [3:0] bitno;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tft_rst_n <= 1'b0;
      tft_dc    <= 1'b0;
      tft_cs_n  <= 1'b1;
      tft_sclk  <= 1'b0;
      tft_sdi   <= 1'b0;
      shift     <= 10'h0;
      sdiv      <= 2'd0;
      busy      <= 1'b0;
      bitno     <= 4'd0;
    end else begin
      // control register latches the SPI control pins directly
      if (cwe && (addr[3:0] == 4'h0)) begin
        tft_rst_n <= wdata[0];
        tft_dc    <= wdata[1];
        tft_cs_n  <= wdata[2];
      end

      if (busy) begin
        case (sdiv)
          2'd0: begin tft_sclk <= 1'b0; tft_sdi <= shift[9]; sdiv <= 2'd1; end
          2'd1: begin sdiv <= 2'd2; end
          2'd2: begin
             tft_sclk <= 1'b1;
             shift    <= {shift[8:0], 1'b0};
             sdiv     <= 2'd3;
          end
          default: begin
             sdiv <= 2'd0;
             bitno <= bitno + 1;
             if (bitno == 4'd7) begin
               busy  <= 1'b0;
               tft_sclk <= 1'b0;
             end
          end
        endcase
      end else begin
        tft_sclk <= 1'b0;
        if (cwe && (addr[3:0] == 4'h4)) begin
          shift <= {2'b00, wdata[7:0]};   // 2 idle bits then 8 data bits
          bitno <= 4'd0;
          sdiv  <= 2'd0;
          busy  <= 1'b1;
        end
      end
    end
  end

  always @(*) begin
    rdata = 32'h0;
    if (crd && (addr[3:0] == 4'h8))
      rdata = {31'b0, busy};
  end

endmodule