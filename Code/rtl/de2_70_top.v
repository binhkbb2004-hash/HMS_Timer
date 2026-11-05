// de2_70_top : top cua board DE2-70, bao ngoai hms_timer
//   CLOCK_50 -> clk (50 MHz)
//   KEY[0]   -> rstn  (nut nhan, bam = 0 = reset)
//   KEY[1]   -> sel_in 
//   KEY[2]   -> up_in
//   KEY[3]   -> down_in
//   HEX7..HEX6 = gio, HEX5..HEX4 = phut, HEX3..HEX2 = giay
//   HEX1, HEX0 khong dung (tat het cac doan)
// LED 7 thanh tich cuc thap, bit 0 = a ... bit 6 = g.
module de2_70_top (
  input  wire       CLOCK_50,
  input  wire [3:0] KEY,
  output wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);
  localparam [6:0] OFF = 7'b1111111;
  wire [4:0] h;
  wire [5:0] m, s;
  wire [1:0] fld;   // 00 = chay, 01 = chinh gio, 10 = chinh phut, 11 = chinh giay

  hms_timer #(.CLK_FREQ_HZ(50_000_000)) u_hms (
    .clk(CLOCK_50), 
    .rstn(KEY[0]),
    .sel_in(~KEY[1]), 
    .up_in(~KEY[2]), 
    .down_in(~KEY[3]),
    .h_out(h), 
    .m_out(m), 
    .s_out(s), 
    .adj_fld_o(fld));

  // xung nhap nhay: bit 24 cua bo dem 50 MHz doi trang thai 1,5 Hz
  reg [24:0] blink_cnt;
  always @(posedge CLOCK_50 or negedge KEY[0]) begin
    if (!KEY[0]) begin
      blink_cnt <= 25'd0;
    end else begin         
      blink_cnt <= blink_cnt + 1'b1;
    end
  end

  wire blink = blink_cnt[24] & KEY[2] & KEY[3];

  // tach hang chuc / hang don vi
  wire [3:0] h_t = h / 10, h_u = h % 10;
  wire [3:0] m_t = m / 10, m_u = m % 10;
  wire [3:0] s_t = s / 10, s_u = s % 10;

  wire [6:0] h1, h0, m1, m0, s1, s0;
  seg7 u_h1 (.d(h_t), .seg(h1));
  seg7 u_h0 (.d(h_u), .seg(h0));
  seg7 u_m1 (.d(m_t), .seg(m1));
  seg7 u_m0 (.d(m_u), .seg(m0));
  seg7 u_s1 (.d(s_t), .seg(s1));
  seg7 u_s0 (.d(s_u), .seg(s0));

  // truong dang chinh: tat het cac doan khi blink = 1
  wire blank_h = blink & (fld == 2'b11);
  wire blank_m = blink & (fld == 2'b10);
  wire blank_s = blink & (fld == 2'b01);

  assign HEX7 = blank_h ? OFF : h1;
  assign HEX6 = blank_h ? OFF : h0;
  assign HEX5 = blank_m ? OFF : m1;
  assign HEX4 = blank_m ? OFF : m0;
  assign HEX3 = blank_s ? OFF : s1;
  assign HEX2 = blank_s ? OFF : s0;

  // HEX1, HEX0 khong dung: tat het cac doan
  assign HEX1 = OFF;
  assign HEX0 = OFF;
endmodule

// seg7 : so 0-9 -> 7 thanh (tich cuc thap, {g,f,e,d,c,b,a})
module seg7 (
  input  wire [3:0] d,
  output reg  [6:0] seg
);
  always @* begin
    case (d)
      4'd0:    seg = 7'b1000000;
      4'd1:    seg = 7'b1111001;
      4'd2:    seg = 7'b0100100;
      4'd3:    seg = 7'b0110000;
      4'd4:    seg = 7'b0011001;
      4'd5:    seg = 7'b0010010;
      4'd6:    seg = 7'b0000010;
      4'd7:    seg = 7'b1111000;
      4'd8:    seg = 7'b0000000;
      4'd9:    seg = 7'b0010000;
      default: seg = 7'b1111111;
    endcase
  end
endmodule
