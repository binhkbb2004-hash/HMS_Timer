// =========================================================================
// Verison 08//10/26
// =========================================================================
 
module timer_counter (
    input wire clk,
    input wire rstn_sync,
    input wire pulse_1s,
    input wire pause_cnt,
    input wire set_h,
    input wire set_m,
    input wire set_s,
    input wire up_tick,
    input wire down_tick,
    output reg [4:0] h_out,
    output reg [5:0] m_out,
    output reg [5:0] s_out
);

    // --- Logic xử lý Giây ---

    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            s_out <= 6'd0;
        end else begin
            if (pause_cnt == 1'b0) begin
                // CHẾ ĐỘ NORMAL: Chạy theo pulse_1s
                if (pulse_1s) begin
                    if (s_out == 6'd59) begin
                        s_out <= 6'd0;
                    end else begin               
                        s_out <= s_out + 1'b1;
                    end
                end
            end else if (set_s && pause_cnt) begin
                // CHẾ ĐỘ CÀI ĐẶT: Chạy theo thao tác nút nhấn
                if (up_tick) begin
                    if (s_out == 6'd59) begin 
                        s_out <= 6'd0;
                    end else begin               
                        s_out <= s_out + 1'b1;
                    end
                end else if (down_tick) begin
                    if (s_out == 6'd0) begin 
                        s_out <= 6'd59;
                    end else begin               
                        s_out <= s_out - 1'b1;
                    end
                end else begin
                    s_out <= s_out;
                end
            end
        end
    end

    // --- Logic xử lý Phút ---

    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            m_out <= 6'd0;
        end else begin
            if (pause_cnt == 1'b0) begin
                // CHẾ ĐỘ NORMAL: Tăng 1 khi pulse_1s = 1 VÀ s_out đang là 59
                if (pulse_1s && (s_out == 6'd59)) begin
                    if (m_out == 6'd59) begin 
                        m_out <= 6'd0;
                    end else begin                
                        m_out <= m_out + 1'b1;
                    end
                end
            end else if (set_m && pause_cnt) begin
                // CHẾ ĐỘ CÀI ĐẶT: Ngắt liên kết với s_out
                if (up_tick) begin
                    if (m_out == 6'd59) begin 
                        m_out <= 6'd0;
                    end else begin                
                        m_out <= m_out + 1'b1;
                    end
                end else if (down_tick) begin
                    if (m_out == 6'd0) begin 
                        m_out <= 6'd59;
                    end else begin                
                        m_out <= m_out - 1'b1;
                    end
                end else begin
                    m_out <= m_out;
                end
            end
        end
    end

    // --- Logic xử lý Giờ ---
  
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            h_out <= 5'd0;
        end else begin
            if (pause_cnt == 1'b0) begin
                // CHẾ ĐỘ NORMAL: Tăng 1 khi Giây = 59 VÀ Phút = 59 và có pulse_1s
                if (pulse_1s && (s_out == 6'd59) && (m_out == 6'd59)) begin
                    if (h_out == 5'd23) begin
                        h_out <= 5'd0;
                    end else begin               
                        h_out <= h_out + 1'b1;
                    end
                end
            end else if (set_h && pause_cnt) begin
                // CHẾ ĐỘ CÀI ĐẶT: Ngắt liên kết với phút và giây
                if (up_tick) begin
                    if (h_out == 5'd23) begin
                        h_out <= 5'd0;
                    end else begin                
                        h_out <= h_out + 1'b1;
                    end
                end else if (down_tick) begin
                    if (h_out == 5'd0) begin 
                        h_out <= 5'd23;
                    end else begin               
                        h_out <= h_out - 1'b1;
                    end
                end else begin
                    h_out <= h_out;
                end
            end
        end
    end

endmodule