// axil monitor item
import axil_pkg::*;

class axil_m_item extends uvm_sequence_item;
    typedef axil_m_item this_type_t;
    `uvm_object_utils(axil_m_item);

    register_t register;
    rw_t rw;
    bit [31:0] data;

    function new(string name = "axil_m_item");
        super.new(name);
    endfunction: new
endclass: axil_m_item