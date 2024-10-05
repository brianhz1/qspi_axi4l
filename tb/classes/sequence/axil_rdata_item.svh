// reads data from rx
class axil_rdata_item extends axil_item;
    `uvm_object_utils(axil_rdata_item)

    function new(string name = "axil_rdata_item");
        super.new(name);
        addr.rand_mode(0);
        addr = 32'h00000003;
        rw = 1;
    endfunction: new
endclass: axil_rdata_item