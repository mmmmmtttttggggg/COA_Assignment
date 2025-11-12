`timescale 1ns / 1ps

//
// Module Name: array_multiplier
// Description:
// This module implements a baseline 16x16 array multiplier. It is a
// purely combinational design.
// Logic flow:
// 1. 16 partial products are generated (one for each bit of 'a').
// 2. A sequential 'generate' loop creates a chain of 16 adders.
// 3. Each adder stage adds the next (shifted) partial product to the
//    accumulated sum from the previous stage.
//

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