`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_array
// Description: 
//   Testbench for the 16-bit, combinational 'array_multiplier'.
//   It uses the *exact same test vectors* as the tb_wallace file.
//////////////////////////////////////////////////////////////////////////////////

module tb_array;

    // --- Testbench Signals ---
    reg  [15:0] A;
    reg  [15:0] B;

    // Output from UUT
    wire [31:0] P;
    
    // Golden reference
    wire [31:0] p_golden;
    // We use a register for the golden value to match the
    // stimulus timing correctly.
    reg [31:0] p_golden_reg;
    assign p_golden = {16'b0, A} * {16'b0, B};

    // --- Instantiate the Unit Under Test (UUT) ---
    array_multiplier uut (
        .a(A), 
        .b(B), 
        .p(P)
    );

    // --- Testbench Globals ---
    integer i;
    integer error_count = 0;
    
    // Verification task
    task check_result;
        begin
            // We must add a small delay for the
            // combinational logic of the UUT to settle.
            #1; 
            if (P === p_golden) begin
                $display("PASS: %d * %d = %d", A, B, P);
            end else begin
                $display("FAIL: %d * %d = %d (Expected: %d)", A, B, P, p_golden);
                error_count = error_count + 1;
            end
        end
    endtask

    // --- Main Simulation Block (Stimulus) ---
    // This uses the *exact same test vectors* as the wallace testbench
    initial begin
        $display("Starting 16-bit Array Multiplier Testbench...");
        A = 0;
        B = 0;
        #20; // Initial delay
        
        // --- Apply Test Cases (one per 10ns) ---
        $display("--- Running Edge Cases ---");
        A = 16'd0;     B = 16'd12345; #10; check_result();
        A = 16'd1;     B = 16'd54321; #10; check_result();
        A = 16'hFFFF;  B = 16'hFFFF;  #10; check_result();
        A = 16'hFFFF;  B = 16'd1;     #10; check_result();
        A = 16'd256;   B = 16'd256;   #10; check_result();
        A = 16'd10;    B = 16'd20;    #10; check_result();

        // --- Running Random Test Cases ---
        $display("--- Running 20 Random Unsigned Test Cases ---");
        for (i = 0; i < 20; i = i + 1) begin
            // Apply new inputs
            A = $random;
            B = $random;
            // Wait 10ns (like the wallace TB)
            #10;
            // Check the result
            check_result();
        end
        
        // --- Summary ---
        if (error_count == 0) begin
            $display("All tests passed!");
        end else begin
            $display("Testbench FAILED with %d errors.", error_count);
        end

        $display("Testbench finished.");
        $finish;
    end
    
    // VCD dump for waveform
    initial begin
        $dumpfile("tb_array.vcd");
        $dumpvars(0, tb_array);
    end

endmodule