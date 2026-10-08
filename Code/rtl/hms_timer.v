// =========================================================================
// Verison 08//10/26
// =========================================================================

module hms_timer (
    input wire clk,        
    input wire rstn,       
    input wire sel_in,     
    input wire up_in,       
    input wire down_in,     
    output wire [4:0] h_out, 
    output wire [5:0] m_out, 
    output wire [5:0] s_out  
);

    // Wire từ khối reset_sync
    wire w_rstn_sync;

    // Wire từ khối clock_divider
    wire w_pulse_1ms;
    wire w_pulse_1s;

    // Wire từ khối button_processor
    wire w_sel_tick;
    wire w_up_tick;
    wire w_down_tick;

    // Wire từ khối control_fsm
    wire w_pause_cnt;
    wire w_set_h;
    wire w_set_m;
    wire w_set_s;

    reset_sync u_reset_sync (
        .clk (clk),
        .rstn (rstn),
        .rstn_sync (w_rstn_sync)
    );

    clock_divider u_clock_divider (
        .clk (clk),
        .rstn_sync (w_rstn_sync),
        .pulse_1ms (w_pulse_1ms),
        .pulse_1s (w_pulse_1s)
    );

    button_processor u_button_processor (
        .clk (clk),
        .rstn_sync (w_rstn_sync),
        .pulse_1ms (w_pulse_1ms),
        .sel_in (sel_in),
        .up_in (up_in),
        .down_in (down_in),
        .sel_tick (w_sel_tick),
        .up_tick (w_up_tick),
        .down_tick (w_down_tick)
    );

    control_fsm u_control_fsm (
        .clk (clk),
        .rstn_sync (w_rstn_sync),
        .pulse_1ms (w_pulse_1ms),
        .sel_tick (w_sel_tick),
        .up_tick (w_up_tick),
        .down_tick (w_down_tick),
        .pause_cnt (w_pause_cnt),
        .set_h (w_set_h),
        .set_m (w_set_m),
        .set_s (w_set_s)
    );

    timer_counter u_timer_counter (
        .clk (clk),
        .rstn_sync (w_rstn_sync),
        .pulse_1s (w_pulse_1s),
        .pause_cnt (w_pause_cnt),
        .set_h (w_set_h),
        .set_m (w_set_m),
        .set_s (w_set_s),
        .up_tick (w_up_tick),
        .down_tick (w_down_tick),
        .h_out (h_out), 
        .m_out (m_out),
        .s_out (s_out)
    );

endmodule