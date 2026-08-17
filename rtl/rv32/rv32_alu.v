//====================================================================
// rv32_alu.v — 32-bit combinational ALU + branch comparators.
// alu_op (4 bits):
//   4'b0000 add, 4'b0001 sub, 4'b0010 sll, 4'b0011 srl, 4'b0100 sra,
//   4'b0101 xor, 4'b0110 and, 4'b0111 or,
//   4'b1000 slt (signed), 4'b1001 sltu, 4'b1010 pass-b (LUI / CSR rd)
// Branch compare helpers (eq/lt/ltu) independent of alu_op.
//====================================================================
module rv32_alu (
  input  wire [31:0] a,
  input  wire [31:0] b,
  input  wire [3:0]  alu_op,
  output reg  [31:0] y,
  output wire        eq,
  output wire        lt,   // a < b  signed
  output wire        ltu   // a < b  unsigned
);

  wire [31:0] add_y = a + b;
  wire [31:0] sub_y = a - b;

  assign eq  = (a == b);
  assign lt  = ($signed(a) < $signed(b));
  assign ltu = (a < b);

  always @(*) begin
    case (alu_op)
      4'b0000: y = add_y;
      4'b0001: y = sub_y;
      4'b0010: y = a << b[4:0];            // sll / slli
      4'b0011: y = a >> b[4:0];            // srl / srli
      4'b0100: y = $signed(a) >>> b[4:0];  // sra / srai
      4'b0101: y = a ^ b;
      4'b0110: y = a & b;
      4'b0111: y = a | b;
      4'b1000: y = lt  ? 32'h1 : 32'h0;    // slt
      4'b1001: y = ltu ? 32'h1 : 32'h0;    // sltu
      4'b1010: y = b;                      // pass-through (lui/csr)
      default: y = 32'h0;
    endcase
  end

endmodule