`timescale 1ns / 1ps
module tb_clock_divider();
    reg  clk;
    reg  rstn_sync;
    wire pulse_1ms;
    wire pulse_1s;

    clock_divider dut (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .pulse_1s(pulse_1s)
    );

    initial begin
        clk = 0;
        forever #500 clk = ~ clk;
    end

    time t_ms1, t_ms2;       // Lưu thời điểm xuất hiện pulse_1ms
    integer ms_pulse_cnt;    // đếm số lượng xung pulse_1ms

    always @(posedge pulse_1ms) begin
        if (rstn_sync) ms_pulse_cnt = ms_pulse_cnt + 1;
    end

    initial begin
        rstn_sync = 0;
        ms_pulse_cnt = 0;

        $display(" --- START --- ");
        
        #1500 rstn_sync = 1;

        // TESTCASE 1: Kiểm tra khoảng cách giữa 2 xung pulse_1ms
        @(posedge pulse_1ms); 
        t_ms1 = $time;
        
        @(posedge pulse_1ms);
        t_ms2 = $time;
        
        if ((t_ms2 - t_ms1) == 1000000) begin
            $display("[PASS] Testcase 1: pulse_1ms phat ra dung moi 1,000,000 ns (1ms).");
        end else begin
            $display("[FAIL] Testcase 1: pulse_1ms sai chu ky! Thuc te: %0t ns", (t_ms2 - t_ms1));
        end

        // TESTCASE 2: Kiểm tra cờ pulse_1s (Phải đợi đủ 1000 xung pulse_1ms)
        @(posedge pulse_1s);
        
        if (ms_pulse_cnt == 1000) begin
            $display("[PASS] Testcase 2: pulse_1s xuat hien sau dung 1000 nhip pulse_1ms.");
        end else begin
            $display("[FAIL] Testcase 2: So xung 1ms da dem duoc: %0d (Ky vong: 1000)", ms_pulse_cnt);
        end
        #10000;
        $stop;
    end

endmodule