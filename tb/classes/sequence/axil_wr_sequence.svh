// starts memory write of word_count words at address addr
class axil_wr_sequence extends uvm_sequence #(axil_item);
    `uvm_object_utils(axil_wr_sequence);

    rand bit [5:0] word_count; // 4 byte words
    rand bit [23:0] addr;

    constraint addr_lim {
        addr[23:22] == 2'b00;
        (addr+word_count*4) <= 4194303;
    }
    
    function new(string name = "axil_wr_sequence");
        super.new(name);
    endfunction: new

    extern virtual task body();

endclass: axil_wr_sequence

task axil_wr_sequence::body();
    axil_addr_item addr_item;
    axil_wdata_item data_item;
    axil_wr_item wr_item;

    addr_item = axil_addr_item::type_id::create("addr_item");
    data_item = axil_wdata_item::type_id::create("data_item");
    wr_item = axil_wr_item::type_id::create("wr_item");

    // set addr bit
    `uvm_info("wr_seqeunce", "set address bit", UVM_NONE)
    start_item(addr_item);
    finish_item(addr_item);
    // set mem write address
    `uvm_info("wr_seqeunce", "sending address", UVM_NONE)
    start_item(data_item);
    data_item.set_addr(addr);
    finish_item(data_item);
    
    `uvm_info("wr_seqeunce", "loading tx buffer", UVM_NONE)
    for (int i=0; i<word_count; i=i+1) begin
        start_item(data_item);
        if (!data_item.randomize())
            `uvm_error("axil_wr_sequence", "failed to randomize data_item")
        finish_item(data_item);
    end

    `uvm_info("wr_seqeunce", "starting write", UVM_NONE)
    // set write bit
    start_item(wr_item);
    finish_item(wr_item);
    `uvm_info("axil_wr_sequence", $psprintf("starting %d byte write at addr=%h", word_count*4, addr), UVM_NONE)
endtask