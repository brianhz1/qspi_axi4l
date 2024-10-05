// base item class
virtual class axil_item extends uvm_sequence_item;
    `uvm_object_utils(axil_item);

    bit rw; // 0: write, 1: read
    rand bit [31:0] addr;
    rand bit [31:0] data;

    //  Constructor: new
    function new(string name = "axil_item");
        super.new(name);
    endfunction: new
endclass: axil_item