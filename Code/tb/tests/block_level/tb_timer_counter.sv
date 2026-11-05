`timescale 1ns / 1ps
module tb_timer_counter();
    logic clk, rstn_sync, pulse_1s;
    logic pause_cnt, set_h, set_m, set_s;
    logic up_tick, down_tick;
    logic [4:0] h_out; logic [5:0] m_out; logic [5:0] s_out;

    timer_counter dut (.*);

    initial begin clk = 0; forever #500 clk = ~clk; end

    task pump_1s(int times);
        repeat(times) begin
            @(posedge clk); pulse_1s = 1;
            @(posedge clk); pulse_1s = 0;
            #1000;
        end
    endtask

    task press_up(); @(posedge clk); up_tick = 1; @(posedge clk); up_tick = 0; #1000; endtask
    task press_down(); @(posedge clk); down_tick=1; @(posedge clk); down_tick=0; #1000; endtask

    // --- TASK ---
    task task_full_day_wrap();
        pause_cnt = 1; 
        set_h = 1; repeat(23) press_up(); set_h = 0;
        set_m = 1; repeat(59) press_up(); set_m = 0;
        set_s = 1; repeat(59) press_up(); set_s = 0;
        
        pause_cnt = 0; // Thả cho đếm
        pump_1s(2); // Cấp 2 giây (sẽ tràn 23:59:59 -> 00:00:00 -> 00:00:01)
    endtask

    task task_set_m_down();
        pause_cnt = 1; set_m = 1;
        press_down(); // Trừ qua 0 -> 59
        press_down(); // Xuống 58
        set_m = 0; pause_cnt = 0;
    endtask

    initial begin
        rstn_sync=0; pulse_1s=0; pause_cnt=0;
        set_h=0; set_m=0; set_s=0; up_tick=0; down_tick=0;
        #1500; rstn_sync = 1; #2000;

        $display("[TB] Test tran ngay 23:59:59 -> 00:00:00"); task_full_day_wrap();
        $display("[TB] Test down Phut 00 -> 59"); task_set_m_down();
        $stop;
    end
endmodule