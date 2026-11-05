// =========================================================================
// Checker clock_divider
// File: tb/checkers/chk_clock_divider.sv
// =========================================================================

module chk_clock_divider (
    input logic clk,
    input logic rstn_sync,
    input logic [9:0] cnt_1ms,
    input logic [9:0] cnt_1s,
    input logic pulse_1ms,
    input logic pulse_1s
);

    initial $display("Binding SVA Checker: chk_clock_divider...");

    // Thiết lập xung nhịp chung cho tất cả các assertion
    default clocking cb @(posedge clk); endclocking
    default disable iff (!rstn_sync); // Tự động bỏ qua check khi đang reset

    // -----------------------------------------------------------------
    // Assertion 1: ap_pulse_1ms_width_1
    // Mô tả: pulse_1ms chỉ ở mức 1 trong đúng 1 chu kỳ clk mỗi lần kích hoạt
    // -----------------------------------------------------------------
    property p_pulse_1ms_width;
        $rose(pulse_1ms) |=> $fell(pulse_1ms);
    endproperty
    ap_pulse_1ms_width_1: assert property (p_pulse_1ms_width)
        else $error("SVA FAIL: pulse_1ms keo dai hon 1 chu ky clk!");

    // -----------------------------------------------------------------
    // Assertion 2: ap_cnt_1ms_wrap_999
    // Mô tả: Kiểm tra chuỗi cnt_1ms chạy đến 999 rồi vòng về 0 đồng thời pulse_1ms=1
    // -----------------------------------------------------------------
    property p_cnt_1ms_wrap;
        (cnt_1ms == 10'd999) |=> (cnt_1ms == 10'd0) && pulse_1ms;
    endproperty
    ap_cnt_1ms_wrap_999: assert property (p_cnt_1ms_wrap)
        else $error("SVA FAIL: cnt_1ms khong vong ve 0 hoac thieu pulse_1ms tai moc 999!");

    // -----------------------------------------------------------------
    // Assertion 3: ap_pulse_1s_width_1
    // Mô tả: pulse_1s chỉ ở mức 1 trong đúng 1 chu kỳ clk
    // -----------------------------------------------------------------
    property p_pulse_1s_width;
        $rose(pulse_1s) |=> $fell(pulse_1s);
    endproperty
    ap_pulse_1s_width_1: assert property (p_pulse_1s_width)
        else $error("SVA FAIL: pulse_1s keo dai hon 1 chu ky clk!");

// -----------------------------------------------------------------
    // Assertion 4: ap_cnt_1s_gated_by_1ms
    // Mô tả: cnt_1s chỉ được phép thay đổi ở chu kỳ SAU KHI có xung pulse_1ms
    // -----------------------------------------------------------------
    property p_cnt_1s_gated;
        @(posedge clk) disable iff (!rstn_sync)
        (!pulse_1ms) |=> $stable(cnt_1s);
    endproperty

    ap_cnt_1s_gated_by_1ms: assert property(p_cnt_1s_gated) 
        else $error("SVA FAIL: cnt_1s bi thay doi khi KHONG CO pulse_1ms!");

    // -----------------------------------------------------------------
    // Assertion 5: ap_cnt_1s_wrap_999
    // Mô tả: Khi cnt_1s == 999 VÀ pulse_1ms == 1 (chu kỳ cuối của 1s), chu kỳ tiếp theo cnt_1s về 0 VÀ pulse_1s bật lên 1
    // -----------------------------------------------------------------
    property p_cnt_1s_wrap;
        @(posedge clk) disable iff (!rstn_sync)
        (cnt_1s == 10'd999 && pulse_1ms) |=> (cnt_1s == 10'd0 && pulse_1s);
    endproperty

    ap_cnt_1s_wrap_999: assert property(p_cnt_1s_wrap)
        else $error("SVA FAIL: cnt_1s khong vong ve 0 hoac thieu pulse_1s tai moc 1 giay!");

    // -----------------------------------------------------------------
    // Assertion 6: ap_1s_implies_1ms
    // Mô tả: Nếu pulse_1s bật mức 1 ở chu kỳ này, thì chu kỳ trước đó phải có xung pulse_1ms
    // -----------------------------------------------------------------
    property p_1s_implies_1ms;
        @(posedge clk) disable iff (!rstn_sync)
        pulse_1s |-> $past(pulse_1ms);
    endproperty

    ap_1s_implies_1ms: assert property(p_1s_implies_1ms)
        else $error("SVA FAIL: Xung pulse_1s xuat hien lech pha");

endmodule