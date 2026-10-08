// =========================================================================
// Verison 07//10/26
// =========================================================================
 
module button_processor (
    input wire clk,
    input wire rstn_sync,
    input wire pulse_1ms,
    input wire sel_in,
    input wire up_in,
    input wire down_in,
    output wire sel_tick,
    output wire up_tick,
    output wire down_tick
);

    // 3 kênh xử lý cho sel_in, up_in, down_in
    
    button inst_sel (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .btn_in(sel_in),
        .btn_tick(sel_tick)
    );

    button inst_up (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .btn_in(up_in),
        .btn_tick(up_tick)
    );

    button inst_down (
        .clk(clk),
        .rstn_sync(rstn_sync),
        .pulse_1ms(pulse_1ms),
        .btn_in(down_in),
        .btn_tick(down_tick)
    );

endmodule