`timescale 1ns / 1ps
module tb_reset_sync();

    reg  clk;
    reg  rstn;
    wire rstn_sync;

    // DUT
    reset_sync dut (
        .clk(clk),
        .rstn(rstn),
        .rstn_sync(rstn_sync)
    );

    // Clock (1 MHz -> clock cycle 1000ns)
    initial begin
        clk = 0;
        forever begin
        #500 clk = ~clk;
        end
    end

    initial begin
        rstn = 1;

        repeat (2) @(negedge clk);

        rstn = 0; 
        
        repeat (5) @(negedge clk); 

        rstn = 1;
        
        #3000;

        $stop;
    end

endmodule