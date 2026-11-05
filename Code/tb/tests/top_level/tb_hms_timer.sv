// =========================================================================
// Top-Level Verification: tb_hms_timer.sv (Directed Tests)
// Đã tối ưu Timeout bằng kỹ thuật Backdoor Force
// =========================================================================
`timescale 1ns / 1ps

module tb_hms_timer();

    logic clk, rstn;
    logic sel_in, up_in, down_in;
    logic [4:0] h_out; logic [5:0] m_out; logic [5:0] s_out;

    hms_timer dut (.*);

    initial begin clk = 0; forever #500 clk = ~clk; end

    task press_sel();  sel_in = 1;  #25000000; sel_in = 0;  #30000000; endtask
    task press_up();   up_in = 1;   #25000000; up_in = 0;   #30000000; endtask
    task press_down(); down_in = 1; #25000000; down_in = 0; #30000000; endtask

    task wait_real_sec(int sec);
        for(int i=0; i<sec; i++) repeat(1000) #1000000;
        #5000; 
    endtask

    task task_reset_in_set_mode();
        press_sel(); press_sel(); press_up(); 
        #1234; rstn = 0; #5000; rstn = 1; 
    endtask

    task task_e2e_day_rollover();
        press_sel(); press_down(); // H = 23
        press_sel(); press_down(); // M = 59
        press_sel(); repeat(10) press_down(); // S = 50
        press_sel(); // Về NORMAL -> 23:59:50
        wait_real_sec(12); // Chờ 12s -> Vòng về 00:00:02
    endtask

    task task_e2e_sel_bounce();
        repeat(5) begin sel_in = 1; #5000000; sel_in = 0; #2000000; end
    endtask

    // HACK THỜI GIAN WATCHDOG
    task task_e2e_wdog_from_set_h();
        $display("   [Teleport] Hack thoi gian Watchdog len sat 5s bang lenh Force...");
        press_sel(); // Vào SET_H
        
        // Tua nhanh thanh ghi wdog_cnt bên trong chip lên mốc 4995.
        // LƯU Ý: Đổi 'dut_fsm' thành tên instance FSM thực tế của bạn trong file hms_timer.v
        force dut.u_control_fsm.wdog_cnt = 13'd4995; 
        #5000; 
        release dut.u_control_fsm.wdog_cnt; // Trả lại tự do cho mạch tự đếm tiếp
        
        // Chờ 10 mili-giây (thay vì 6 giây) để mạch tự rớt về NORMAL
        repeat(10000) @(posedge clk); 
    endtask

    initial begin
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        $display("=========================================================");
        $display(" BẮT ĐẦU CHẠY DIRECTED TESTS CHO TOÀN HỆ THỐNG (E2E)     ");
        $display("=========================================================");

        #1500 rstn = 1; 
        wait_real_sec(1); // task_cold_reset_init

        $display(">> RUNNING: task_reset_in_set_mode..."); task_reset_in_set_mode();
        $display(">> RUNNING: task_e2e_day_rollover..."); task_e2e_day_rollover();
        $display(">> RUNNING: task_e2e_sel_bounce..."); task_e2e_sel_bounce();
        $display(">> RUNNING: task_e2e_wdog_from_set_h..."); task_e2e_wdog_from_set_h();

        $display("=========================================================");
        $display(" HOÀN THÀNH E2E TEST! HÃY KIỂM TRA LOG XEM CÓ LỖI SVA KHÔNG");
        $display("=========================================================");
        $stop;
    end
endmodule