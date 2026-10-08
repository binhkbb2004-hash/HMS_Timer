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

    // 3. Tạo xung nhịp 1MHz (Chu kỳ = 1000ns -> Bật/tắt mỗi 500ns)
    initial begin
        clk = 0;
        forever begin
             #500 clk = ~clk;
        end
    end

    initial begin
        rstn_sync = 0;
        
        repeat (2) @(negedge clk);

        rstn_sync = 1;
        $display("[%0t ns] Nha rstn_sync = 1, bat dau dem...", $time);

        @(posedge pulse_1ms);
        $display("[%0t ns] xung pulse_1ms dau tien", $time);

        @(posedge pulse_1ms);
        $display("[%0t ns] xung pulse_1ms thu 2", $time);

        @(posedge pulse_1s);
        $display("[%0t ns] xung pulse_1s dau tien", $time);

        repeat(2000) @(posedge clk);
        
        $stop;
    end

endmodule