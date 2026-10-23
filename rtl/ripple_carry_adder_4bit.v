`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2026 13:39:05
// Design Name: 
// Module Name: ripple_carry_adder_4bit
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



module ripple_carry_adder_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       Cout
);

    wire c1, c2, c3;

    full_adder FA0 (
        .A(A[0]), .B(B[0]), .Cin(Cin),
        .S(Sum[0]), .Cout(c1)
    );

    full_adder FA1 (
        .A(A[1]), .B(B[1]), .Cin(c1),
        .S(Sum[1]), .Cout(c2)
    );

    full_adder FA2 (
        .A(A[2]), .B(B[2]), .Cin(c2),
        .S(Sum[2]), .Cout(c3)
    );

    full_adder FA3 (
        .A(A[3]), .B(B[3]), .Cin(c3),
        .S(Sum[3]), .Cout(Cout)
    );

endmodule

