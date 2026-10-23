`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 17:17:05
// Design Name: 
// Module Name: divider_4bit
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


module divider_4bit (
    input  wire [3:0] A,              // Dividend
    input  wire [3:0] B,              // Divisor
    output reg  [3:0] Quotient,
    output reg  [3:0] Remainder,
    output wire       DivideByZero
);

    reg [4:0] rem_work;
    reg [4:0] divisor_ext;

    integer i;

    // Detect division by zero
    assign DivideByZero = (B == 4'b0000);

    always @(*) begin
        Quotient  = 4'b0000;
        Remainder = 4'b0000;
        rem_work  = 5'b00000;
        divisor_ext = {1'b0, B};

        if (B != 4'b0000) begin

            // Restoring division
            for (i = 3; i >= 0; i = i - 1) begin

                // Shift in the next dividend bit
                rem_work = {rem_work[3:0], A[i]};

                // Subtract divisor if remainder is large enough
                if (rem_work >= divisor_ext) begin
                    rem_work = rem_work - divisor_ext;
                    Quotient[i] = 1'b1;
                end

            end

            Remainder = rem_work[3:0];

        end
    end

endmodule
