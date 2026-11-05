// =========================================================================
// Constrained-Random
// =========================================================================
`timescale 1ns / 1ps

module tb_hms_timer_rand();
    // Định nghĩa hằng số 1ms dựa trên timescale 1ns
    localparam time MS = 1000000;

    logic clk, rstn, sel_in, up_in, down_in;
    logic [1:0] adj_fld_o;
    logic [4:0] h_out; logic [5:0] m_out; logic [5:0] s_out;

    hms_timer dut (.*);

    initial begin 
        clk = 0; 
        forever #500 clk = ~clk; 
    end

    class ButtonEvent;
    // Các biến ngẫu nhiên
    rand bit press_sel;
    rand bit press_up;
    rand bit press_down;
    
    rand int hold_time_ms;
    rand int idle_time_ms;

    constraint c_buttons {
        // Tỷ lệ nhấn phím:
        press_sel  dist {1 := 50, 0 := 50}; // 50% ấn 50% không
        press_up   dist {1 := 40, 0 := 60}; // 40% ấn 60% không
        press_down dist {1 := 40, 0 := 60}; // 40% ấn 60% không

        // không bấm 2 nút cùng lúc 
        (press_sel + press_up + press_down) <= 1;

        // Thời gian nhấn phím
        hold_time_ms dist {
            [1:15]      :/ 15,   // 15% bấm 1 - 15 ms
            [30:70]     :/ 85    // 85% bấm 30 - 70 ms
        };

        // Thời gian nghỉ giữa các lần bấm
        idle_time_ms dist {
            [1:15]      :/ 10, // 10% nghỉ 1 - 15 ms
            [100:500]   :/ 70, // 70% nghỉ 100 - 500 ms
            [5010:6000] :/ 20  // 20% Bỏ đi uống nước (nghỉ hơn 5s)
        };
    }

    endclass

    initial begin
        ButtonEvent btn_event;    
        btn_event = new();
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #1500 rstn = 1;

        #(300 * MS);

        // ===========================================================
        //   ------- DIREC TEST DE PHU COVERAGE VA SVA ----------
        // ===========================================================

        // -----------------------------------------------------------
        // Kịch bản 1: Cờ timeout bật ở các trạng thái SET
        // -----------------------------------------------------------

        // 1. Quét nhánh timeout ở trạng thái SET_H 
        $display("Cho co Timeout bat o cac che do SET_H, SET_M, SET_S");
        @(negedge clk);
        sel_in = 1;
        #(50 * MS); sel_in = 0;  // Bấm SEL 1 lần để vào SET_H
        $display("Dang o SET_H. Cho 6 giay de Watchdog kich hoat...");
        #(6000 * MS);            

        // 2. Quét nhánh timeout ở trạng thái SET_M 
        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);                         
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_M
        $display("Dang o SET_M. Cho 6 giay de Watchdog kich hoat...");
        #(6000 * MS); 

        // 3. Quét nhánh timeout ở trạng thái SET_S 
        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_M
        #(200 * MS);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_S
        $display("Dang o SET_S. Cho 6 giay de Watchdog kich hoat...");
        #(6000 * MS); 

        // -----------------------------------------------------------
        // Kịch bản 2: Săn Assertion ap_pause_blocks_1s (Đóng băng đếm giờ)
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra Dong bang thoi gian (Pause Blocks 1s)...");
        
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0; // Đẩy vào SET_H
        
        $display("Dang o SET_H, cho im lang 3 giay ...");
        #(3000 * MS); 
        
        // Bấm SEL để đưa FSM về lại NORMAL một cách an toàn
        sel_in = 1; #(50 * MS); sel_in = 0; // Sang SET_M
        #(100 * MS);
        sel_in = 1; #(50 * MS); sel_in = 0; // Sang SET_S
        #(100 * MS);
        sel_in = 1; #(50 * MS); sel_in = 0; // Về lại NORMAL
        #(100 * MS); // Chờ ổn định ở NORMAL

        // -----------------------------------------------------------
        // Kịch bản 3: Ép tràn thời gian 23:59:59 -> 00:00:01
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian 23:59:59 -> 00:00:01 ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        // Ép thời gian về gần sát ngưỡng tràn 23:59:59
        force dut.u_timer_counter.h_out = 5'd23;
        force dut.u_timer_counter.m_out = 6'd59;
        force dut.u_timer_counter.s_out = 6'd58; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        // Chờ qua 15s để mạch tự nhảy: 23:59:59 -> 00:00:00 -> 00:00:01
        #(15000 * MS);

        // -----------------------------------------------------------
        // Kịch bản 4: Ép tràn thời gian 02:59:58 -> 03:00:01
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian 02:59:58 -> 03:00:01 ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        // Ép thời gian về gần sát ngưỡng tràn 02:59:58
        force dut.u_timer_counter.h_out = 5'd02;
        force dut.u_timer_counter.m_out = 6'd59;
        force dut.u_timer_counter.s_out = 6'd58; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        // Chờ qua 15s để mạch tự nhảy:
        #(15000 * MS);

        // -----------------------------------------------------------
        // Kịch bản 5: Tràn thời gian khi sửa SET_H up
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian khi sua SET_H up ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        force dut.u_timer_counter.h_out = 5'd23;
        force dut.u_timer_counter.m_out = 6'd50;
        force dut.u_timer_counter.s_out = 6'd10; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);                         
        up_in = 1; #(50 * MS); up_in = 0;    
        #(200 * MS);
        up_in = 1; #(50 * MS); up_in =0;
        #(6000 * MS);


        // -----------------------------------------------------------
        // Kịch bản 6: Tràn thời gian khi sửa SET_H down
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian khi sua SET_H down ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        force dut.u_timer_counter.h_out = 5'd00;
        force dut.u_timer_counter.m_out = 6'd59;
        force dut.u_timer_counter.s_out = 6'd30; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);                         
        down_in = 1; #(50 * MS); down_in = 0;  
        #(200 * MS);
        down_in = 1; #(50 * MS); down_in =0;
        #(6000 * MS);

        // -----------------------------------------------------------
        // Kịch bản 7: Tràn thời gian khi sửa SET_M up
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian khi sua SET_M up ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        force dut.u_timer_counter.h_out = 5'd22;
        force dut.u_timer_counter.m_out = 6'd59;
        force dut.u_timer_counter.s_out = 6'd40; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);                         
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_M
        #(200 * MS);
        up_in = 1; #(50 * MS); up_in = 0;    // Tăng phút để tràn về 00
        #(200 * MS);
        up_in = 1; #(50 * MS); up_in =0;
        #(6000 * MS);


        // -----------------------------------------------------------
        // Kịch bản 8: Ép tràn thời gian SET_M down
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian khi sua SET_M down ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        force dut.u_timer_counter.h_out = 5'd22;
        force dut.u_timer_counter.m_out = 6'd00;
        force dut.u_timer_counter.s_out = 6'd54; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);                         
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_M
        #(200 * MS);
        down_in = 1; #(50 * MS); down_in = 0;  // Giảm phút để tràn về 59
        #(200 * MS);
        down_in = 1; #(50 * MS); down_in =0;
        #(6000 * MS);

        // -----------------------------------------------------------
        // Kịch bản 9: Tràn thời gian khi sửa SET_S up
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian SET_S up ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        force dut.u_timer_counter.h_out = 5'd03;
        force dut.u_timer_counter.m_out = 6'd30;
        force dut.u_timer_counter.s_out = 6'd59; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);                         
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_M
        #(200 * MS);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_S
        #(200 * MS);
        up_in = 1; #(50 * MS); up_in = 0;    // Tăng để tràn về 00
        #(200 * MS);
        up_in = 1; #(50 * MS); up_in =0;
        #(6000 * MS);


        // -----------------------------------------------------------
        // Kịch bản 10: Ép tràn thời gian SET_S down 
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra tran thoi gian SET_S down ...");
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);
        
        force dut.u_timer_counter.h_out = 5'd03;
        force dut.u_timer_counter.m_out = 6'd32;
        force dut.u_timer_counter.s_out = 6'd00; 

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        @(negedge clk);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL vào SET_H
        #(200 * MS);                         
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_M
        #(200 * MS);
        sel_in = 1; #(50 * MS); sel_in = 0;  // Bấm SEL chuyển sang SET_S
        #(200 * MS);
        down_in = 1; #(50 * MS); down_in = 0;  // Giảm để tràn về 59
        #(200 * MS);
        down_in = 1; #(50 * MS); down_in =0;
        #(6000 * MS);

        // -----------------------------------------------------------
        // Kịch bản 11: Kích hoạt Reset Synchronizer
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra SVA Reset Synchronizer...");
        
        @(negedge clk);
        rstn = 1'b0;  
        #(37 * MS); 
        rstn = 1'b1;  
        #(200 * MS);


        // -----------------------------------------------------------
        // Kịch bản 12: Vét cạn các tổ hợp biên Cross Coverage (cx_h_m & cx_m_s)
        // -----------------------------------------------------------
        $display("Kich hoat kiem tra vet can Cross Coverage (cx_h_m & cx_m_s)...");

        // 12.1. Quét <h_max, m_zero> (23:00:xx): Đếm từ 22:59:58 -> 23:00:01
        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;
        #(300 * MS);

        force dut.u_timer_counter.h_out = 5'd22;
        force dut.u_timer_counter.m_out = 6'd59;
        force dut.u_timer_counter.s_out = 6'd58;

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        // Chờ 5s để nhảy qua 22:59:59 -> 23:00:00 (<h_max, m_zero>) -> 23:00:01
        #(5000 * MS);

        // 12.2. Quét <m_max, s_zero> (xx:59:00): Đếm từ 00:58:58 -> 00:59:01
        force dut.u_timer_counter.h_out = 5'd00;
        force dut.u_timer_counter.m_out = 6'd58;
        force dut.u_timer_counter.s_out = 6'd58;

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        // Chờ 5s để nhảy qua 00:58:59 -> 00:59:00 (<m_max, s_zero>) -> 00:59:01
        #(5000 * MS);

        // 12.3. Quét <m_zero, s_max> (xx:00:59): Đếm từ 00:00:58 -> 00:01:01
        force dut.u_timer_counter.h_out = 5'd00;
        force dut.u_timer_counter.m_out = 6'd00;
        force dut.u_timer_counter.s_out = 6'd58;

        @(posedge clk);
        #100;
        release dut.u_timer_counter.h_out;
        release dut.u_timer_counter.m_out;
        release dut.u_timer_counter.s_out;

        // Chờ 5s để nhảy qua 00:00:59 (<m_zero, s_max>) -> 00:01:00 -> 00:01:01
        #(5000 * MS);
        

        $display("=========================================================");
        $display(" START CONSTRAINED-RANDOM TEST (15000 EVENTS)    ");
        $display("=========================================================");

        $display(" Dang chay, hoi lau nen cho 1 ty ....    ");

        rstn = 0; sel_in = 0; up_in = 0; down_in = 0;
        #(600 * MS); rstn = 1;

        #(300 * MS);

        for (int i = 1; i <= 15000; i++) begin
            if (i % 1000 == 0) $display("   -> Da chay %0d random case ...", i);

            if (!btn_event.randomize()) $fatal("Lỗi Randomize!");

            sel_in  = btn_event.press_sel;
            up_in   = btn_event.press_up;
            down_in = btn_event.press_down;

            #(btn_event.hold_time_ms * MS); 

            sel_in = 0; up_in = 0; down_in = 0;

            #(btn_event.idle_time_ms * MS);
        end

        $display("=========================================================");
        $display(" COMPLETED 15000  RANDOM CASE               ");
        $display("=========================================================");

        
        $display("=========================================================");
        $display(" TAT CA CAC KICH BAN DA HOAN TAT!                        ");
        $display("=========================================================");
        $stop;
    end


    // =====================================================================
    // BINDING
    // =====================================================================

    // SVA Binding
    bind dut.u_reset_sync chk_reset_sync chk_rst_inst (.*);  

    bind dut.u_clock_divider chk_clock_divider chk_clk_inst (.*);  

    bind dut.u_button_processor.inst_sel chk_button chk_btn_sel_inst (.*);

    bind dut.u_button_processor.inst_up  chk_button chk_btn_up_inst (.*);

    bind dut.u_button_processor.inst_down chk_button chk_btn_down_inst (.*);
    
    bind dut.u_control_fsm chk_control_fsm chk_fsm_inst (.*);
    
    bind dut.u_timer_counter chk_timer_counter chk_timer_inst (.*);

    // Functional Coverage Binding
    bind dut cov_hms_timer cov_timer_inst (
        .clk           (clk),
        .rstn_sync     (w_rstn_sync),
        .current_state (u_control_fsm.current_state),
        .h_out         (h_out),
        .m_out         (m_out),
        .s_out         (s_out)
    );
    
endmodule