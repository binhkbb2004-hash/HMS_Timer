# 1. Dọn dẹp thư viện cũ
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# 2. Compile
puts "---------------------------------------------------------"
puts " COMPILING..."
puts "---------------------------------------------------------"

# Biên dịch RTL 
vlog -work work +cover=sbce -sv ../rtl/reset_sync.v
vlog -work work +cover=sbce -sv ../rtl/clock_divider.v
vlog -work work +cover=sbce -sv ../rtl/button.v
vlog -work work +cover=sbce -sv ../rtl/button_processor.v
vlog -work work +cover=sbce -sv ../rtl/control_fsm.v
vlog -work work +cover=sbce -sv ../rtl/timer_counter.v
vlog -work work +cover=sbce -sv ../rtl/hms_timer.v

# Biên dịch SVA Checkers (Không bật code coverage ở đây)
vlog -work work -sv ../tb/checkers/chk_reset_sync.sv
vlog -work work -sv ../tb/checkers/chk_clock_divider.sv
vlog -work work -sv ../tb/checkers/chk_button.sv
vlog -work work -sv ../tb/checkers/chk_control_fsm.sv
vlog -work work -sv ../tb/checkers/chk_timer_counter.sv

# Functional Coverage
vlog -work work -sv ../tb/coverage/cov_hms_timer.sv

# Chạy Top-Level Random Test
vlog -work work -sv ../tb/tests/top_level/tb_hms_timer_rand.sv


# 3. Simulate
puts "---------------------------------------------------------"
puts " SIMULATING..."
puts "---------------------------------------------------------"

# Gọi trình mô phỏng
vsim -voptargs="+acc" -assertdebug -coverage work.tb_hms_timer_rand

transcript file ../logs/sim_transcript.log

add wave -position insertpoint sim:/tb_hms_timer_rand/dut/*
add wave -position insertpoint sim:/tb_hms_timer_rand/dut/u_control_fsm/*

# Chạy mô phỏng
run -all
