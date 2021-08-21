# Ethernet constraints

# IDELAY on RGMII from PHY chip
set_property IDELAY_VALUE 0 [get_cells {phy_rx_ctl_idelay phy_rxd_idelay_*}]




create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 32768 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_int]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[0]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[1]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[2]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[3]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[4]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[5]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[6]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[7]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[8]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[9]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[10]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[11]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[12]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[13]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[14]} {core_inst/i2c_axi_inst/string_generator/hdr_dest_port[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 7 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {core_inst/i2c_axi_inst/string_generator/byte_select[0]} {core_inst/i2c_axi_inst/string_generator/byte_select[1]} {core_inst/i2c_axi_inst/string_generator/byte_select[2]} {core_inst/i2c_axi_inst/string_generator/byte_select[3]} {core_inst/i2c_axi_inst/string_generator/byte_select[4]} {core_inst/i2c_axi_inst/string_generator/byte_select[5]} {core_inst/i2c_axi_inst/string_generator/byte_select[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {core_inst/i2c_axi_inst/string_generator/next_string_control_state[0]} {core_inst/i2c_axi_inst/string_generator/next_string_control_state[1]} {core_inst/i2c_axi_inst/string_generator/next_string_control_state[2]} {core_inst/i2c_axi_inst/string_generator/next_string_control_state[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[0]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[1]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[2]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[3]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[4]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[5]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[6]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[7]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[8]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[9]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[10]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[11]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[12]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[13]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[14]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[15]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[16]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[17]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[18]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[19]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[20]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[21]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[22]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[23]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[24]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[25]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[26]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[27]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[28]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[29]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[30]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_source_ip[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 32 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[0]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[1]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[2]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[3]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[4]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[5]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[6]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[7]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[8]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[9]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[10]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[11]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[12]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[13]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[14]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[15]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[16]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[17]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[18]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[19]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[20]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[21]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[22]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[23]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[24]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[25]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[26]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[27]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[28]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[29]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[30]} {core_inst/i2c_axi_inst/string_generator/hdr_ip_dest_ip[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 4 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {core_inst/i2c_axi_inst/string_generator/string_control_state[0]} {core_inst/i2c_axi_inst/string_generator/string_control_state[1]} {core_inst/i2c_axi_inst/string_generator/string_control_state[2]} {core_inst/i2c_axi_inst/string_generator/string_control_state[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {core_inst/i2c_axi_inst/string_generator/hdr_source_port[0]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[1]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[2]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[3]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[4]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[5]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[6]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[7]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[8]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[9]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[10]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[11]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[12]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[13]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[14]} {core_inst/i2c_axi_inst/string_generator/hdr_source_port[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 8 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {core_inst/tx_udp_payload_axis_tdata[0]} {core_inst/tx_udp_payload_axis_tdata[1]} {core_inst/tx_udp_payload_axis_tdata[2]} {core_inst/tx_udp_payload_axis_tdata[3]} {core_inst/tx_udp_payload_axis_tdata[4]} {core_inst/tx_udp_payload_axis_tdata[5]} {core_inst/tx_udp_payload_axis_tdata[6]} {core_inst/tx_udp_payload_axis_tdata[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list core_inst/i2c_axi_inst/string_generator/in_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list core_inst/i2c_axi_inst/string_generator/in_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list core_inst/i2c_axi_inst/string_generator/tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list core_inst/tx_udp_hdr_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list core_inst/tx_udp_hdr_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list core_inst/tx_udp_payload_axis_tlast]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list core_inst/tx_udp_payload_axis_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list core_inst/tx_udp_payload_axis_tuser]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list core_inst/tx_udp_payload_axis_tvalid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_int]
