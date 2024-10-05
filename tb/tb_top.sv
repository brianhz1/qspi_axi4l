module tb_top ();
	import tb_includes::*;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

    logic clk;
    logic rst_n;

    axil_intf AXIL(.clk(clk), .rst_n(rst_n));
    spi_intf SPI();

    // instantiate DUT
    spi_top u_spi_top (
        .i_clk        (clk),
        .i_rst_n      (rst_n),
        // read addr
        .i_arvalid    (AXIL.arvalid),
        .o_arready    (AXIL.arready),
        .i_araddr     (AXIL.araddr),
        // read data
        .o_rvalid     (AXIL.rvalid),
        .i_rready     (AXIL.rready),
        .o_rdata      (AXIL.rdata),
        .o_rresp      (AXIL.rresp),
        // write addr
        .i_awvalid    (AXIL.awvalid),
        .o_awready    (AXIL.awready),
        .i_awaddr     (AXIL.awaddr),
        // write data
        .i_wvalid     (AXIL.wvalid),
        .i_wready     (AXIL.wready),
        .i_wdata      (AXIL.wdata),
        .i_wstrb      (AXIL.wstrb),
        // write response
        .o_bvalid     (AXIL.bvalid),
        .i_bready     (AXIL.bready),
        .o_bresp      (AXIL.bresp),
        // SPI
        .CS           (SPI.CS),
        .SCLK         (SPI.SCLK),
        .SIO          (SPI.SIO)
    );

    initial begin
        uvm_config_db #(virtual axil_intf)::set(null, "", "AXIL_VIF", AXIL);
        uvm_config_db #(virtual spi_intf)::set(null, "", "SPI_VIF", SPI);
        run_test("rw_random_test");
    end

    // clock and reset
    initial begin
        clk = 0;
        rst_n = 0;
        fork 
            forever begin
                #10;    // 100 MHz
                clk = ~clk; 
            end
            begin
                @(negedge clk);
                rst_n = 1;
            end
        join_none
    end
endmodule