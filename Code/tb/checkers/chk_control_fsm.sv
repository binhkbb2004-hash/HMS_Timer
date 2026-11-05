// =========================================================================
// Checker control_fsm
// File: tb/checkers/chk_control_fsm.sv
// =========================================================================

module chk_control_fsm (
    input logic clk,
    input logic rstn_sync,
    input logic sel_tick,
    input logic up_tick,
    input logic down_tick,
    input logic [1:0] current_state, // 0=NORMAL, 1=H, 2=M, 3=S
    input logic pause_cnt,
    input logic set_h,
    input logic set_m,
    input logic set_s,
    input logic [12:0] wdog_cnt
);

    initial $display("Binding SVA Checker: chk_control_fsm...");

    typedef enum logic [1:0] {
        NORMAL = 2'b00,
        SET_H  = 2'b01,
        SET_M  = 2'b10,
        SET_S  = 2'b11
    } state_e;

    default clocking cb @(posedge clk); endclocking

    // -----------------------------------------------------------------
    // Assertion 11: ap_reset_to_normal
    // Kéo reset là FSM phải về NORMAL ngay lập tức
    // -----------------------------------------------------------------
    property p_reset_fsm;
        (!rstn_sync) |-> (current_state == NORMAL);
    endproperty
    ap_reset_to_normal: assert property (p_reset_fsm)
        else $error("SVA FAIL: FSM khong ve NORMAL khi reset!");

    default disable iff (!rstn_sync); // Các SVA bên dưới chỉ check khi hết reset

    // -----------------------------------------------------------------
    // Assertion 12-15: Chuyển trạng thái (State Transition)
    // Kiểm tra chu trình NORMAL -> H -> M -> S -> NORMAL
    // -----------------------------------------------------------------
    ap_trans_n_to_h: assert property ( (current_state == NORMAL && sel_tick) |=> (current_state == SET_H) );
    ap_trans_h_to_m: assert property ( (current_state == SET_H  && sel_tick) |=> (current_state == SET_M) );
    ap_trans_m_to_s: assert property ( (current_state == SET_M  && sel_tick) |=> (current_state == SET_S) );
    ap_trans_s_to_n: assert property ( (current_state == SET_S  && sel_tick) |=> (current_state == NORMAL) );

    // -----------------------------------------------------------------
    // Assertion 16-19: Cờ ngõ ra (Output Logic)
    // -----------------------------------------------------------------
    ap_out_normal: assert property (
        (current_state == NORMAL) |-> ({pause_cnt, set_h, set_m, set_s} == 4'b0000)
    ) else $error("SVA FAIL: Sai co output o NORMAL");

    ap_out_set_h: assert property (
        (current_state == SET_H)  |-> ({pause_cnt, set_h, set_m, set_s} == 4'b1100)
    ) else $error("SVA FAIL: Sai co output o SET_H");

    ap_out_set_m: assert property (
        (current_state == SET_M)  |-> ({pause_cnt, set_h, set_m, set_s} == 4'b1010)
    ) else $error("SVA FAIL: Sai co output o SET_M");

    ap_out_set_s: assert property (
        (current_state == SET_S)  |-> ({pause_cnt, set_h, set_m, set_s} == 4'b1001)
    ) else $error("SVA FAIL: Sai co output o SET_S");

    // -----------------------------------------------------------------
    // Assertion 20: ap_set_onehot0
    // Đảm bảo không cài đặt (set_h, set_m, set_s) cùng một lúc
    // -----------------------------------------------------------------
    ap_set_onehot0: assert property (
        $onehot0({set_h, set_m, set_s})
    ) else $error("SVA FAIL: Loi nghiem trong! Phat hien 2 co SET bat cung luc!");

    // -----------------------------------------------------------------
    // Assertion 21-22: Watchdog
    // Đảm bảo reset wdog_cnt khi ve NORMAL
    // -----------------------------------------------------------------
    ap_wdog_zero_in_normal: assert property (
        (current_state == NORMAL) |=> (wdog_cnt == 0)
    ) else $error("SVA FAIL: wdog_cnt khong bi reset ve 0 khi FSM ve NORMAL!");

    ap_wdog_clear_on_activity: assert property (
        (sel_tick || up_tick || down_tick) |=> (wdog_cnt == 0)
    ) else $error("SVA FAIL: Watchdog khong bi xoa khi co thao thao nut bam!");

endmodule