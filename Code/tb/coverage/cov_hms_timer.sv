// =========================================================================
// Functional Coverage
// File: tb/coverage/cov_hms_timer.sv
// =========================================================================
`timescale 1ns / 1ps

module cov_hms_timer (
    input logic clk,
    input logic rstn_sync,
    input logic [1:0] current_state,
    input logic [4:0] h_out,
    input logic [5:0] m_out,
    input logic [5:0] s_out
);

    // COVERGROUP
    covergroup cg_hms_timer_main @(posedge clk iff rstn_sync);
        option.per_instance = 1;

        // 1. Phu cac trang thai FSM
        cp_state: coverpoint current_state {
            bins ST_NORMAL = {2'b00};
            bins ST_SET_H  = {2'b01};
            bins ST_SET_M  = {2'b10};
            bins ST_SET_S  = {2'b11};
        }

        // 2. Phu chuoi chuyen trang thai FSM
        cp_transitions: coverpoint current_state {
            bins normal_to_h    = (2'b00 => 2'b01);
            bins h_to_m         = (2'b01 => 2'b10);
            bins m_to_s         = (2'b10 => 2'b11);
            bins s_to_normal    = (2'b11 => 2'b00);
            bins timeout_h_to_n = (2'b01 => 2'b00);
            bins timeout_m_to_n = (2'b10 => 2'b00);
            bins timeout_s_to_n = (2'b11 => 2'b00);
        }

        // 3. Phu gia tri bien Gio - Phut - Giay
        cp_hours: coverpoint h_out {
            bins h_zero = {5'd0};
            bins h_mid  = {[5'd1:5'd22]};
            bins h_max  = {5'd23};
        }

        cp_mins: coverpoint m_out {
            bins m_zero = {6'd0};
            bins m_mid  = {[6'd1:6'd58]};
            bins m_max  = {6'd59};
        }

        cp_secs: coverpoint s_out {
            bins s_zero = {6'd0};
            bins s_mid  = {[6'd1:6'd58]};
            bins s_max  = {6'd59};
        }

        // 4. Cross Coverage
        cx_h_m: cross cp_hours, cp_mins;
        cx_m_s: cross cp_mins, cp_secs;

    endgroup

    // Khai bao va khoi tao instance
    cg_hms_timer_main cov_inst;

    initial begin
        cov_inst = new();
        $display("Khoi tao Coverage Model: cov_hms_timer_main THANH CONG!");
    end

endmodule