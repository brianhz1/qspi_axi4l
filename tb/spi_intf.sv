interface spi_intf ();
    bit CS;
    bit SCLK;
    wire [3:0] SIO;

    bit mem_w;
    bit [3:0] mem_sio;

    assign SIO = mem_w ? mem_sio : 4'hz;
endinterface