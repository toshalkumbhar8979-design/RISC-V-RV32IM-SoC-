//====================================================================
// rv32_muldiv.v - multicycle M-extension engine (multiply + divide).
// op_i carries the raw funct3 of the M instruction:
//   MUL=000 MULH=001 MULHSU=010 MULHU=011 DIV=100 DIVU=101 REM=110 REMU=111
// Notice this encoding (bit2 == 0) selects multiply vs divide, so REM and
// REMU are naturally distinct here (unlike a sparse 3-bit opcode).
//
// Multiplication : shift-add, 32 iterations (~36 cycles)
// Division       : restoring shift-subtract MSB-first (~36 cycles)
// Sign handling  : magnitude arithmetic + two's-complement adjust
// Spec edge cases:
//   DIV/DIVU by zero  -> quotient 0xFFFFFFFF, remainder = dividend
//   MIN_INT / -1      -> quotient MIN_INT, remainder 0  (from magnitude math)
//
// Interface: start_i pulses once; busy_o high while computing;
// done_o pulses once with res_o final.
//====================================================================
`include "rv32_defs.vh"

module rv32_muldiv (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        start_i,
  input  wire [31:0] a_i,
  input  wire [31:0] b_i,
  input  wire [2:0]  op_i,
  output reg  [31:0] res_o,
  output reg         done_o,
  output reg         busy_o
);

  localparam [1:0] S_IDLE = 2'd0, S_RUN = 2'd1, S_FIN = 2'd2, S_DONE = 2'd3;

  wire is_mul   = ~op_i[2];                      // MUL/MULH/MULHSU/MULHU
  wire a_signed = (op_i==3'b000)||(op_i==3'b001)||(op_i==3'b010)|| // MUL,MULH,MULHSU
                  (op_i==3'b100)||(op_i==3'b110);                  // DIV,REM
  wire b_signed = (op_i==3'b000)||(op_i==3'b001)||
                  (op_i==3'b100)||(op_i==3'b110);                  // DIV,REM
  wire is_rem   = (op_i==3'b110)||(op_i==3'b111);                  // REM,REMU

  wire [31:0] amag = (a_signed && a_i[31]) ? (~a_i + 32'h1) : a_i;
  wire [31:0] bmag = (b_signed && b_i[31]) ? (~b_i + 32'h1) : b_i;
  wire        la   = a_signed && a_i[31];
  wire        lb   = b_signed && b_i[31];

  reg  [1:0]  st;
  reg  [5:0]  step;
  reg  [31:0] ma, mb;                  // operand magnitudes
  reg         la_q, lb_q;              // operand signs (latched)
  reg  [63:0] acc, ash;                // multiply state
  reg  [33:0] r;                       // divide working remainder
  reg  [31:0] d, dv;                   // dividend shifts + divisor
  reg  [31:0] q;                       // divide quotient (magnitude)
  reg         zd;                      // divisor is zero

  // result selection (combinational, evaluated while st==S_FIN)
  wire [63:0] mpro = (la_q ^ lb_q) ? (~acc + 64'h1) : acc;
  wire [31:0] qadj = (la_q ^ lb_q) ? (~q  + 32'h1)  : q;
  wire [31:0] radj = la_q ? (~r[31:0] + 32'h1) : r[31:0];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE; busy_o <= 1'b0; done_o <= 1'b0; res_o <= 32'h0;
      step <= 6'd0;
    end else begin
      done_o <= 1'b0;
      case (st)
        S_IDLE: begin
          if (start_i) begin
            st     <= S_RUN;
            busy_o <= 1'b1;
            step   <= 6'd0;
            ma     <= amag; mb <= bmag;
            la_q   <= la;    lb_q <= lb;
            acc    <= 64'h0; ash <= {32'h0, amag};
            r      <= 34'h0; d   <= amag;
            dv     <= bmag;
            q      <= 32'h0;
            zd     <= (bmag == 32'h0);
          end
        end
        S_RUN: begin
          if (is_mul) begin
            if (step == 6'd32) begin
              st <= S_FIN;
            end else begin
              if (mb[step]) acc <= acc + ash;
              ash  <= ash << 1;
              step <= step + 1;
            end
          end else if (zd) begin
            st <= S_FIN;                 // spec result in S_FIN
          end else if (step == 6'd32) begin
            st <= S_FIN;
          end else begin
            if ({r[32:0], d[31]} >= {2'b00, dv}) begin
              r        <= {r[32:0], d[31]} - {2'b00, dv};
              q[31-step] <= 1'b1;
            end else begin
              r <= {r[32:0], d[31]};
            end
            d    <= d << 1;
            step <= step + 1;
          end
        end
        S_FIN: begin
          if (is_mul) begin
            res_o <= (op_i == 3'b000) ? mpro[31:0] : mpro[63:32];
          end else if (zd) begin
            res_o <= is_rem ? a_i : 32'hFFFF_FFFF;   // div-by-zero
          end else begin
            res_o <= is_rem ? radj : qadj;
          end
          st     <= S_DONE;
          busy_o <= 1'b0;
        end
        S_DONE: begin
          done_o <= 1'b1;
          st     <= S_IDLE;
        end
        default: st <= S_IDLE;
      endcase
    end
  end

endmodule