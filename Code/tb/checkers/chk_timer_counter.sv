// =========================================================================
// Checker timer_counter
// File: tb/checkers/chk_timer_counter.sv
// =========================================================================

module chk_timer_counter (
    input logic clk,
    input logic rstn_sync,
    input logic pulse_1s,
    input logic pause_cnt,
    input logic set_h,
    input logic set_m,
    input logic set_s,
    input logic up_tick,
    input logic down_tick,
    input logic [4:0] h_out,
    input logic [5:0] m_out,
    input logic [5:0] s_out
);

    initial $display("Binding SVA Checker: chk_timer_counter...");

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rstn_sync);

    // =================================================================
    // Logic Đếm Bình Thường (NORMAL MODE) - Chạy theo pulse_1s
    // =================================================================
    
    // Tăng giây: Khi không pause và có pulse_1s, nếu s_out < 59 thì s_out phải tăng 1
    property p_sec_inc_normal;
        (!pause_cnt && pulse_1s && s_out < 6'd59) |=> (s_out == $past(s_out) + 1'b1);
    endproperty
    ap_sec_inc_on_1s: assert property (p_sec_inc_normal) else $error("SVA FAIL: s_out khong tang khi co nhip 1s!");

    // Tràn Giây (Wrap): Khi s_out đang là 59 và có xung 1s, s_out phải về 0
    property p_sec_wrap_normal;
        (!pause_cnt && pulse_1s && s_out == 6'd59) |=> (s_out == 6'd0);
    endproperty
    ap_sec_wrap_on_1s: assert property (p_sec_wrap_normal) else $error("SVA FAIL: s_out khong vong ve 0 khi dat 59!");

    // Cờ nhớ Phút: Khi giây = 59 và có xung 1s -> m_out phải tăng (hoặc tràn)
    property p_sec_carry_to_min;
        (!pause_cnt && pulse_1s && s_out == 6'd59 && m_out < 6'd59) |=> (m_out == $past(m_out) + 1'b1);
    endproperty
    ap_sec_carry_to_min: assert property (p_sec_carry_to_min) else $error("SVA FAIL: s_out tran nhung khong cong vao m_out!");

    // Cờ nhớ Giờ: Khi cả giây và phút = 59 và có xung 1s -> h_out phải tăng
    property p_min_carry_to_hr;
        (!pause_cnt && pulse_1s && s_out == 6'd59 && m_out == 6'd59 && h_out < 5'd23) |=> (h_out == $past(h_out) + 1'b1);
    endproperty
    ap_min_carry_to_hr: assert property (p_min_carry_to_hr) else $error("SVA FAIL: m_out tran nhung khong cong vao h_out!");

    // =================================================================
    // Logic Chỉnh Tay (MANUAL SETTING) - Xử lý Wrap & No Carry
    // =================================================================
    
    // CHỈNH GIỜ (SET_H)

    property p_h_up_wrap;
        (pause_cnt && set_h && up_tick && h_out == 5'd23) |=> (h_out == 5'd0);
    endproperty
    ap_h_up_wrap: assert property (p_h_up_wrap) else $error("SVA FAIL: Chinh Gio UP khong vong ve 0!");

    property p_h_down_wrap;
        (pause_cnt && set_h && !up_tick && down_tick && h_out == 5'd0) |=> (h_out == 5'd23);
    endproperty
    ap_h_down_wrap: assert property (p_h_down_wrap) else $error("SVA FAIL: Chinh Gio DOWN khong vong ve 23!");

    // CHỈNH PHÚT (SET_M)
    property p_m_up_wrap_nocarry;
        (pause_cnt && set_m && up_tick && m_out == 6'd59) |=> (m_out == 6'd0 && $stable(h_out));
    endproperty
    ap_m_up_wrap_nocarry: assert property (p_m_up_wrap_nocarry) else $error("SVA FAIL: Chinh phut UP tran bi cong lan sang Gio!");

    property p_m_down_wrap;
        (pause_cnt && set_m && !up_tick && down_tick && m_out == 6'd0) |=> (m_out == 6'd59);
    endproperty
    ap_m_down_wrap: assert property (p_m_down_wrap) else $error("SVA FAIL: Chinh phut DOWN khong vong ve 59!");

    // CHỈNH GIÂY (SET_S)
    property p_s_up_wrap_nocarry;
        (pause_cnt && set_s && up_tick && s_out == 6'd59) |=> (s_out == 6'd0 && $stable(m_out));
    endproperty
    ap_s_up_wrap_nocarry: assert property (p_s_up_wrap_nocarry) else $error("SVA FAIL: Chinh giay UP tran bi cong lan sang Phut!");
    
    property p_s_down_wrap;
        (pause_cnt && set_s && !up_tick && down_tick && s_out == 6'd0) |=> (s_out == 6'd59);
    endproperty
    ap_s_down_wrap: assert property (p_s_down_wrap) else $error("SVA FAIL: Chinh giay DOWN khong vong ve 59!");

    // =================================================================
    // DỪNG ĐỒNG HỒ KHI CHỈNH
    // =================================================================
    
    // Khi đang chỉnh Giờ, Phút và Giây phải đứng im
    ap_ms_frozen_in_set_h: assert property (
        (pause_cnt && set_h) |=> $stable(m_out) && $stable(s_out)
    ) else $error("SVA FAIL: Phut/Giay tu dong bi lech khi dang chinh Gio!");

    // Khi đang chỉnh Phút, Giờ và Giây phải đứng im
    ap_hs_frozen_in_set_m: assert property (
        (pause_cnt && set_m) |=> $stable(h_out) && $stable(s_out)
    ) else $error("SVA FAIL: Gio/Giay tu dong bi lech khi dang chinh Phut!");
    
    // Khi đang chỉnh Giây, Giờ và Phút phải đứng im
    ap_hm_frozen_in_set_s: assert property (
        (pause_cnt && set_s) |=> $stable(h_out) && $stable(m_out)
    ) else $error("SVA FAIL: Gio/Phut tu dong bi lech khi dang chinh Giay!");

    // Khi đang chỉnh giờ thì người dùng không ấn up down, giờ phải giữ nguyên
    property p_pause_blocks_1s;
        (pause_cnt && !up_tick && !down_tick) |=> 
        $stable(h_out) && $stable(m_out) && $stable(s_out);
    endproperty
    ap_pause_blocks_1s: assert property (p_pause_blocks_1s) 
        else $error("SVA FAIL: Dong ho van chay ngam khi pause_cnt = 1!");

endmodule