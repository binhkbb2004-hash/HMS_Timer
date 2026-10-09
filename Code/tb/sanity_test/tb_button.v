`timescale 1ns / 1ps
module tb_button();
    reg  clk;
    reg  rstn_sync;
    reg  pulse_1ms;
    reg  btn_in;
    wire btn_tick;

    button dut (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .btn_in(btn_in),
        .btn_tick(btn_tick)
    );

    initial begin
        clk = 0;
        forever #500 clk = ~clk;
    end

    reg [9:0] cnt_1ms;
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            cnt_1ms <= 0;
            pulse_1ms <= 0;
        end else begin
            if (cnt_1ms == 999) begin
                cnt_1ms <= 0;
                pulse_1ms <= 1;
            end else begin
                cnt_1ms <= cnt_1ms + 1;
                pulse_1ms <= 0;
            end
        end
    end

    integer tick_cnt;

    always @(posedge clk) begin
        if (btn_tick) tick_cnt = tick_cnt + 1;
    end

    initial begin
        rstn_sync = 0; 
        btn_in = 0;
        tick_cnt = 0;

        $display(" --- START --- ");

        #1500 rstn_sync = 1;

        // TESTCASE 1: tín hiệu in ổn định < 20ms 
        $display ("TESTCASE 1: tin hieu in on dinh < 20ms");
        tick_cnt = 0;
        
        btn_in = 1; #5000000; // Bấm 5ms
        btn_in = 0; #2000000; // Nhả 2ms
        btn_in = 1; #10000000;  // Bấm 10ms
        btn_in = 0; #10000000;  // Nhả 10ms

        #5000000; 

        if (tick_cnt == 0) begin
            $display("  -> [PASS] Tin hieu in chua on dinh du 20ms thi khong co xung tick");
        end else begin
            $display("  -> [FAIL] Sinh ra %0d tick khi co nhieu", tick_cnt);
        end

        // TESTCASE 2: tín hiệu in ổn định > 20ms
        $display ("TESTCASE 2: tin hieu in on dinh > 20ms");
        tick_cnt = 0;
        
        btn_in = 1; #2000000; // Bấm 2ms
        btn_in = 0; #1000000; // Nhả 1ms
        
        // Bấm ổn định 30ms
        btn_in = 1;
        #30000000;

        if (tick_cnt == 1) begin
            $display("  -> [PASS] Bat dung 1 tick sau khi phim on dinh 20ms.");
        end else begin
            $display("  -> [FAIL] Sinh ra %0d tick", tick_cnt);
        end

        // TESTCASE 3: Nhả phím có xuất hiện nhiễu
        $display("TESTCASE 3: Nha phim co nhieu");
        tick_cnt = 0; 
        
        btn_in = 0; #3000000;   // Nhả 3ms
        btn_in = 1; #2000000;   // Bấm 2ms
        
        // Nhả 30ms
        btn_in = 0; 
        #30000000;

        if (tick_cnt == 0) begin
            $display("  -> [PASS] Khong sinh ra tick nao khi nha phim.");
        end else begin
            $display("  -> [FAIL] Sinh ra %0d tick khi nha phim.", tick_cnt);
        end
        #10000;
        $stop;
    end
endmodule