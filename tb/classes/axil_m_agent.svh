// axil master agent
class axil_m_agent extends uvm_agent;
    `uvm_component_utils(axil_m_agent)
    sequencer sequencer_h;    
    axil_driver axil_driver_h;
    axil_monitor axil_monitor_h;

    uvm_analysis_port #(axil_m_item) axil_m_agent_analysis_port;

    function new(string name="axil_m_agent", uvm_component parent=null);
        super.new(name, parent);
    endfunction: new
    
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
endclass: axil_m_agent

function void axil_m_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer_h = sequencer::type_id::create("sequencer_h", this);
    axil_driver_h = axil_driver::type_id::create("axil_driver_h", this);
    axil_monitor_h = axil_monitor::type_id::create("axil_monitor_h", this);
    axil_m_agent_analysis_port = new("axil_m_agent_analysis_port", this);
endfunction: build_phase

function void axil_m_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axil_driver_h.seq_item_port.connect(sequencer_h.seq_item_export);
    axil_monitor_h.out_port.connect(axil_m_agent_analysis_port);
endfunction: connect_phase

