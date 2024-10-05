// reads status register
class axil_rstatus_item extends axil_item;
`uvm_object_utils(axil_rstatus_item)

function new(string name = "axil_rstatus_item");
    super.new(name);
    addr.rand_mode(0);
    addr = 32'h00000000;
    rw = 1;
endfunction: new
endclass: axil_rstatus_item