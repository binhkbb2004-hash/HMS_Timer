// =========================================================================
// Checker button
// File: tb/checkers/chk_button.sv
// =========================================================================

module chk_button (
    input logic clk,
    input logic rstn_sync,
    input logic pulse_1ms,
    input logic btn_sync,
    input logic btn_clean,
    input logic [4:0] debounce_cnt,
    input logic btn_tick
);

    initial $display("Binding SVA Checker: chk_button...");

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rstn_sync);

    // -----------------------------------------------------------------
    // Assertion 7: ap_cnt_reset_on_match
    // Nếu btn_sync == btn_clean, bộ đếm debounce_cnt phải lập tức bị xóa về 0 ở chu kỳ tiếp theo.
    // -----------------------------------------------------------------
    property p_cnt_reset;
        (btn_sync == btn_clean) |=> (debounce_cnt == 5'd0);
    endproperty
    ap_cnt_reset_on_match: assert property (p_cnt_reset)
        else $error("SVA FAIL: debounce_cnt khong bi xoa khi btn_sync giong btn_clean!");

    // -----------------------------------------------------------------
    // Assertion 8: ap_cnt_gated_by_1ms
    // debounce_cnt chỉ được thay đổi khi có pulse_1ms.
    // -----------------------------------------------------------------
    property p_cnt_gated;
        (!pulse_1ms && (btn_sync != btn_clean)) |=> $stable(debounce_cnt);
    endproperty
    ap_cnt_gated_by_1ms: assert property (p_cnt_gated)
        else $error("SVA FAIL: debounce_cnt dem sai nhip khi khong co pulse_1ms!");

    // -----------------------------------------------------------------
    // Assertion 9: ap_rising_edge_tick
    // Bất cứ khi nào sinh ra btn_tick, thì edge detector vừa ghi nhận sườn dương (chuyển từ 0 lên 1)
    // -----------------------------------------------------------------
    property p_btn_tick_valid;
        btn_tick |-> (btn_clean == 1'b1 && $past(btn_clean) == 1'b0);
    endproperty
    ap_rising_edge_tick: assert property (p_btn_tick_valid)
        else $error("SVA FAIL: Sinh ra tick ao khi khong he co phim bam!");

    // -----------------------------------------------------------------
    // Assertion 10: ap_no_tick_on_falling
    // Khi nhả phím (btn_clean từ 1 xuống 0 -> $fell), tuyệt đối KHÔNG được sinh ra btn_tick.
    // -----------------------------------------------------------------
    property p_no_tick_falling;
        $fell(btn_clean) |=> (btn_tick == 1'b0);
    endproperty
    ap_no_tick_on_falling: assert property (p_no_tick_falling)
        else $error("SVA FAIL: Sinh ra btn_tick sai luat khi nha phim!");

endmodule