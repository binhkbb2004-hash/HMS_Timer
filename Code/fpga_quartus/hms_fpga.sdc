# hms_fpga.sdc : rang buoc timing cho de2_70_top tren DE2-70

# clock 50 MHz (chu ky 20 ns)
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]

derive_clock_uncertainty

# nut bam vao: da qua sync_2ff / bo dong bo reset trong hms_timer, khong rang buoc timing
set_false_path -from [get_ports {KEY[*]}]

# LED 7 thanh ra: mach hien thi cham, khong rang buoc timing
set_false_path -to [get_ports {HEX*}]
