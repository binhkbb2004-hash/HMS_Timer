// =========================================================================
// Verison 31//10/26
// =========================================================================
 
module clock_divider #(
    parameter CLK_FREQ_HZ = 1_000_000
)(
    input wire clk,
    input wire rstn_sync, 
    output reg pulse_1ms, 
    output reg pulse_1s   
);

    localparam integer CLKS_PER_MS = CLK_FREQ_HZ / 1000;
    localparam integer CNT_1MS_W   = $clog2(CLKS_PER_MS);
    localparam [CNT_1MS_W-1:0] CNT_1MS_MAX = CLKS_PER_MS - 1;

    reg [CNT_1MS_W-1:0] cnt_1ms; 
    reg [9:0]           cnt_1s;  

    // --- Tạo xung pulse_1ms ---
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            cnt_1ms <= {CNT_1MS_W{1'b0}};
            pulse_1ms <= 1'b0;
        end else begin
            if (cnt_1ms == CNT_1MS_MAX) begin 
                cnt_1ms <= {CNT_1MS_W{1'b0}};
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