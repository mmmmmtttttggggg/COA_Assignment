//////////////////////////////////////////////////////////////////////////////////
//Description: A 16x16 pipelined Wallace-Tree Multiplier.
// Architecture:
// This design is heavily optimized for speed (high clock frequency)
// by implementing a deep 4-stage pipeline. It breaks the
// multiplication logic into four smaller combinational stages, with
// registers separating each stage.
// Pipeline Stages:
//   - Stage 1: Partial Product Generation
//   - Stage 2: CSA Reduction Tree (16 -> 6)
//   - Stage 3: CSA Reduction Tree (6 -> 2)
//   - Stage 4: Final 32-bit Addition
//////////////////////////////////////////////////////////////////////////////////
//
// Module: csa_3_2
// Description: A 3-to-2 compressor (32-bit Carry-Save Adder).
module csa_3_2 (
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,
    output [31:0] s,     // Sum vector
    output [31:0] c_out  // Carry vector (shifted left by 1)
);

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_full_adder
            // s[i] is the simple XOR of the three input bits
            assign s[i] = a[i] ^ b[i] ^ c[i];
            
            // carry is the majority function of the three input bits
            wire carry;
            assign carry = (a[i] & b[i]) | (b[i] & c[i]) | (a[i] & c[i]);
            
            // The carry from bit 'i' becomes an input to the adder at bit 'i+1'.
            // So, we assign it to c_out[i+1].
            if (i < 31) begin
                assign c_out[i+1] = carry;
            end
        end
    endgenerate
    
    // There is no carry-in to the first bit
    assign c_out[0] = 1'b0;
endmodule


