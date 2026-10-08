// =========================================================================
// Verison 07//10/26
// =========================================================================
 
module clock_divider (
    input wire clk,
    input wire rstn_sync, 
    output reg pulse_1ms, 
    output reg pulse_1s   
);

    reg [9:0] cnt_1ms; 
    reg [9:0] cnt_1s;  

    // --- Tạo xung pulse_1ms (Đếm 1000 nhịp clk) ---
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            cnt_1ms <= 10'd0;
            pulse_1ms <= 1'b0;
        end else begin
            if (cnt_1ms == 10'd999) begin
                cnt_1ms <= 10'd0;
                pulse_1ms <= 1'b1;
            end else begin
                cnt_1ms <= cnt_1ms + 1'b1;
                pulse_1ms <= 1'b0;
            end
        end
    end

    // --- Tạo xung pulse_1s (Đếm 1000 nhịp pulse_1ms) ---
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            cnt_1s <= 10'd0;
            pulse_1s <= 1'b0;
        end else begin
            if (pulse_1ms) begin
                if (cnt_1s == 10'd999) begin
                    cnt_1s <= 10'd0;
                    pulse_1s <= 1'b1;
                end else begin
                    cnt_1s <= cnt_1s + 1'b1;
                    pulse_1s <= 1'b0;
                end
            end
            else begin
                pulse_1s <= 1'b0;
            end
        end
    end
endmodule