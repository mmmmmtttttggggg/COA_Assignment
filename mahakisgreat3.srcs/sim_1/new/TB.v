`timescale 1ns / 1ps

module tb_multiplier;

    // --- Testbench Signals ---
    reg  [15:0] A;
    reg  [15:0] B;
    reg  clk;
    reg  rst;

    wire [31:0] P;
    wire p_valid;

    // --- Instantiate the Unit Under Test (UUT) ---
    wallace_16bit uut (
        .clk(clk),
        .rst(rst),
        .A(A), 
        .B(B), 
        .P(P),
        .p_valid(p_valid)
    );

    // --- Testbench Globals ---
    integer i;
    integer error_count = 0;
    
    // --- "Golden Model" Pipeline ---
    // This creates a 4-stage-deep pipeline for the inputs and the
    // expected result. This matches the 4-cycle latency of the UUT.
    localparam LATENCY = 4;
    reg [15:0] A_pipe[LATENCY-1:0];
    reg [15:0] B_pipe[LATENCY-1:0];
    reg [31:0] expected_pipe[LATENCY-1:0];

    // This block clocks the inputs and the expected result
    // through the "golden" pipeline.
    always @(posedge clk) begin
        if (rst) begin
            for(i=0; i<LATENCY; i=i+1) begin
                A_pipe[i] <= 0;
                B_pipe[i] <= 0;
                expected_pipe[i] <= 0;
            end
        end else begin
            A_pipe[0] <= A;
            B_pipe[0] <= B;
            expected_pipe[0] <= {16'b0, A} * {16'b0, B};
            
            for(i=1; i<LATENCY; i=i+1) begin
                A_pipe[i] <= A_pipe[i-1];
                B_pipe[i] <= B_pipe[i-1];
                expected_pipe[i] <= expected_pipe[i-1];
            end
        end
    end

    // --- Output Checker ---
    // This block checks the UUT output against the
    // "golden" pipeline output, but only when p_valid is high.
    always @(posedge clk) begin
        // We check one cycle *after* p_valid goes high, to allow
        // $display to see the final registered values correctly.
        if (!rst && p_valid) begin
            // The result at the *end* of the golden pipeline
            // should match the UUT's output.
            if (P === expected_pipe[LATENCY-1]) begin
                $display("PASS: %d * %d = %d", A_pipe[LATENCY-1], B_pipe[LATENCY-1], P);
            end else begin
                $display("FAIL: %d * %d = %d (Expected: %d)", A_pipe[LATENCY-1], B_pipe[LATENCY-1], P, expected_pipe[LATENCY-1]);
                error_count = error_count + 1;
            end
        end
    end

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period = 100MHz clock
    end

    // --- Main Simulation Block (Stimulus) ---
    initial begin
        $display("Starting 16-bit Pipelined Multiplier Testbench...");
        rst = 1;
        A = 0;
        B = 0;
        #20; // Hold reset
        rst = 0;
        #10; // Wait for reset to de-assert
        
        // --- Apply Test Cases (one per clock cycle) ---
        $display("--- Running Edge Cases ---");
        @(negedge clk); A = 16'd0;     B = 16'd12345; // Test Case 0
        @(negedge clk); A = 16'd1;     B = 16'd54321; // Test Case 1
        @(negedge clk); A = 16'hFFFF;  B = 16'hFFFF;  // Test Case 2
        @(negedge clk); A = 16'hFFFF;  B = 16'd1;     // Test Case 3
        @(negedge clk); A = 16'd256;   B = 16'd256;   // Test Case 4
        @(negedge clk); A = 16'd10;    B = 16'd20;    // Test Case 5

        // --- Running Random Test Cases ---
        $display("--- Running 20 Random Unsigned Test Cases ---");
        for (i = 0; i < 20; i = i + 1) begin
            @(negedge clk);
            A = $random;
            B = $random;
        end
        
        // --- Wait for the last test case to exit the pipeline ---
        // We need to wait LATENCY cycles + a buffer
        repeat(LATENCY + 2) @(negedge clk);
        
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
        $dumpfile("tb_multiplier.vcd");
        $dumpvars(0, tb_multiplier);
    end

endmodule