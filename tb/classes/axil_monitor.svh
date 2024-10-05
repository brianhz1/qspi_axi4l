import axil_pkg::*;

class axil_monitor extends uvm_monitor;
    `uvm_component_utils(axil_monitor)

    virtual axil_intf vif;
    uvm_analysis_port #(axil_m_item) out_port;

    function new (string name="axil_monitor", uvm_component parent=null);
        super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual axil_intf)::get(this, "", "AXIL_VIF", vif)) begin
            `uvm_fatal(get_name(), {"virtual interface is not set for ", get_full_name(), ".vif"})
        end
        out_port = new("out_port", this);
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        axil_m_item item;
        item = axil_m_item::type_id::create("item");

        forever begin
            @(posedge vif.clk);
            if (vif.arvalid) begin // read
                item.rw = READ;
                case (vif.awaddr[3:2])
                    2'b00:  item.register = STATUS;
                    2'b01:  item.register = CFG;
                    2'b10:  item.register = TX;
                    2'b11:  item.register = RX;
                endcase 
                while (!vif.rvalid) begin
                    @(posedge vif.clk);
                end
                item.data = vif.rdata;
                out_port.write(item);
                @(negedge vif.arvalid);
            end
            else if (vif.awvalid & vif.wvalid) begin // write
                item.rw = WRITE;
                case (vif.awaddr[3:2])
                    2'b00:  item.register = STATUS;
                    2'b01:  item.register = CFG;
                    2'b10:  item.register = TX;
                    2'b11:  item.register = RX;
                endcase 
                item.data = vif.wdata;
                out_port.write(item);
                @(negedge vif.wvalid);
            end
        end
    endtask: run_phase
endclass