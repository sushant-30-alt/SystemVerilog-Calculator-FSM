`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 16:38:01
// Design Name: 
// Module Name: subtractor_4bit
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




module subtractor_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire signed [7:0] Difference
);

    wire [3:0] B_complement;
    wire [3:0] diff_4bit;
    wire       Cout;

    wire [3:0] A_complement;
    wire [3:0] negative_magnitude;
    wire       unused_cout;

    // A - B = A + ~B + 1
    assign B_complement = ~B;

    ripple_carry_adder_4bit RCA_SUB (
        .A(A),
        .B(B_complement),
        .Cin(1'b1),
        .Sum(diff_4bit),
        .Cout(Cout)
    );

    // When A < B, calculate B - A to obtain the magnitude.
    assign A_complement = ~A;

    ripple_carry_adder_4bit RCA_MAG (
        .A(B),
        .B(A_complement),
        .Cin(1'b1),
        .Sum(negative_magnitude),
        .Cout(unused_cout)
    );

    // Convert the magnitude to a signed 8-bit result.
    assign Difference = Cout
                      ? {4'b0000, diff_4bit}
                      : -$signed({4'b0000, negative_magnitude});

endmodule


