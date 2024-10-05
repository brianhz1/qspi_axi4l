// writes data to tx
class axil_wdata_item extends axil_item;
    `uvm_object_utils(axil_wdata_item)

    function set_data(bit [31:0] data);
        this.data = data;
    endfunction: set_data

    function set_addr(bit [23:0] addr);
        this.data[23:0] = addr;
    endfunction: set_addr

    function new(string name = "axil_wdata_item");
        super.new(name);
        addr.rand_mode(0);
        addr = 32'h00000002;
        rw = 0;
    endfunction: new
endclass: axil_wdata_item