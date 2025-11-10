`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: array_multiplier
// Description: 
//   16-bit baseline array multiplier (behavioral model).
//   This implementation uses a generate loop to create a chain of 
//   combinational adders, one for each partial product.
//   This is NOT an efficient implementation and is intended as a 
//   baseline for comparison against an optimized multiplier (e.g., Wallace-Tree).
//   It will result in a long critical path.
//////////////////////////////////////////////////////////////////////////////////

module array_multiplier(
  input [15:0] a,
  input [15:0] b,
  output [31:0] p
);

  // This generate block creates a combinational "chain" of adders.
  // p_stage[0] = 0
  // p_stage[1] = p_stage[0] + (pp[0] << 0)
  // p_stage[2] = p_stage[1] + (pp[1] << 1)
  // ...
  // p = p_stage[16]
  
  // Wires to hold the intermediate sum at each stage
  wire [31:0] p_stage [0:16];
  genvar i;
  
  // Stage 0: The initial sum is zero.
  assign p_stage[0] = 32'b0;
  
  generate
    for (i = 0; i < 16; i = i + 1) begin : array_add_loop
    
      // 1. Calculate the partial product for this stage: (b * a[i])
      //    This is just `b` if `a[i]` is 1, or `0` if `a[i]` is 0.
      wire [15:0] pp;
      assign pp = {16{a[i]}} & b;
      
      // 2. Add the (shifted) partial product to the sum from the previous stage.
      //    This implies a 32-bit adder for each stage 'i'.
      //    The `(pp << i)` performs the necessary shift for the partial product.
      assign p_stage[i+1] = p_stage[i] + (pp << i);
      
    end
  endgenerate
  
  // The final result is the output from the last adder stage.
  assign p = p_stage[16];

endmodule