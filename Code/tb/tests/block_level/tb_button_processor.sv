`timescale 1ns / 1ps
module tb_button_processor();
    logic clk, rstn_sync, pulse_1ms;
    logic sel_in, up_in, down_in;
    logic sel_tick, up_tick, down_tick;

    button_processor dut (.*);

    initial begin clk = 0; forever #500 clk = ~clk; end
    
    // Giả lập pulse_1ms
    logic [9:0] ms_cnt;
    always_ff @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin ms_cnt <= 0; pulse_1ms <= 0; end
        else if (ms_cnt == 999) begin ms_cnt <= 0; pulse_1ms <= 1; end
        else begin ms_cnt <= ms_cnt + 1; pulse_1ms <= 0; end
    end

    // --- TASK ---
    task task_channel_indep_sel();
        sel_in = 1; #25000000; sel_in = 0; #10000000;
    endtask

    task task_channel_indep_up();
        up_in = 1; #25000000; up_in = 0; #10000000;
    endtask

    task task_simultaneous_press();
        // Nhấn cả 3 nút cùng lúc
        sel_in = 1; up_in = 1; down_in = 1; 
        #25000000; 
        sel_in = 0; up_in = 0; down_in = 0; 
        #10000000;
    endtask

    initial begin
        rstn_sync = 0; sel_in = 0; up_in = 0; down_in = 0;
        #1500; rstn_sync = 1; #2000;

        $display("[TB] Test kenh SEL doc lap..."); task_channel_indep_sel();
        $display("[TB] Test kenh UP doc lap...");  task_channel_indep_up();
        $display("[TB] Test an 3 nut cung luc..."); task_simultaneous_press();
        $stop;
    end
endmodule