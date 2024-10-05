module spi_top
(
    input i_clk,
    input i_rst_n,

    // read addr
    input i_arvalid,
    output o_arready,
    input [31:0] i_araddr,

    // read data
    output o_rvalid,
    input i_rready,
    output [31:0] o_rdata,
    output o_rresp,

    // write addr
    input i_awvalid,
    output o_awready,
    input [31:0] i_awaddr,

    // write data
    input i_wvalid,
    output i_wready,
    input [31:0] i_wdata,
    input [3:0] i_wstrb,

    // write response
    output o_bvalid,
    input i_bready,
    output [1:0] o_bresp,

    // SPI
    output CS,
    output SCLK,
    inout [3:0] SIO
);

    wire [7:0] tx_out, rx_out;
    wire [7:0] ctrl_data_o, i_data, tx_din, rx_din;
    wire [7:0] byte_count;
    wire [31:0] status;

    axil_s u_axil_s 
    (
        .clk             (clk),
        .rst_n           (rst_n),
        // spi control signals
        .i_rx_empty      (rx_empty),
        .i_rx_byte       (rx_out),
        .i_complete      (spi_ctrl_complete),
        .i_wip           (wip),
        .o_rx_rd         (rx_rd),
        .o_tx_wr         (tx_wr),
        .o_tx_byte       (tx_din),
        .o_write         (write),
        .o_read          (read),
        .o_byte_count    (byte_count),
        // read addr
        .i_arvalid       (i_arvalid),
        .o_arready       (o_arready),
        .i_araddr        (i_araddr),
        // read data
        .o_rvalid        (o_rvalid),
        .i_rready        (i_rready),
        .o_rdata         (o_rdata),
        .o_rresp         (o_rresp),
        // write addr
        .i_awvalid       (i_awvalid),
        .o_awready       (o_awready),
        .i_awaddr        (i_awaddr),
        // write data
        .i_wvalid        (i_wvalid),
        .o_wready        (o_wready),
        .i_wdata         (i_wdata),
        .i_wstrb         (i_wstrb),
        // write response
        .o_bvalid        (o_bvalid),
        .i_bready        (i_bready),
        .o_bresp         (o_bresp)
    );

    fifo #(.depth(259)) tx_fifo
    (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_wdata    (tx_din),
        .i_wr       (tx_wr),
        .i_rd       (tx_rd),
        .o_full     (tx_full),
        .o_empty    (tx_empty),
        .o_rdata    (tx_out)
    );

    fifo rx_fifo (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_wdata    (rx_din),
        .i_wr       (rx_wr),
        .i_rd       (rx_rd),
        .o_full     (rx_full),
        .o_empty    (rx_empty),
        .o_rdata    (rx_out)
    );

    spi_ctrl u_spi_ctrl (
        .clk             (i_clk),
        .rst_n           (i_rst_n),
        .i_read          (read), 
        .i_write         (write),
        .i_byte_count    (byte_count),
        .o_wip           (wip),

        // spi_module control
        .i_ready         (ready),
        .i_dload         (dload),
        .i_dval          (dval),
        .o_d_source      (d_source),
        .o_data          (ctrl_data_o),
        .o_start         (start),
        .o_rw            (rw),
        .o_q_mode        (q_mode),
        .o_dummy         (dummy),
        .o_complete      (spi_ctrl_complete),

        // fifo control
        .o_tx_rd         (tx_rd),
        .o_rx_wr         (rx_wr),
        .i_tx_empty      (tx_empty)
    );

    spi_module u_spi_module (
        .clk            (i_clk),
        .rst_n          (i_rst_n),
        .i_start        (start),
        .i_rw           (rw),
        .i_q_mode       (q_mode),
        .i_dummy        (dummy),
        .i_data_read    (rx_rd),
        .i_data         (i_data),
        .o_data         (rx_din),
        .o_dval         (dval),
        .o_dload        (dload),
        .o_ready        (ready),
        .o_sclk         (SCLK),
        .o_cs           (CS),
        .SIO            (SIO)
    );

    assign i_data = d_source ? ctrl_data_o : tx_out;

endmodule