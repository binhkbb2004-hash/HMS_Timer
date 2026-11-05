`timescale 1ns / 1ps

module tb_button();

    logic clk;
    logic rstn_sync;
    logic pulse_1ms;
    logic btn_in;
    
    logic btn_meta, btn_sync, btn_clean;
    logic [4:0] debounce_cnt;
    logic btn_tick;

    button dut (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .btn_in(btn_in),
        .btn_tick(btn_tick)
    );

    assign btn_meta = dut.btn_meta;
    assign btn_sync = dut.btn_sync;
    assign btn_clean = dut.btn_clean;
    assign debounce_cnt = dut.debounce_cnt;

    initial begin
        clk = 0;
        forever #500 clk = ~clk; // 1MHz
    end

    logic [9:0] ms_cnt;
    always_ff @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            ms_cnt <= 0;
            pulse_1ms <= 0;
        end else begin
            if (ms_cnt == 999) begin
                ms_cnt <= 0;
                pulse_1ms <= 1'b1;
            end else begin
                ms_cnt <= ms_cnt + 1;
                pulse_1ms <= 1'b0;
            end
        end
    end

    // --- TASK ---

    task task_glitch_reject(input int glitch_width_us);
        begin
            btn_in = 1;
            #(glitch_width_us * 1000); // Rộng từ 1us đến 19000us
            btn_in = 0;
            #5000000; // Đợi 5ms
        end
    endtask

    task task_debounce_press_20ms(input int press_width_ms);
        begin
            btn_in = 1;
            #(press_width_ms * 1000000); 
            btn_in = 0;
            #30000000; // Nghỉ 30ms sau khi nhả
        end
    endtask

    class BounceGenerator;
        rand int num_bounces;
        rand int bounce_width_us;
        rand int final_press_ms;

        constraint c_bounce {
            num_bounces inside {[3:10]}; // Nảy 3 đến 10 lần
            bounce_width_us inside {[10:5000]}; // Nhiễu hẹp 10us đến 5ms
            final_press_ms inside {[25:100]}; // Lần ấn thực sự cuối cùng
        }
    endclass

    task task_random_bounce_stress();
        BounceGenerator bgen = new();
        if (!bgen.randomize()) $fatal("Randomize failed!");
        
        $display("   [Khởi tạo kịch bản Bounce] Số lần nảy: %0d", bgen.num_bounces);
        
        // Mô phỏng Glitch liên tục
        for (int i=0; i<bgen.num_bounces; i++) begin
            btn_in = 1; #(bgen.bounce_width_us * 1000);
            btn_in = 0; #(bgen.bounce_width_us * 1000);
        end
        // ấn lâu 
        btn_in = 1; #(bgen.final_press_ms * 1000000);
        btn_in = 0; #30000000;
    endtask


    initial begin
        rstn_sync = 0; btn_in = 0;
        
        $display("---------------------------------------------------------");
        $display(" STARTING BLOCK-LEVEL VERIFICATION: tb_button            ");
        $display("---------------------------------------------------------");

        #1500 rstn_sync = 1; 
        #2000;

        $display(">> RUNNING: task_glitch_reject (Chèn nhiễu < 20ms)...");
        task_glitch_reject(500);  // Nhiễu 0.5ms
        task_glitch_reject(15000); // Nhiễu 15ms
        task_glitch_reject(19000); // Nhiễu 19ms sát ngưỡng

        $display(">> RUNNING: task_debounce_press_20ms (Bấm phím chuẩn)...");
        task_debounce_press_20ms(25); // Bấm 25ms
        task_debounce_press_20ms(50); // Bấm 50ms

        $display(">> RUNNING: task_random_bounce_stress (Kiểm thử stress 10 lần)...");
        for(int i=0; i<10; i++) begin
            task_random_bounce_stress();
        end

        $display("---------------------------------------------------------");
        $display(" FINISHED BLOCK-LEVEL VERIFICATION!                      ");
        $display(" Luu y: Kiem tra file SVA Checker de xem co loi logic khong. ");
        $display("---------------------------------------------------------");
        $stop;
    end

endmodule