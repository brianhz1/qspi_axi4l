// random r/w operations
class axil_rw_sequence #(wr_weight=1, rd_weight=1) extends uvm_sequence #(axil_item);
    `uvm_object_utils(axil_rw_sequence#(wr_weight, rd_weight))

    rand int transaction_count;
    bit rw_select;

    constraint limit_transaction_c {transaction_count inside {[10:1000]};}

    function new(string name = "axil_rw_sequence");
        super.new(name);
    endfunction: new

    extern virtual task body();
endclass: axil_rw_sequence

task axil_rw_sequence::body();
    int complete_count;
    axil_wr_sequence wr_sequence;
    axil_rd_sequence rd_sequence;

    complete_count = 0;
    wr_sequence = axil_wr_sequence::type_id::create("wr_sequence");
    rd_sequence = axil_rd_sequence::type_id::create("rd_sequence");

    `uvm_info("axi_rw_sequence", $psprintf("starting r/w sequence with %d transactions", transaction_count), UVM_NONE)
    for (int i=0; i<transaction_count; i=i+1) begin
        if (!(std::randomize(rw_select) with {rw_select dist {0:=wr_weight, 1:=rd_weight};})) begin
            `uvm_error("axil_rw_sequence", "failed to randomize rw_select")
        end
        if (rw_select) begin
            `uvm_do(rd_sequence)
        end
        else begin
            `uvm_do(wr_sequence)
        end

        complete_count++;
        `uvm_info("axi_rw_sequence", $psprintf("completed transaction %d of %d", complete_count, transaction_count), UVM_NONE)
    end
    
    `uvm_info("axi_rw_sequence", "completed all transactions", UVM_NONE)
endtask