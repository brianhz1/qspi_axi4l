// starts read of byte_count bytes
class axil_rd_item extends axil_item;
    `uvm_object_utils(axil_rd_item)

    function set_byte_count(bit [7:0] byte_count);
        this.data[9:2] = byte_count;
    endfunction: set_byte_count

    function new(string name = "axil_rd_item");
        super.new(name);
        addr.rand_mode(0);
        data.rand_mode(0);
        addr = 32'h00000001;
        data = 32'h00000001;
        rw = 0;
    endfunction: new
endclass: axil_rd_item