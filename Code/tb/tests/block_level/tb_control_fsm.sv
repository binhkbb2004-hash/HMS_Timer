`timescale 1ns / 1ps

module tb_control_fsm();
    logic clk, rstn_sync, pulse_1ms;
    logic sel_tick, up_tick, down_tick;
    logic pause_cnt, set_h, set_m, set_s;

    control_fsm dut (.*);

    initial begin clk = 0; forever #500 clk = ~clk; end
    
    // TẠO PULSE_1MS 5 nhịp clk = 1ms thay vì 1000
    logic [9:0] ms_cnt;
    always_ff @(posedge clk) begin
        if (ms_cnt == 4) begin ms_cnt <= 0; pulse_1ms <= 1; end 
        else begin ms_cnt <= ms_cnt + 1; pulse_1ms <= 0; end
    end

    // --- TASK ---
    task press_sel(); @(posedge clk); sel_tick = 1; @(posedge clk); sel_tick = 0; endtask
    task press_up();  @(posedge clk); up_tick = 1;  @(posedge clk); up_tick = 0;  endtask

    task task_full_ring_walk();
        press_sel(); #5000; // N -> H
        press_sel(); #5000; // H -> M
        press_sel(); #5000; // M -> S
        press_sel(); #5000; // S -> N
    endtask

    task task_wdog_timeout_5s();
        press_sel(); // Vào SET_H
        repeat(5100) @(posedge pulse_1ms); 
    endtask

    task task_wdog_extend_near_timeout();
        press_sel(); // Vào SET_H
        repeat(4998) @(posedge pulse_1ms); // Sát mép 5s
        press_up(); // Bấm vớt vát để kéo dài thời gian
        repeat(2000) @(posedge pulse_1ms); // Đợi thêm 2s
        press_sel(); press_sel(); press_sel(); // Về NORMAL
    endtask

    initial begin
        rstn_sync = 0; sel_tick = 0; up_tick = 0; down_tick = 0;
        #1500; rstn_sync = 1; ms_cnt = 0; #2000;

        $display("[TB] Xoay vong FSM..."); task_full_ring_walk();
        $display("[TB] Test Timeout 5s..."); task_wdog_timeout_5s();
        $display("[TB] Test keo dai wdog..."); task_wdog_extend_near_timeout();
        
        $display("---------------------------------------------------------");
        $display(" FINISHED BLOCK-LEVEL VERIFICATION: tb_control_fsm       ");
        $display("---------------------------------------------------------");
        $stop;
    end
endmodule