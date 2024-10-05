// memory simulation agent
class mem_agent extends uvm_agent;
    `uvm_component_utils(mem_agent)
    spi_monitor spi_monitor_h;
    mem_sim mem_sim_h;

    uvm_analysis_port #(spi_item) mem_agent_analysis_port;

    function new(string name="mem_agent", uvm_component parent=null);
        super.new(name, parent);
    endfunction: new
    
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
endclass: mem_agent

function void mem_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    mem_agent_analysis_port = new("mem_agent_analysis_port", this);
    mem_sim_h = mem_sim::type_id::create("mem_sim_h", this);
    spi_monitor_h = spi_monitor::type_id::create("spi_monitor_h", this);
endfunction: build_phase

function void mem_agent::connect_phase(uvm_phase phase);    
    super.connect_phase(phase);
    spi_monitor_h.spi_out_port.connect(mem_agent_analysis_port);
endfunction: connect_phase