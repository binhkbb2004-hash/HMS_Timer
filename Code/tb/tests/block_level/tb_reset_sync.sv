`timescale 1ns / 1ps
module tb_reset_sync();
    logic clk, rstn;
    logic rstn_sync;

    reset_sync dut (.*); 

    initial begin clk = 0; forever #500 clk = ~clk; end

    // --- TASK ---
    task task_async_assert_reset();
        #1234; rstn = 0; 
        #5000; rstn = 1;
    endtask

    task task_short_reset_pulse();
        @(posedge clk);
        #100; rstn = 0; 
        #200; rstn = 1; 
    endtask

    task task_release_latency_2cyc();
        rstn = 0; #2000;
        rstn = 1; 
        repeat(5) @(posedge clk);
    endtask

    initial begin
        rstn = 1; #1000;
        $display("[TB] Chay task_async_assert_reset..."); task_async_assert_reset();
        $display("[TB] Chay task_short_reset_pulse...");  task_short_reset_pulse();
        $display("[TB] Chay task_release_latency_2cyc..."); task_release_latency_2cyc();
        #2000; $stop;
    end
endmodule