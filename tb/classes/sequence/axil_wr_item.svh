// starts write
class axil_wr_item extends axil_item;
    `uvm_object_utils(axil_wr_item)

    function new(string name = "axil_wr_item");
        super.new(name);
        addr.rand_mode(0);
        data.rand_mode(0);
        addr = 32'h00000001;
        data = 32'h00000002;
        rw = 0;
    endfunction: new
endclass: axil_wr_item