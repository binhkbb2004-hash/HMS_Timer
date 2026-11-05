// =========================================================================
// Checker reset_sync
// File: tb/checkers/chk_reset_sync.sv
// =========================================================================

module chk_reset_sync (
    input logic clk,
    input logic rstn,
    input logic rstn_sync
);

    // Bật log báo lỗi khi Assertion fail
    initial $display("Binding SVA Checker: chk_reset_sync...");

    // -----------------------------------------------------------------
    // Assertion: ap_release_aligned_posedge
    // Mô tả: Khi rstn được nhả (0 -> 1) bất đồng bộ, rstn_sync không được thay đổi mà phải đợi tới sườn dương
    // -----------------------------------------------------------------
    property p_release_aligned;
        @(posedge clk)
        $rose(rstn_sync) |-> (rstn == 1'b1);
    endproperty

    ap_release_aligned_posedge: assert property (p_release_aligned)
        else $error("SVA FAIL [ap_release_aligned_posedge]: rstn_sync duoc nha khong dong bo voi suon clk");

endmodule