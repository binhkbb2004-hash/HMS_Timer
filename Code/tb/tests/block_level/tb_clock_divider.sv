`timescale 1ns / 1ps
module tb_clock_divider();
    logic clk, rstn_sync;
    logic pulse_1ms, pulse_1s;

    clock_divider dut (.*);

    initial begin clk = 0; forever #500 clk = ~clk; end

    // --- TASK ---
    task task_reset_during_count_1ms();
        repeat(500) @(posedge clk); // Đang đếm dở đến 500
        rstn_sync = 0; #2000; rstn_sync = 1; // Đập reset
    endtask

    task task_reset_during_count_1s();
        // Chờ đếm được khoảng 0.5s
        repeat(500000) @(posedge clk);
        rstn_sync = 0; #2000; rstn_sync = 1;
    endtask

    task task_long_run_10s();
        $display("[TB] Tua nhanh thoi gian 10 giay...");
        // 10 giây = 10,000,000 chu kỳ clk
        repeat(10000000) @(posedge clk); 
    endtask

    initial begin
        rstn_sync = 0; #1500; rstn_sync = 1;
        
        $display("[TB] Chay task_reset_during_count_1ms..."); task_reset_during_count_1ms();
        $display("[TB] Chay task_reset_during_count_1s...");  task_reset_during_count_1s();
        $display("[TB] Chay task_long_run_10s...");           task_long_run_10s();
        
        #5000; $stop;
    end
endmodule