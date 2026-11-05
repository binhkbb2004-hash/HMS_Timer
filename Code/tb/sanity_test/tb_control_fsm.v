`timescale 1ns / 1ps
module tb_control_fsm();
    reg clk;
    reg rstn;
    reg sel_in; 
    reg up_in;
    reg down_in;
    
    wire rstn_sync;
    wire pulse_1ms;
    wire pulse_1s;
    wire sel_tick;
    wire up_tick;
    wire down_tick;
    wire pause_cnt;
    wire set_h;
    wire set_m;
    wire set_s;
    
    //DUT
    reset_sync u_reset_sync (
        .clk(clk),
        .rstn(rstn),
        .rstn_sync(rstn_sync)
    );

    clock_divider u_clock_divider (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .pulse_1s(pulse_1s)
    );

    button_processor u_button_processor (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .sel_in(sel_in),
        .up_in(up_in),
        .down_in(down_in),
        .sel_tick(sel_tick),
        .up_tick(up_tick),
        .down_tick(down_tick)
    );

    control_fsm dut_fsm (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .sel_tick(sel_tick),
        .up_tick(up_tick),
        .down_tick(down_tick),
        .pause_cnt(pause_cnt),
        .set_h(set_h),
        .set_m(set_m),
        .set_s(set_s)
    );

    // Clock 1MHz
    initial begin
        clk = 0;
        forever #500 clk = ~clk; // Chu kỳ 1us (1MHz)
    end

    // --- Task mô phỏng ấn nút ---

    task press_sel();
        begin
            sel_in = 1;
            #25000000; //25ms
            sel_in = 0;
            #25000000; //25ms
        end
    endtask

    task press_up();
        begin
            up_in = 1;
            #25000000; //25ms
            up_in = 0;
            #25000000; //25ms
        end
    endtask

    task press_down();
        begin
            down_in = 1;
            #25000000; //25ms 
            down_in = 0;
            #25000000; //25ms
        end
    endtask


    initial begin
        rstn = 0;
        sel_in = 0; 
        up_in = 0; 
        down_in = 0;

        $display(" --- START --- ");

        #1500 rstn = 1;
        @(posedge rstn_sync);
        #1000;

        // --- TESTCASE 1: Chuyển trạng thái bằng sel_in ---

        $display("TESTCASE 1: Chuyen trang thai");
        
        if ({pause_cnt, set_h, set_m, set_s} == 4'b0000) begin
            $display("  -> [PASS] Output tai NORMAL chinh xac");
        end else begin 
            $display("  -> [FAIL] Sai Output o NORMAL.");
        end
        
        // Chuyển sang SET_H
        press_sel();
        if ({pause_cnt, set_h, set_m, set_s} == 4'b1100) begin
            $display("  -> [PASS] Da vao SET_H");
        end else begin 
            $display("  -> [FAIL] Khong the vao SET_H"); 
        end

        // Chuyển sang SET_M
        press_sel(); 
        if ({pause_cnt, set_h, set_m, set_s} == 4'b1010) begin
            $display("  -> [PASS] Da vao SET_M");
        end else begin 
            $display("  -> [FAIL] Khong the vao SET_M"); 
        end
        
        // Chuyển sang SET_S 
        press_sel(); 
        if ({pause_cnt, set_h, set_m, set_s} == 4'b1001) begin
            $display("  -> [PASS] Da vao SET_S.");
        end else begin 
            $display("  -> [FAIL] Khong the vao SET_S.");
        end

        // Chuyển về NORMAL
        press_sel();
        if ({pause_cnt, set_h, set_m, set_s} == 4'b0000) begin
            $display("  -> [PASS] Vong ve NORMAL");
        end else begin 
            $display("  -> [FAIL] Khong the vong ve NORMAL");
        end


        // --- TESTCASE 2: Watchdog chờ không đủ 5s ---
    
        $display("TESTCASE 2: Watchdog khong du 5s");
        
        // Chuyển về SET_H
        press_sel();
        
        // Đợi 3 giây 
        repeat (3000) #1000000; 
        
        // Ấn nút Up reset Wathdog
        press_up();
        
        // Đợi thêm 3 giây nữa
        repeat (3000) #1000000; 
        
        if (pause_cnt == 1'b1 && set_h == 1'b1) begin
            $display("  -> [PASS] FSM van o SET_H Watchdog chay dung");
        end else begin 
            $display("  -> [FAIL] Watchdog loi.");
        end

    
        // --- TESTCASE 3: Watchdog chờ đủ 5s ---

        $display("[TEST 3] Watchdog cho du 5s");
        
        press_down();
        repeat (5100) #1000000; 
        
        if ({pause_cnt, set_h, set_m, set_s} == 4'b0000) begin 
            $display("  -> [PASS] FSM da Timeout va thoat ve NORMAL");
        end else begin 
            $display("  -> [FAIL] FSM khong thoat khi Timeout"); 
        end

        $display(" --- END --- ");

        #1000000;

        $stop;
    end
endmodule