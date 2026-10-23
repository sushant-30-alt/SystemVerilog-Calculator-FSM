`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 09:33:09
// Design Name: 
// Module Name: multiplier_4bit
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




module multiplier_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [7:0] P
);

    // Generate 16 partial products
    wire [3:0] pp0, pp1, pp2, pp3;

    and_gate AND0  (.a(A[0]), .b(B[0]), .y(pp0[0]));
    and_gate AND1  (.a(A[0]), .b(B[1]), .y(pp0[1]));
    and_gate AND2  (.a(A[0]), .b(B[2]), .y(pp0[2]));
    and_gate AND3  (.a(A[0]), .b(B[3]), .y(pp0[3]));

    and_gate AND4  (.a(A[1]), .b(B[0]), .y(pp1[0]));
    and_gate AND5  (.a(A[1]), .b(B[1]), .y(pp1[1]));
    and_gate AND6  (.a(A[1]), .b(B[2]), .y(pp1[2]));
    and_gate AND7  (.a(A[1]), .b(B[3]), .y(pp1[3]));

    and_gate AND8  (.a(A[2]), .b(B[0]), .y(pp2[0]));
    and_gate AND9  (.a(A[2]), .b(B[1]), .y(pp2[1]));
    and_gate AND10 (.a(A[2]), .b(B[2]), .y(pp2[2]));
    and_gate AND11 (.a(A[2]), .b(B[3]), .y(pp2[3]));

    and_gate AND12 (.a(A[3]), .b(B[0]), .y(pp3[0]));
    and_gate AND13 (.a(A[3]), .b(B[1]), .y(pp3[1]));
    and_gate AND14 (.a(A[3]), .b(B[2]), .y(pp3[2]));
    and_gate AND15 (.a(A[3]), .b(B[3]), .y(pp3[3]));

    // Align the partial-product rows
    wire [7:0] row0, row1, row2, row3;

    assign row0 = {4'b0000, pp0};
    assign row1 = {3'b000, pp1, 1'b0};
    assign row2 = {2'b00, pp2, 2'b00};
    assign row3 = {1'b0, pp3, 3'b000};

    // Add the rows using explicit HA/FA structures
    wire [7:0] sum01, sum012;

    adder8 ADD0 (.X(row0),  .Y(row1),  .S(sum01));
    adder8 ADD1 (.X(sum01), .Y(row2),  .S(sum012));
    adder8 ADD2 (.X(sum012),.Y(row3),  .S(P));

endmodule


// 8-bit ripple-carry adder built from HA and FA modules
module adder8 (
    input  wire [7:0] X,
    input  wire [7:0] Y,
    output wire [7:0] S
);

    wire [8:0] carry;

    // Least-significant bit uses a half adder
    half_adder HA0 (
        .A(X[0]), .B(Y[0]),
        .S(S[0]), .C(carry[1])
    );

    // Remaining bits use full adders
    genvar k;
    generate
        for (k = 1; k < 8; k = k + 1) begin : FA_STAGE
            full_adder FA (
                .A(X[k]),
                .B(Y[k]),
                .Cin(carry[k]),
                .S(S[k]),
                .Cout(carry[k+1])
            );
        end
    endgenerate

endmodule

