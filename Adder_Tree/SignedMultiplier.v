`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.02.2026 22:38:48
// Design Name: 
// Module Name: SignedMultiplier
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


module SignedMultiplier #(parameter IN_WIDTH = 16)(
    input  signed [IN_WIDTH-1:0] in_a,
    input  signed [IN_WIDTH-1:0] in_b,
    output signed [(2*IN_WIDTH)-1:0] out_p
);
    assign out_p = in_a * in_b; 
endmodule
