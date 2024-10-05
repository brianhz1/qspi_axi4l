package tb_includes;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	`include "spi_item.svh"
	`include "axil_item.svh"
	`include "axil_addr_item.svh"
	`include "axil_m_item.svh"
	`include "axil_rd_item.svh"
	`include "axil_rdata_item.svh"
	`include "axil_wdata_item.svh"
	`include "axil_wr_item.svh"
	`include "axil_rstatus_item.svh"

	`include "axil_rd_sequence.svh"
	`include "axil_wr_sequence.svh"
	`include "axil_rw_sequence.svh"

	`include "axil_driver.svh"
	`include "axil_monitor.svh"
	`include "sequencer.svh"
	`include "axil_m_agent.svh"

	`include "spi_monitor.svh"
	`include "mem_sim.svh"
	`include "mem_agent.svh"

	`include "scoreboard.svh"
	`include "basic_env.svh"
	`include "rw_random_test.svh"
	`include "wr_bias_test.svh"
	`include "rd_bias_test.svh"
endpackage