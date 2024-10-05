// completes memory read of byte_count bytes at address addr
class axil_rd_sequence extends uvm_sequence #(axil_item);
    `uvm_object_utils(axil_rd_sequence);

    rand bit [7:0] byte_count;
    rand bit [23:0] addr;

    constraint addr_lim {
        addr[23:22] == 2'b00;
        (addr+byte_count) <= 4194303;
    }

    function new(string name = "axil_rd_sequence");
        super.new(name);
    endfunction: new

    extern virtual task body();
endclass: axil_rd_sequence

task axil_rd_sequence::body();
    axil_addr_item addr_item;
    axil_wdata_item wdata_item;
    axil_rd_item rd_item;
    axil_rdata_item rdata_item;
    int word_count;

    word_count = byte_count/4;
    if (byte_count%4 != 0)
        word_count++;

    addr_item = axil_addr_item::type_id::create("addr_item");
    wdata_item = axil_wdata_item::type_id::create("wdata_item");
    rdata_item = axil_rdata_item::type_id::create("rdata_item");
    rd_item = axil_rd_item::type_id::create("rd_item");

    // set addr bit
    `uvm_info("rd_seqeunce", "setting addr bit", UVM_NONE)
    start_item(addr_item);
    finish_item(addr_item);
    `uvm_info("rd_seqeunce", "sending address", UVM_NONE)
    // set mem read address
    start_item(wdata_item);
    wdata_item.set_addr(addr);
    finish_item(wdata_item);

    // set read bit
    `uvm_info("rd_seqeunce", "starting read", UVM_NONE)
    start_item(rd_item);
    finish_item(rd_item);
    `uvm_info("axil_rd_sequence", $psprintf("starting %d byte read at addr=%h", byte_count, addr), UVM_NONE)
    
    // read all data words
    for (int i=0; i<word_count; i=i+1) begin
        start_item(rdata_item);
        finish_item(rdata_item);
    end
    `uvm_info("axil_rd_sequence", $psprintf("read %d data words at addr=%h", word_count, addr), UVM_NONE)

endtask