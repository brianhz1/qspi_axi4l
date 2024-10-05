class rd_bias_test extends uvm_test;
    `uvm_component_utils(rd_bias_test)

    virtual axil_intf axil_vif;
    virtual spi_intf spi_vif;

    axil_rw_sequence #(.wr_weight(0), .rd_weight(1)) axil_rw_sequence_h;
    basic_env basic_env_h;

    function new(string name="rd_bias_test", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);    
endclass

function void rd_bias_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axil_intf)::get(this, "", "AXIL_VIF", axil_vif)) begin
        `uvm_fatal(get_name(), "could not get AXIL_VIF")
    end
    if(!uvm_config_db#(virtual spi_intf)::get(this, "", "SPI_VIF", spi_vif)) begin
        `uvm_fatal(get_name(), "could not get SPI_VIF")
    end
    uvm_config_db #(virtual axil_intf)::set(this, "*", "AXIL_VIF", axil_vif);
    uvm_config_db #(virtual spi_intf)::set(this, "*", "SPI_VIF", spi_vif);

    axil_rw_sequence_h = axil_rw_sequence#(.wr_weight(0), .rd_weight(1))::type_id::create("axil_rw_sequence_h");
    basic_env_h = basic_env::type_id::create("basic_env_h", this);
endfunction: build_phase

task rd_bias_test::run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_name(), "<run_phase> started, objection raised.", UVM_NONE)

    if (!axil_rw_sequence_h.randomize()) begin
        `uvm_fatal(get_name(), "failed to randomize axil_rw_sequence_h")
    end

    // wait for reset
    wait (axil_vif.rst_n == 1);
    axil_rw_sequence_h.start(basic_env_h.axil_m_agent_h.sequencer_h);

    #1000000;
    phase.drop_objection(this);
    `uvm_info(get_name(), "<run_phase> finished, objection dropped.", UVM_NONE)
endtask: run_phase

