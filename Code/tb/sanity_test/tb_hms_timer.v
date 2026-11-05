`timescale 1ns / 1ps
module tb_hms_timer();
    reg  clk;
    reg  rstn;
    reg  sel_in;
    reg  up_in;
    reg  down_in;
    
    wire [4:0] h_out;
    wire [5:0] m_out;
    wire [5:0] s_out;

    // DUT 
    hms_timer dut (
        .clk(clk),
        .rstn(rstn),
        .sel_in(sel_in),
        .up_in(up_in),
        .down_in(down_in),
        .h_out(h_out),
        .m_out(m_out),
        .s_out(s_out)
    );

    // Clock 1MHz
    initial begin
        clk = 0;
        forever #500 clk = ~clk; 
    end

    
    // --- Task mô phỏng ấn nút ---
    task press_sel();
        begin
            sel_in = 1; #25000000; 
            sel_in = 0; #25000000; 
        end
    endtask

    task press_up();
        begin
            up_in = 1; #25000000; 
            up_in = 0; #25000000; 
        end
    endtask

    task press_down();
        begin
            down_in = 1; #25000000; 
            down_in = 0; #25000000; 
        end
    endtask

    // --- Task tua thời gian --- 
    task wait_seconds(input integer s);
        integer i;
        begin
            for (i = 0; i < s; i = i + 1) begin
                // mỗi lần lặp đếm 1s 
                repeat(1000) #1000000; 
            end
            #5000;
        end
    endtask


    initial begin
        rstn = 0;
        sel_in = 0; 
        up_in = 0; 
        down_in = 0;

        $display(" --- START --- ");

        #1500 rstn = 1;
        repeat (2) @(posedge clk); // Đợi 2 chu kỳ để rst_sync lên 1
        #500;

        // --- TESTCASE 1: NORMAL MODE --- 

        $display("TESTCASE 1: NORMAL MODE");
        
        // Đợi 10 giây
        wait_seconds(10); 
        
        if (h_out == 0 && m_out == 0 && s_out == 10) begin
            $display("  -> [PASS] Dong ho dem chuan xac (Hien tai: %0d:%0d:%0d).", h_out, m_out, s_out);
        end else begin 
            $display("  -> [FAIL] Dong ho sai! (Hien tai: %0d:%0d:%0d).", h_out, m_out, s_out);  
        end

        // --- TESTCASE 2: SET MODE ---

        $display("TESTCASE 2: SET MODE");
        
        // Vào SET_H
        press_sel();
        $display("  -> Da an SEL. Dang o che do SET_H.");
        
        press_down(); // Giờ lùi từ 0 -> 23
        if (h_out == 23 && m_out == 0 && s_out == 10) begin
            $display("  -> [PASS] Chinh GIO lui qua 0 vong len 23 chuan xac");
        end else begin 
            $display("  -> [FAIL] Chinh GIO sai"); 
        end

        // Vào SET_M
        press_sel();
        $display("  -> Da an SEL. Dang o che do SET_M");
        
        // Phút tăng từ 0 -> 2
        press_up();
        press_up();
        if (h_out == 23 && m_out == 2 && s_out == 10) begin
            $display("  -> [PASS] Chinh PHUT tien tu 0 len 2 chuan xac");
        end else begin 
            $display("  -> [FAIL] Chinh PHUT sai");
        end
        
        // Đợi 3s không thao tác
        wait_seconds(3);
        if (h_out == 23 && m_out == 2 && s_out == 10) begin
            $display("  -> [PASS] Che do SET Thoi gian bi Pause");
        end else begin 
            $display("  -> [FAIL] Thoi gian bi lech o SET MODE");
        end


        // --- TESTCASE 3: Thoát về NORMAL và đếm tiếp ---

        $display("TESTCASE 3: Ve NORMAL va dem tiep");
        
        press_sel(); // Vào SET_S
        press_up(); // Giây từ 10 -> 11
        press_sel(); // Về NORMAL MODE
        
        $display("  -> Da an SEL thoat ve NORMAL. Thoi gian dang la: %0d:%0d:%0d.", h_out, m_out, s_out);
        
        // Chờ 10 giây
        wait_seconds(10); 

        if (h_out == 23 && m_out == 2 && s_out == 21) begin
            $display("  -> [PASS] Dong ho da dem tiep tuc (Hien tai: %0d:%0d:%0d)", h_out, m_out, s_out);
        end else begin 
            $display("  -> [FAIL] Dong ho khong dem tiep sau khi thoat NORMAL"); 
        end

        $display(" --- END --- ");

        #100000;
        $stop;
    end
endmodule