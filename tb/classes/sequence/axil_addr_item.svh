// sets addr bit
class axil_addr_item extends axil_item;
    `uvm_object_utils(axil_addr_item)

    function new(string name = "axil_addr_item");
        super.new(name);
        addr.rand_mode(0);
        data.rand_mode(0);
        addr = 32'h00000001;
        data = 32'h00000400;
        rw = 0;
    endfunction: new
endclass: axil_addr_item