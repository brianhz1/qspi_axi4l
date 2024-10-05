interface axil_intf (input bit clk, rst_n);
    // read addr
    bit arvalid;
    bit arready;
    bit [31:0] araddr;

    // read data
    bit rvalid;
    bit rready;
    bit [31:0] rdata;
    bit rresp;

    // write addr
    bit awvalid;
    bit awready;
    bit [31:0] awaddr;

    // write data
    bit wvalid;
    bit wready;
    bit [31:0] wdata;
    bit [3:0] wstrb;

    // write response
    bit bvalid;
    bit bready;
    bit [1:0] bresp;

endinterface