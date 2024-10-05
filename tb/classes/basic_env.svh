class basic_env extends uvm_env;
    `uvm_component_utils(basic_env)

    mem_agent mem_agent_h;
    axil_m_agent axil_m_agent_h;
    scoreboard scoreboard_h;

    function new(string name="basic_env", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    extern function void build_phase(uvm_phase phase);    
    extern function void connect_phase(uvm_phase phase);
endclass

function void basic_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    mem_agent_h = mem_agent::type_id::create("mem_agent_h", this);
    axil_m_agent_h = axil_m_agent::type_id::create("axil_m_agent_h", this);
    scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);
endfunction: build_phase

function void basic_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mem_agent_h.mem_agent_analysis_port.connect(scoreboard_h.spi_export);
    axil_m_agent_h.axil_m_agent_analysis_port.connect(scoreboard_h.axil_export);
endfunction: connect_phase

