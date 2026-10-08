// =========================================================================
// Verison 07//10/26
// =========================================================================
 
module button (
    input wire clk,
    input wire rstn_sync,
    input wire pulse_1ms,
    input wire btn_in,
    output wire btn_tick
);

    // --- Tầng 1: Khử Metastability ---
    reg ff1, btn_sync;
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            ff1 <= 1'b0;
            btn_sync <= 1'b0;
        end else begin
            ff1 <= btn_in;
            btn_sync <= ff1;
        end
    end

    // --- Tầng 2: Debounce 20ms ---
    reg [4:0] debounce_cnt;
    reg btn_clean;
    
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            debounce_cnt <= 5'd0;
            btn_clean <= 1'b0;
        end else begin
            if (pulse_1ms) begin
                if (btn_sync == btn_clean) begin
                    // Nếu giống trạng thái cũ -> Xóa bộ đếm
                    debounce_cnt <= 5'd0;
                end else begin
                    // Nếu phát hiện trạng thái khác -> Bắt đầu đếm
                    if (debounce_cnt == 5'd19) begin
                        btn_clean <= btn_sync;  // Cập nhật trạng thái khi đủ 20ms
                        debounce_cnt <= 5'd0;
                    end else begin
                        debounce_cnt <= debounce_cnt + 1'b1;
                    end
                end
            end else begin
                debounce_cnt <= debounce_cnt;
            end
        end
    end

    // --- Tầng 3: Edge Detector ---
    reg clean_delay; 
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            clean_delay <= 1'b0;
        end else begin
            clean_delay <= btn_clean;
        end
    end

    assign btn_tick = btn_clean & (~clean_delay);

endmodule