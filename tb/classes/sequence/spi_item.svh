class spi_item extends uvm_sequence_item;
    typedef spi_item this_type_t;
    `uvm_object_utils(spi_item);

    bit [7:0] SPI_data;
    bit set_address;
    bit rw;
    bit command;
    
    function new(string name = "spi_item");
        super.new(name);
        SPI_data = 0;
        set_address = 0;
        rw = 0;
        command = 0;
    endfunction: new
endclass: spi_item