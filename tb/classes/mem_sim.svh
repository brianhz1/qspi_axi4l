class mem_sim extends uvm_component;
    `uvm_component_utils(mem_sim)
    virtual spi_intf vif;
    byte mem[int];

    function new (string name="spi_monitor", uvm_component parent=null);
        super.new(name, parent);
        mem = '{default:0};
    endfunction: new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual spi_intf)::get(this, "", "SPI_VIF", vif)) begin
            `uvm_fatal(get_name(), {"virtual interface is not set for ", get_full_name(), ".vif"})
        end
    endfunction

    task run_phase(uvm_phase phase);
        bit [7:0] spi_byte;
        bit [23:0] address;
        int offset;
        
        forever begin
            vif.mem_w = 0;
            #10;
            if (!vif.CS) begin
                offset = 0;
                for (int i=7; i>=0; i=i-1) begin
                    @(posedge vif.SCLK);
                    spi_byte[i] = vif.SIO[0];
                end

                if (spi_byte == 8'h6b) begin // QREAD
                    // address
                    for (int byte_c=23; byte_c>=0; byte_c=byte_c-1) begin
                        @(posedge vif.SCLK);
                        address[byte_c] = vif.SIO[0];
                    end
                    repeat (8) @(posedge vif.SCLK); // dummy cycles
                    // data
                    while (!vif.CS) begin
                        for (int i=1; i>=0; i=i-1) begin
                            @(negedge vif.SCLK);
                            vif.mem_sio = mem[address+offset][i*4 +: 4];
                            vif.mem_w = 1;
                        end
                        offset++;
                    end
                end
                else if (spi_byte == 8'h38) begin // 4PP
                    // address
                    for (int i=5; i>=0; i=i-1) begin
                        @(posedge vif.SCLK);
                        address[i*4 +: 4] = vif.SIO;
                    end                    
                    // data
                    while (!vif.CS) begin
                        for (int i=1; i>=0; i=i-1) begin
                            @(posedge vif.SCLK);
                            spi_byte[i*4 +: 4] = vif.SIO;
                        end
                        mem[address+offset] = spi_byte;
                        offset++;
                    end
                end
                else begin // ignore command
                    @(posedge vif.CS);
                end
            end
        end
    endtask: run_phase
endclass: mem_sim