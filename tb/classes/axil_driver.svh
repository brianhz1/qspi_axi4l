class axil_driver extends uvm_driver #(axil_item);
    `uvm_component_utils(axil_driver)

    virtual axil_intf vif;
    axil_item item;

    // constructor
    function new(string name="axil_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass : axil_driver

function void axil_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axil_intf)::get(this, "", "AXIL_VIF", vif)) begin
        `uvm_fatal(get_name(), ".vif is not set")
    end
endfunction: build_phase

task axil_driver::run_phase(uvm_phase phase);
    // initial bus values
    // read addr
    vif.arvalid <= 0;
    vif.araddr <= 0;

    // read data
    vif.rready <= 0;

    // write addr
    vif.awvalid <= 0;
    vif.awaddr <= 0;

    // write data
    vif.wvalid <= 0;
    vif.wdata <= 0;
    vif.wstrb <= '1;

    // write response
    vif.bready <= 0;

    forever begin 
        seq_item_port.get_next_item(item);
        @(posedge vif.clk);
        if (item.rw) begin // read
            if (item.addr[3:2] == 2'b11) begin
                vif.araddr <= 0;
                vif.arvalid <= 1;
                vif.rready <= 1;
                
                fork
                    forever begin: wait_available
                        if (vif.arready && vif.rvalid 
                            && (vif.rresp == 0) && vif.rdata[1] == 1'b1) begin
                            @(posedge vif.clk);
                            vif.araddr[3:2] <= 2'b11;
                            vif.arvalid <= 1;
                            vif.rready <= 1;
                            @(posedge vif.rvalid);
                            @(posedge vif.clk);
                            vif.arvalid <= 0;
                            vif.rready <= 0;
                            disable timeout_rd;
                            disable wait_available;
                        end
                        @(posedge vif.clk);
                    end: wait_available

                    begin: timeout_rd
                        #1000000;
                        disable wait_available;
                        vif.arvalid <= 0;
                        vif.rready <= 0;
                        `uvm_info("axil_driver", "read timed out", UVM_HIGH)
                    end: timeout_rd
                join_any

            end  
        end
        else begin // write
            vif.wdata <= item.data;
            vif.wvalid <= 1;
            vif.awaddr <= item.addr;
            vif.awvalid <= 1;
            vif.bready <= 1;
            
            fork
                forever begin: wait_resp
                    if (vif.awready && vif.wready 
                        && (vif.bresp == 0) && vif.bvalid) begin
                        @(posedge vif.clk);
                        vif.wvalid <= 0;
                        vif.awvalid <= 0;
                        vif.bready <= 0;
                        disable timeout_wr;
                        disable wait_resp;
                    end
                    @(posedge vif.clk);
                end: wait_resp

                begin: timeout_wr
                    #1000000;
                    disable wait_resp;
                    `uvm_info("axil_driver", "write timed out", UVM_HIGH)
                    vif.wvalid <= 0;
                    vif.awvalid <= 0;
                    vif.bready <= 0;
                end: timeout_wr
            join_any
        end
        seq_item_port.item_done();
    end 
endtask: run_phase