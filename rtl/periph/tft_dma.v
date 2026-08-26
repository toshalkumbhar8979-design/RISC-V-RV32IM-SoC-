//====================================================================
// tft_dma.v — pixel-DMA engine for the SPI-TFT (ILI9341).
//
// Pushes a byte stream (e.g. a framebuffer region) from the PSRAM window
// to the ILI9341 over its own slow SPI master pins, freeing the CPU from
// per-byte writes. CPU sets CTRL/SRC/LEN then polls STAT.
//
// Memory map (base 0x4001_0100):
//   +0x00 CTRL (W) bit0 GO
//   +0x04 SRC  (W) framebuffer start address (physical)
//   +0x08 LEN  (W) number of bytes to push
//   +0x0c STAT (R) bit0 BUSY
//====================================================================
module tft_dma (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        cwe,
  input  wire        crd,
  input  wire [7:0]  addr,          // offset in reg window
  input  wire [31:0] wdata,
  output reg  [31:0] rdata,
  // source memory read port (PSRAM framebuffer)
  output wire [31:0] fb_addr,
  input  wire [31:0] fb_rdata,
  input  wire        fb_rdy,        // data valid
  output reg         fb_req,
  // TFT SPI pins (shared style with spi_tft)
  output reg         tft_dc,
  output reg         tft_cs_n,
  output reg         tft_sclk,
  output reg         tft_sdi,
  output wire        tft_busy
);

  localparam ST_IDLE=3'd0, ST_RSRC=3'd1, ST_SHIFT=3'd2, ST_DONE=3'd3;

  reg [2:0] st;
  reg [31:0] src, len, cnt;
  reg [7:0]  shreg;
  reg [2:0]  bitc;
  reg [1:0]  sdiv;
  reg        go;

  assign tft_busy = (st != ST_IDLE);
  assign fb_addr  = src;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= ST_IDLE; src <= 0; len <= 0; cnt <= 0;
      shreg <= 0; bitc <= 0; sdiv <= 0; go <= 0;
      tft_dc <= 1'b0; tft_cs_n <= 1'b1; tft_sclk <= 1'b0; tft_sdi <= 1'b0;
      fb_req <= 1'b0;
      rdata <= 0;
    end else begin
      // register writes
      if (cwe) begin
        case (addr[3:0])
          4'h0: go  <= wdata[0];
          4'h4: src <= wdata;
          4'h8: len <= wdata;
          default: ;
        endcase
      end
      if (crd) begin
        case (addr[3:0])
          4'hc: rdata <= {31'b0, (st != ST_IDLE)};
          default: rdata <= 0;
        endcase
      end
      case (st)
        ST_IDLE: begin
          tft_cs_n <= 1'b1; tft_sclk <= 1'b0;
          if (go) begin
            go       <= 1'b0;
            cnt      <= 32'h0;
            tft_cs_n <= 1'b0;
            tft_dc   <= 1'b1;           // data mode
            fb_req   <= 1'b1;           // request first byte
            st       <= ST_RSRC;
          end
        end
        ST_RSRC: begin
          if (fb_rdy) begin
            shreg  <= fb_rdata[7:0];
            bitc   <= 0; sdiv <= 0;
            fb_req <= 1'b0;
            st     <= ST_SHIFT;
          end
        end
        ST_SHIFT: begin
          case (sdiv)
            2'd0: begin tft_sclk <= 1'b0; tft_sdi <= shreg[7]; sdiv <= 2'd1; end
            2'd1: begin sdiv <= 2'd2; end
            2'd2: begin tft_sclk <= 1'b1; shreg <= {shreg[6:0], 1'b0}; sdiv <= 2'd3; end
            default: begin
              sdiv <= 2'd0;
              bitc <= bitc + 1'b1;
              if (bitc == 3'd7) begin
                cnt <= cnt + 1'b1;
                if (cnt == (len-1)) begin
                  st <= ST_DONE;
                end else begin
                  fb_req <= 1'b1;
                  src    <= src + 1'b1;
                  st     <= ST_RSRC;
                end
              end
            end
          endcase
        end
        ST_DONE: begin
          tft_cs_n <= 1'b1; tft_sclk <= 1'b0;
          st <= ST_IDLE;
        end
        default: st <= ST_IDLE;
      endcase
    end
  end

endmodule