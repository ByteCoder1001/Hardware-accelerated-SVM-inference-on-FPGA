`timescale 1ns / 1ps

module tb_Inference;

    // Parameters
    parameter dataWidth = 16;
    parameter numWeight = 8;

    // Inputs
    reg clk;
    reg rst;
    reg [dataWidth-1:0] myinput;
    reg myinputValid;

    // Outputs
    wire [dataWidth-1:0] out;
    wire outvalid;

    // Instantiate DUT
    Inference #(
        .numWeight(numWeight),
        .dataWidth(dataWidth),
        .weightFile("weights.mem"),
        .biasFile("bias.mem")
    ) dut (
        .clk(clk),
        .rst(rst),
        .myinput(myinput),
        .myinputValid(myinputValid),
        .out(out),
        .outvalid(outvalid)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Test vector storage (example sample)
    reg signed [15:0] testVector [0:numWeight-1];

    integer i;

    initial begin

        // Initialize clock
        clk = 0;
        rst = 1;
        myinputValid = 0;
        myinput = 0;

        // Example Q15 input vector
        // Replace with real dataset values if needed
        testVector[0] = 16'b0001011001000000; 
        testVector[1] = 16'b0010011000000000;
        testVector[2] = 16'b0001110000000000;
        testVector[3] = 16'b0000101000000000;
        testVector[4] = 16'b0000110000000000;
        testVector[5] = 16'b0010100000000000;
        testVector[6] = 16'b0001100000000000;
        testVector[7] = 16'b0001000000000000;

        // Reset pulse
        #20;
        rst = 0;

        #20;

        // Send input features sequentially
        for(i = 0; i < numWeight; i = i + 1)
        begin
            @(posedge clk);
            myinput <= testVector[i];
            myinputValid <= 1;
        end

        // Stop valid signal
        @(posedge clk);
        myinputValid <= 0;

        // Wait for output
        wait(outvalid);

        #10;

        // Display result
        if(out == 16'h0001)
            $display("Prediction: CLASS +1");
        else if(out == 16'hFFFF)
            $display("Prediction: CLASS -1");
        else
            $display("Unknown output");

        #50;
        $finish;

    end

endmodule
