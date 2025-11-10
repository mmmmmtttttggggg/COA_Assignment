`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: mult_tb
// Description: 
//   Testbench for 16-bit multipliers.
//   It compares the output of the UUT (Unit Under Test) against a
//   golden reference model (using Verilog's '*' operator).
//
//   To test your Wallace-Tree multiplier, you would instantiate it
//   here as well and connect its inputs/outputs.
//////////////////////////////////////////////////////////////////////////////////

module mult_tb;

  // Parameters
  localparam WIDTH = 16;
  localparam NUM_RANDOM_TESTS = 10;
  
  // Inputs to the UUT
  reg [WIDTH-1:0] a_tb;
  reg [WIDTH-1:0] b_tb;
  
  // Output from the UUT
  wire [2*WIDTH-1:0] p_array_tb;
  
  // Golden reference
  // We use a separate wire for the expected result for clarity.
  // This uses the built-in Verilog multiplier.
  wire [2*WIDTH-1:0] p_golden;
  assign p_golden = $signed(a_tb) * $signed(b_tb); // Use signed for correctness if needed
  // Note: If your design is unsigned, use:
  // assign p_golden = a_tb * b_tb;
  
  
  // Instantiate the Unit Under Test (UUT)
  array_multiplier uut_array (
    .a(a_tb),
    .b(b_tb),
    .p(p_array_tb)
  );
  
  // --- Add your Wallace-Tree Instantiation here for testing ---
  // wallace_multiplier uut_wallace (
  //   .a(a_tb),
  //   .b(b_tb),
  //   .p(p_wallace_tb) // You'll need to declare p_wallace_tb
  // );
  
  
  // Testbench logic
  integer i;
  integer errors;
  
  initial begin
    $display("--- Starting 16-bit Multiplier Testbench ---");
    errors = 0;
    
    // Initialize inputs
    a_tb = 0;
    b_tb = 0;
    #10;
    
    // Test 1: Zero test
    $display("Test 1: Zero test");
    a_tb = 16'h0000;
    b_tb = 16'hABCD;
    #10;
    check_result();
    
    // Test 2: Zero test (other input)
    $display("Test 2: Zero test (other input)");
    a_tb = 16'h1234;
    b_tb = 16'h0000;
    #10;
    check_result();
    
    // Test 3: Max value test (unsigned)
    $display("Test 3: Max value test (unsigned)");
    a_tb = 16'hFFFF;
    b_tb = 16'hFFFF;
    #10;
    check_result();
    
    // Test 4: Small numbers
    $display("Test 4: Small numbers");
    a_tb = 16'd10;
    b_tb = 16'd20;
    #10;
    check_result();

    // Test 5: One max, one small
    $display("Test 5: One max, one small");
    a_tb = 16'hFFFF;
    b_tb = 16'd2;
    #10;
    check_result();
    
    // Start of random tests
    $display("--- Starting %0d Random Tests ---", NUM_RANDOM_TESTS);
    for (i = 0; i < NUM_RANDOM_TESTS; i = i + 1) begin
      a_tb = $random;
      b_tb = $random;
      #10;
      check_result();
    end
    
    $display("--- Testbench Finished ---");
    if (errors == 0) begin
      $display(">>> All tests PASSED <<<");
    end else begin
      $display(">>> %0d tests FAILED <<<", errors);
    end
    
    // VCD DUMP (for waveforms)
    // Vivado simulator will automatically pick up signals,
    // but this is good practice for other simulators.
    $dumpfile("mult_tb.vcd");
    $dumpvars(0, mult_tb);
    
    #20; // Allow final events to settle
    $finish;
  end
  
  // Verification task
  task check_result;
    begin
      // Check Array Multiplier
      if (p_array_tb === p_golden) begin
        $display("  [PASS] Array: %h * %h = %h", a_tb, b_tb, p_array_tb);
      end else begin
        $display("  [FAIL] Array: %h * %h = %h (Expected: %h)", a_tb, b_tb, p_array_tb, p_golden);
        errors = errors + 1;
      end
      
      // --- Add your check for Wallace-Tree here ---
      // if (p_wallace_tb === p_golden) begin
      //   ...
      // end else begin
      //   ...
      // end
      
    end
  endtask
  
endmodule