//
// Module: wallace_16bit
// Description: A 4-Stage Pipelined 16x16 unsigned Wallace-Tree Multiplier.
//
module wallace_16bit (
    input  clk,
    input  rst,
    input  [15:0] A,
    input  [15:0] B,
    output reg [31:0] P,  // Product (A * B) - Now a register
    output reg p_valid     // Signals that P is valid
);

    // --- Pipeline Registers ---
    // Stage 1 Registers (after PP Gen)
    reg [31:0] pp_reg[15:0];

    // Stage 2 Registers (after CSA 16 -> 6)
    reg [31:0] s3_operands_reg[5:0];
    
    // Stage 3 Registers (after CSA 6 -> 2)
    reg [31:0] final_sum_reg;
    reg [31:0] final_carry_reg;

    // --- Validity Pipeline (Shift Register) ---
    reg [3:0] valid_shifter;

    // --- Combinational Logic for Stage 1 (PP Gen) ---
    // Inputs: A, B (from module input)
    // Outputs: pp (wires)
    wire [31:0] pp[15:0];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pp
            assign pp[i] = (A[i]) ? ({16'b0, B} << i) : 32'b0;
        end
    endgenerate

    // --- Combinational Logic for Stage 2 (CSA 16 -> 6) ---
    // Inputs: pp_reg (from Stage 1 registers)
    // Outputs: s3_operands (wires)
    wire [31:0] s1[4:0], c1[4:0];
    csa_3_2 csa1_0 (.a(pp_reg[0]),  .b(pp_reg[1]),  .c(pp_reg[2]),  .s(s1[0]), .c_out(c1[0]));
    csa_3_2 csa1_1 (.a(pp_reg[3]),  .b(pp_reg[4]),  .c(pp_reg[5]),  .s(s1[1]), .c_out(c1[1]));
    csa_3_2 csa1_2 (.a(pp_reg[6]),  .b(pp_reg[7]),  .c(pp_reg[8]),  .s(s1[2]), .c_out(c1[2]));
    csa_3_2 csa1_3 (.a(pp_reg[9]),  .b(pp_reg[10]), .c(pp_reg[11]), .s(s1[3]), .c_out(c1[3]));
    csa_3_2 csa1_4 (.a(pp_reg[12]), .b(pp_reg[13]), .c(pp_reg[14]), .s(s1[4]), .c_out(c1[4]));
    
    wire [31:0] s1_operands[10:0];
    assign s1_operands[0]  = s1[0];
    assign s1_operands[1]  = s1[1];
    assign s1_operands[2]  = s1[2];
    assign s1_operands[3]  = s1[3];
    assign s1_operands[4]  = s1[4];
    assign s1_operands[5]  = c1[0];
    assign s1_operands[6]  = c1[1];
    assign s1_operands[7]  = c1[2];
    assign s1_operands[8]  = c1[3];
    assign s1_operands[9]  = c1[4];
    assign s1_operands[10] = pp_reg[15]; // From Stage 1 register

    wire [31:0] s2[2:0], c2[2:0];
    csa_3_2 csa2_0 (.a(s1_operands[0]), .b(s1_operands[1]), .c(s1_operands[2]), .s(s2[0]), .c_out(c2[0]));
    csa_3_2 csa2_1 (.a(s1_operands[3]), .b(s1_operands[4]), .c(s1_operands[5]), .s(s2[1]), .c_out(c2[1]));
    csa_3_2 csa2_2 (.a(s1_operands[6]), .b(s1_operands[7]), .c(s1_operands[8]), .s(s2[2]), .c_out(c2[2]));

    wire [31:0] s2_operands[7:0];
    assign s2_operands[0] = s2[0];
    assign s2_operands[1] = s2[1];
    assign s2_operands[2] = s2[2];
    assign s2_operands[3] = c2[0];
    assign s2_operands[4] = c2[1];
    assign s2_operands[5] = c2[2];
    assign s2_operands[6] = s1_operands[9];
    assign s2_operands[7] = s1_operands[10];

    wire [31:0] s3[1:0], c3[1:0];
    csa_3_2 csa3_0 (.a(s2_operands[0]), .b(s2_operands[1]), .c(s2_operands[2]), .s(s3[0]), .c_out(c3[0]));
    csa_3_2 csa3_1 (.a(s2_operands[3]), .b(s2_operands[4]), .c(s2_operands[5]), .s(s3[1]), .c_out(c3[1]));

    wire [31:0] s3_operands[5:0];
    assign s3_operands[0] = s3[0];
    assign s3_operands[1] = s3[1];
    assign s3_operands[2] = c3[0];
    assign s3_operands[3] = c3[1];
    assign s3_operands[4] = s2_operands[6];
    assign s3_operands[5] = s2_operands[7];

    // --- Combinational Logic for Stage 3 (CSA 6 -> 2) ---
    // Inputs: s3_operands_reg (from Stage 2 registers)
    // Outputs: final_sum, final_carry (wires)
    wire [31:0] s4[1:0], c4[1:0];
    csa_3_2 csa4_0 (.a(s3_operands_reg[0]), .b(s3_operands_reg[1]), .c(s3_operands_reg[2]), .s(s4[0]), .c_out(c4[0]));
    csa_3_2 csa4_1 (.a(s3_operands_reg[3]), .b(s3_operands_reg[4]), .c(s3_operands_reg[5]), .s(s4[1]), .c_out(c4[1]));
    
    wire [31:0] s4_operands[3:0];
    assign s4_operands[0] = s4[0];
    assign s4_operands[1] = s4[1];
    assign s4_operands[2] = c4[0];
    assign s4_operands[3] = c4[1];

    wire [31:0] s5[0:0], c5[0:0];
    csa_3_2 csa5_0 (.a(s4_operands[0]), .b(s4_operands[1]), .c(s4_operands[2]), .s(s5[0]), .c_out(c5[0]));

    wire [31:0] s5_operands[2:0];
    assign s5_operands[0] = s5[0];
    assign s5_operands[1] = c5[0];
    assign s5_operands[2] = s4_operands[3];

    wire [31:0] final_sum, final_carry;
    csa_3_2 csa6_0 (.a(s5_operands[0]), .b(s5_operands[1]), .c(s5_operands[2]), .s(final_sum), .c_out(final_carry));

    // --- Combinational Logic for Stage 4 (Final Add) ---
    // Inputs: final_sum_reg, final_carry_reg (from Stage 3 registers)
    // Outputs: p_wire (wire)
    wire [31:0] p_wire;
    assign p_wire = final_sum_reg + final_carry_reg;


    // --- Pipeline Registering Logic ---
    integer j; // <-- THIS WAS THE FIX: 'genvar j' was changed to 'integer j'
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline registers
            for (j = 0; j < 16; j = j + 1) begin
                pp_reg[j] <= 32'b0;
            end
            for (j = 0; j < 6; j = j + 1) begin
                s3_operands_reg[j] <= 32'b0;
            end
            final_sum_reg   <= 32'b0;
            final_carry_reg <= 32'b0;
            P                 <= 32'b0;
            valid_shifter     <= 4'b0;
            p_valid           <= 1'b0;
        end else begin
            // --- Clock Data Through Pipeline ---
            
            // Stage 1 -> Register Bank 1
            // (A,B -> PP Gen -> pp_reg)
            for (j = 0; j < 16; j = j + 1) begin
                pp_reg[j] <= pp[j];
            end
            
            // Stage 2 -> Register Bank 2
            // (pp_reg -> CSA(16->6) -> s3_operands_reg)
            for (j = 0; j < 6; j = j + 1) begin
                s3_operands_reg[j] <= s3_operands[j];
            end

            // Stage 3 -> Register Bank 3
            // (s3_operands_reg -> CSA(6->2) -> final_..._reg)
            final_sum_reg   <= final_sum;
            final_carry_reg <= final_carry;
            
            // Stage 4 -> Output Register
            // (final_..._reg -> Final Add -> P)
            P <= p_wire;
            
            // --- Validity Pipeline ---
            // A '1' is fed in and propagates through the shifter,
            // taking 4 cycles to reach the end, matching the data pipeline latency.
            valid_shifter[0] <= 1'b1; // Assuming input is always valid when not in reset
            valid_shifter[1] <= valid_shifter[0];
            valid_shifter[2] <= valid_shifter[1];
            valid_shifter[3] <= valid_shifter[2];
            
            // p_valid is high when the '1' reaches the end of the shifter
            p_valid <= valid_shifter[3];
        end
    end

endmodule
