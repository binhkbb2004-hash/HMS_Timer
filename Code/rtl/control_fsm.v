// =========================================================================
// Verison 07//10/26
// =========================================================================
 
module control_fsm (
    input wire clk,
    input wire rstn_sync,
    input wire pulse_1ms,
    input wire sel_tick,
    input wire up_tick,
    input wire down_tick,
    output reg pause_cnt,
    output reg set_h,
    output reg set_m,
    output reg set_s
);

    localparam NORMAL = 2'b00;
    localparam SET_H  = 2'b01;
    localparam SET_M  = 2'b10;
    localparam SET_S  = 2'b11;

    reg [1:0] current_state, next_state;

    // --- Watchdog Timer 5 giây ---
    reg [12:0] wdog_cnt; 
    wire timeout;
    wire any_activity;
    assign any_activity = sel_tick | up_tick | down_tick;

    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            wdog_cnt <= 13'd0;
        end else begin
            // Trạng thái NORMAL luôn ép bộ đếm về 0
            if (current_state == NORMAL) begin
                wdog_cnt <= 13'd0;
            end 
            // Có nút bấm -> Xóa bộ đếm
            else if (any_activity) begin
                wdog_cnt <= 13'd0;
            end 
            // Nếu k có nút bấm, bộ đếm lên 1 khi có pulse_1ms
            else if (pulse_1ms) begin
                if (wdog_cnt == 13'd4999) begin
                    wdog_cnt <= 13'd0;
                end else begin
                    wdog_cnt <= wdog_cnt + 1'b1;
                end
            end
            else begin
                wdog_cnt <= wdog_cnt;
            end 
        end
    end

    assign timeout = (wdog_cnt == 13'd4999); // Cờ timeout bật khi đếm đủ 5 giây

    // --- FSM State Memory ---
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync) begin
            current_state <= NORMAL;
        end else begin
            current_state <= next_state;
        end
    end

    // --- FSM Next State Logic ---
    always @(*) begin
        case (current_state)
            NORMAL: begin
                if (sel_tick) begin
                    next_state = SET_H;
                end else begin
                    next_state = current_state;
                end
            end
            
            SET_H: begin
                if (timeout) begin      
                    next_state = NORMAL;
                end else if (sel_tick) begin
                    next_state = SET_M;
                end else begin
                    next_state = current_state;
                end
            end
            
            SET_M: begin
                if (timeout) begin
                    next_state = NORMAL;
                end else if (sel_tick) begin
                    next_state = SET_S;
                end else begin
                    next_state = current_state;
                end
            end
            
            SET_S: begin
                if (timeout) begin      
                    state_next = NORMAL;
                end else if (sel_tick) begin
                    next_state = NORMAL;
                end else begin
                    next_state = current_state;
                end
            end
            
            default: next_state = NORMAL;
        endcase
    end

    // --- FSM Output Logic ---
    always @(*) begin
        case (current_state)
            NORMAL: begin
                pause_cnt = 1'b0;
                set_h = 1'b0;
                set_m = 1'b0;
                set_s = 1'b0;
            end
            SET_H: begin
                pause_cnt = 1'b1;
                set_h = 1'b1;
                set_m = 1'b0;
                set_s = 1'b0;
            end
            SET_M: begin
                pause_cnt = 1'b1;
                set_h = 1'b0;
                set_m = 1'b1;
                set_s = 1'b0;
            end
            SET_S: begin
                pause_cnt = 1'b1;
                set_h = 1'b0;
                set_m = 1'b0;
                set_s = 1'b1;
            end
            default: begin
                pause_cnt = 1'b0;
                set_h = 1'b0;
                set_m = 1'b0;
                set_s = 1'b0;
            end
        endcase
    end
endmodule