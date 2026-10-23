`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 22:17:08
// Design Name: 
// Module Name: calculator_top
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



module calculator_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,

    input  logic [3:0] A,
    input  logic [3:0] B,
    input  logic [1:0] op,

    output logic [7:0] result,
    output logic [3:0] remainder,

    output logic       done,
    output logic       error
);
    
    // Captured request
    logic [3:0] A_reg;
    logic [3:0] B_reg;
    logic [1:0] op_reg;

    // Moore FSM states
    typedef enum logic [2:0] {
        IDLE,
        EXECUTE,
        DONE,
        ERROR,
        WAIT_RELEASE
    } state_t;

    state_t current_state, next_state;

    // Arithmetic datapath signals
    logic [3:0] add_sum;
    logic       add_cout;

    logic signed [7:0] sub_difference;

    logic [7:0] mult_product;

    logic [3:0] div_quotient;
    logic [3:0] div_remainder;
    logic       divide_by_zero;

    // Selected arithmetic result
    logic [7:0] selected_result;
    logic [3:0] selected_remainder;

     
    // 1. Four-bit ripple-carry adder
    ripple_carry_adder_4bit u_adder (
        .A   (A_reg),
        .B   (B_reg),
        .Cin (1'b0),
        .Sum (add_sum),
        .Cout(add_cout)
    );

    // 2. Four-bit subtractor
    subtractor_4bit u_subtractor (
        .A         (A_reg),
        .B         (B_reg),
        .Difference(sub_difference)
    );

    // 3. Four-bit multiplier
    multiplier_4bit u_multiplier (
        .A(A_reg),
        .B(B_reg),
        .P(mult_product)
    );

    // 4. Four-bit divider
    divider_4bit u_divider (
        .A           (A_reg),
        .B           (B_reg),
        .Quotient    (div_quotient),
        .Remainder   (div_remainder),
        .DivideByZero(divide_by_zero)
    );
    
    
    // Select the result from the requested operation
    always_comb begin
        selected_result    = 8'b0;
        selected_remainder = 4'b0;

        case (op_reg)
            2'b00: begin
                selected_result = {add_cout, add_sum};
            end

            2'b01: begin
                selected_result = sub_difference;
            end

            2'b10: begin
                selected_result = mult_product;
            end

            2'b11: begin
                selected_result    = {4'b0000, div_quotient};
                selected_remainder = div_remainder;
            end

            default: begin
                selected_result    = 8'b0;
                selected_remainder = 4'b0;
            end
        endcase
    end
    
    
    // Sequential state register
    // Active-high synchronous reset
    always_ff @(posedge clk) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
   // Simulation-only FSM transition monitor
`ifndef SYNTHESIS
    state_t previous_state;

    initial previous_state = IDLE;

    always @(current_state) begin
        if (current_state !== previous_state) begin
            $display(
                "FSM_TRANSITION: %0d -> %0d at time %0t",
                previous_state,
                current_state,
                $time
            );
            previous_state = current_state;
        end
    end
`endif
    
    // Combinational next-state logic
    always_comb begin
        next_state = current_state;

        case (current_state)

            IDLE: begin
                if (start)
                    next_state = EXECUTE;
                else
                    next_state = IDLE;
            end

            EXECUTE: begin
                if ((op_reg == 2'b11) && divide_by_zero)
                    next_state = ERROR;
                else
                    next_state = DONE;
            end

            DONE: begin
                next_state = WAIT_RELEASE;
            end

            ERROR: begin
                next_state = WAIT_RELEASE;
            end

            WAIT_RELEASE: begin
                if (start)
                    next_state = WAIT_RELEASE;
                else
                    next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end
    
    
    // Request capture and output registers
    always_ff @(posedge clk) begin
        if (reset) begin
            A_reg     <= 4'b0;
            B_reg     <= 4'b0;
            op_reg    <= 2'b0;
            result    <= 8'b0;
            remainder <= 4'b0;
        end
        else begin
            // Accept a new request in IDLE
            if ((current_state == IDLE) && start) begin
                A_reg  <= A;
                B_reg  <= B;
                op_reg <= op;
            end

            // Capture successful result at the edge entering DONE
            if ((current_state == EXECUTE) &&
                !((op_reg == 2'b11) && divide_by_zero)) begin
                result    <= selected_result;
                remainder <= selected_remainder;
            end
        end
    end

    
    // Moore FSM outputs
    always_comb begin
        done  = 1'b0;
        error = 1'b0;

        case (current_state)
            DONE: begin
                done = 1'b1;
            end

            ERROR: begin
                error = 1'b1;
            end

            default: begin
                done  = 1'b0;
                error = 1'b0;
            end
        endcase
    end

endmodule

