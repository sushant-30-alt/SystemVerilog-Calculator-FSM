`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 22:37:25
// Design Name: 
// Module Name: calculator_top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////




module calculator_top_tb;

    // Testbench signals
    logic clk;
    logic reset;
    logic start;

    logic [3:0] A;
    logic [3:0] B;
    logic [1:0] op;

    logic [7:0] result;
    logic [3:0] remainder;
    logic done;
    logic error;

    integer pass_count;
    integer fail_count;
    integer done_pulses;

    // Instantiate the calculator under test
    calculator_top uut (
        .clk       (clk),
        .reset     (reset),
        .start     (start),
        .A         (A),
        .B         (B),
        .op        (op),
        .result    (result),
        .remainder (remainder),
        .done      (done),
        .error     (error)
    );

    // Generate a 10 ns clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Apply one request and check its result
    task automatic run_test(
        input logic [3:0] test_A,
        input logic [3:0] test_B,
        input logic [1:0] test_op,
        input logic [7:0] expected_result,
        input logic [3:0] expected_remainder,
        input logic       expect_error
    );
        integer cycles;
        logic completed;

        begin
            // Apply request on a falling clock edge
            @(negedge clk);
            A     = test_A;
            B     = test_B;
            op    = test_op;
            start = 1'b1;

            completed = 1'b0;

            // Allow time for EXECUTE and DONE/ERROR
            for (cycles = 0; cycles < 6; cycles = cycles + 1) begin
                @(posedge clk);
                #1;

                if (done || error) begin
                    completed = 1'b1;
                    cycles = 6;
                end
            end

            if (!completed) begin
                $display("FAIL: Timeout, A=%0d B=%0d op=%b",
                         test_A, test_B, test_op);
                fail_count = fail_count + 1;
            end
            else if (expect_error) begin
                if (error && !done) begin
                    $display("PASS: Division by zero detected");
                    pass_count = pass_count + 1;
                end
                else begin
                    $display("FAIL: Expected error, done=%b error=%b",
                             done, error);
                    fail_count = fail_count + 1;
                end
            end
            else begin
                if (done && !error &&
                    result == expected_result &&
                    remainder == expected_remainder) begin

                    $display(
                        "PASS: A=%0d B=%0d op=%b result=%0d remainder=%0d",
                        test_A, test_B, test_op, result, remainder
                    );
                    pass_count = pass_count + 1;
                end
                else begin
                    $display(
                        "FAIL: A=%0d B=%0d op=%b result=%0d expected=%0d rem=%0d expected_rem=%0d done=%b error=%b",
                        test_A, test_B, test_op, result,
                        expected_result, remainder,
                        expected_remainder, done, error
                    );
                    fail_count = fail_count + 1;
                end
            end

            // Release request and allow FSM to return to IDLE
            @(negedge clk);
            start = 1'b0;

            repeat (3) @(posedge clk);
            #1;
        end
    endtask

    // Main test sequence
    initial begin
        reset      = 1'b1;
        start      = 1'b0;
        A          = 4'b0;
        B          = 4'b0;
        op         = 2'b0;
        pass_count = 0;
        fail_count = 0;

        // Apply synchronous reset
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // Allow reset release to settle
        @(posedge clk);
        #1;

        // Addition: 3 + 5 = 8
        run_test(4'd3, 4'd5, 2'b00, 8'd8, 4'd0, 1'b0);

        // Subtraction: 3 - 5 = -2 = 8'hFE
        run_test(4'd3, 4'd5, 2'b01, 8'hFE, 4'd0, 1'b0);

        // Multiplication: 3 * 4 = 12
        run_test(4'd3, 4'd4, 2'b10, 8'd12, 4'd0, 1'b0);

        // Division: 13 / 4 = quotient 3, remainder 1
        run_test(4'd13, 4'd4, 2'b11, 8'd3, 4'd1, 1'b0);

        // Division by zero must assert error, not done
        run_test(4'd13, 4'd0, 2'b11, 8'd0, 4'd0, 1'b1);
        
                // Boundary tests
        run_test(4'd15, 4'd15, 2'b00, 8'd30, 4'd0, 1'b0);
        run_test(4'd0,  4'd15, 2'b10, 8'd0,  4'd0, 1'b0);
        run_test(4'd15, 4'd0,  2'b01, 8'd15, 4'd0, 1'b0);
        run_test(4'd15, 4'd4,  2'b11, 8'd3,  4'd3, 1'b0);
        run_test(4'd0,  4'd5,  2'b11, 8'd0,  4'd0, 1'b0);
        
        
        // Stress Test 1: Hold start HIGH
        done_pulses = 0;

        @(negedge clk);
        A     = 4'd3;
        B     = 4'd5;
        op    = 2'b00;
        start = 1'b1;

        // Keep start asserted for eight clock cycles
        repeat (8) begin
            @(posedge clk);
            #1;

            if (done)
                done_pulses = done_pulses + 1;
        end

        // Check that the request was executed only once
        if ((done_pulses == 1) && (result == 8'd8) && !error) begin
            $display("PASS: Held start produced exactly one completion");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "FAIL: Held start: done_pulses=%0d result=%0d error=%b",
                done_pulses, result, error
            );
            fail_count = fail_count + 1;
        end

        // Release start and allow the FSM to return to IDLE
        @(negedge clk);
        start = 1'b0;

        repeat (3) @(posedge clk);
        #1;
        
        
        // Stress Test 2: Change inputs after request acceptance
        @(negedge clk);
        A     = 4'd3;
        B     = 4'd5;
        op    = 2'b00;
        start = 1'b1;

        // Allow IDLE to accept and capture the request
        @(posedge clk);
        #1;

        // Change external inputs while the request is in progress
        @(negedge clk);
        A  = 4'd9;
        B  = 4'd9;
        op = 2'b10;

        // Wait for the original request to complete
        wait (done || error);
        #1;

        if (done && !error && result == 8'd8) begin
            $display("PASS: Input changes did not alter accepted request");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "FAIL: Input change test: result=%0d done=%b error=%b",
                result, done, error
            );
            fail_count = fail_count + 1;
        end

        // Release request and wait for the FSM to return to IDLE
        @(negedge clk);
        start = 1'b0;

        repeat (3) @(posedge clk);
        #1;
        
        // Stress Test 3: Recover after division-by-zero error
@(negedge clk);
A     = 4'd13;
B     = 4'd0;
op    = 2'b11;
start = 1'b1;

// Wait for the error response
wait (error);
#1;

if (error && !done) begin
    $display("PASS: Division-by-zero error detected");
    pass_count = pass_count + 1;
end
else begin
    $display("FAIL: Division-by-zero error detection");
    fail_count = fail_count + 1;
end

// Release start and allow FSM to return to IDLE
@(negedge clk);
start = 1'b0;
repeat (3) @(posedge clk);
#1;

// Submit a valid request
@(negedge clk);
A     = 4'd3;
B     = 4'd5;
op    = 2'b00;
start = 1'b1;

// Check successful recovery
wait (done);
#1;

if (done && !error && result == 8'd8) begin
    $display("PASS: Calculator recovered and completed next request");
    pass_count = pass_count + 1;
end
else begin
    $display("FAIL: Recovery result=%0d done=%b error=%b",
             result, done, error);
    fail_count = fail_count + 1;
end

// Release start
@(negedge clk);
start = 1'b0;
repeat (3) @(posedge clk);
#1;



        $display("--------------------------------");
        $display("Tests passed: %0d", pass_count);
        $display("Tests failed: %0d", fail_count);
        $display("--------------------------------");

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        $finish;
    end

endmodule

