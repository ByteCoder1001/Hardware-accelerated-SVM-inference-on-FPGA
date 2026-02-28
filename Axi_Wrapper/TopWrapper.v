`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.02.2026 18:58:44
// Design Name: 
// Module Name: TopWrapper
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


module TopWrapper #(parameter NUM_FEATURES = 8,DATA_WIDTH = 16, C_S_AXIS_TDATA_WIDTH = (NUM_FEATURES * DATA_WIDTH),C_M_AXIS_TDATA_WIDTH = 32)
(
    // System Clock and Active-Low Reset from the Zynq PS
    input  wire axi_clk,
    input  wire axi_reset_n,
    // AXI-STREAM SLAVE (From DMA MM2S to PL)
    input  wire [C_S_AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    input  wire                            s_axis_tvalid,
    output wire                            s_axis_tready,
    input  wire                            s_axis_tlast,
    // AXI-STREAM MASTER (From PL to DMA S2MM)
    output wire [C_M_AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    output wire                            m_axis_tvalid,
    input  wire                            m_axis_tready,
    output wire                            m_axis_tlast
);

    // INTERNAL SIGNALS & INVERTERS
    wire rst_high = ~axi_reset_n; // Convert AXI active-low reset to active-high
    
    wire [15:0] raw_prediction;
    wire        svm_valid_out;

    // Handshake logic: Only push data into SVM when both Master and Slave are ready
    wire valid_in = s_axis_tvalid && s_axis_tready;

    // INSTANTIATE SVM 
    TopMod #(
        .NUM_FEATURES(NUM_FEATURES),
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(32)
    ) svm_inst (
        .clk(axi_clk),
        .rst(rst_high),
        .enable(m_axis_tready),
        .in_features_flat(s_axis_tdata),
        .valid_in(s_axis_tvalid),           // Trigger only on a valid AXI handshake
        //.valid_in(valid_in), 
        .out_pred(raw_prediction),    // 16-bit raw prediction
        .valid_out(svm_valid_out)
    );

    // THE 'TLAST' SHIFT REGISTER (Pipeline Synchronization)
    // We need a 5-stage shift register to delay tlast so it perfectly 
    // aligns with the 5-clock-cycle mathematical latency of the SVM.
    localparam PIPELINE_DEPTH = 5; 
    reg [PIPELINE_DEPTH-1:0] tlast_pipe;

    always @(posedge axi_clk) begin
        if (rst_high) begin
            tlast_pipe <= 0;
        end else if (m_axis_tready) begin
            // Shift the incoming tlast signal down the pipe
            tlast_pipe <= {tlast_pipe[PIPELINE_DEPTH-2:0], (valid_in ? s_axis_tlast : 1'b0)};
        end
    end

    // MASTER OUTPUT ASSIGNMENTS
    // Pad the 16-bit prediction with 16 zeros to make it 32-bit aligned for the DMA
    assign m_axis_tdata  = {16'd0, raw_prediction};
    assign m_axis_tvalid = svm_valid_out;
    // Output the tlast signal exactly when the final sample's math is done
    assign m_axis_tlast  = tlast_pipe[PIPELINE_DEPTH-1];
    // The SVM is ready to accept new data AS LONG AS the receiving DMA channel is also ready to accept predictions.
    assign s_axis_tready = m_axis_tready;

endmodule

