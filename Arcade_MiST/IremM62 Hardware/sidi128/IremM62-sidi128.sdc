#set_output_delay -clock [get_clocks $vid_clk] -reference_pin [get_ports {HDMI_PCLK}] -max 5.0  [get_ports {HDMI_R[*] HDMI_G[*] HDMI_B[*] HDMI_HS HDMI_VS HDMI_DE}]
#set_output_delay -clock [get_clocks $vid_clk] -reference_pin [get_ports {HDMI_PCLK}] -min -1.0 [get_ports {HDMI_R[*] HDMI_G[*] HDMI_B[*] HDMI_HS HDMI_VS HDMI_DE}]

set_false_path -to [get_ports {HDMI_PCLK}]
set_false_path -to [get_ports {HDMI_*}]
