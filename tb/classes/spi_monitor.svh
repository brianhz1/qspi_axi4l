class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_intf vif;
    uvm_analysis_port #(spi_item) spi_out_port;

    function new (string name="spi_monitor", uvm_component parent=null);
        super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
        spi_out_port = new("spi_out_port", this);
        if(!uvm_config_db#(virtual spi_intf)::get(this, "", "SPI_VIF", vif)) begin
            `uvm_fatal(get_name(), {"virtual interface is not set for ", get_full_name(), ".vif"})
        end
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        spi_item item;
        bit [7:0] spi_byte;
        item = spi_item::type_id::create("item");

        forever begin
            #10;
            if (!vif.CS) begin
                for (int i=7; i>=0; i=i-1) begin
                    @(posedge vif.SCLK);
                    spi_byte[i] = vif.SIO[0];
                end
                item.SPI_data = spi_byte;
                item.rw = 0;
                item.set_address = 0;
                item.command = 1;
                spi_out_port.write(item);
                if (spi_byte == 8'h6b) begin // QREAD
                    // address
                    item.command = 0;
                    item.set_address = 1;
                    for (int byte_c=0; byte_c<3; byte_c=byte_c+1) begin
                        for (int i=7; i>=0; i=i-1) begin
                            @(posedge vif.SCLK);
                            spi_byte[i] = vif.SIO[0];
                        end
                        item.SPI_data = spi_byte;
                        spi_out_port.write(item);
                    end
                    item.set_address = 0;
                    item.rw = 1;

                    repeat (8) @(posedge vif.SCLK); // dummy cycles
                    // data
                    while (!vif.CS) begin
                        for (int i=1; i>=0; i=i-1) begin
                            @(posedge vif.SCLK);
                            spi_byte[i*4 +: 4] = vif.SIO;
                        end
                        item.SPI_data = spi_byte;
                        spi_out_port.write(item);
                    end
                end
                else if (spi_byte == 8'h38) begin // 4PP
                        // address
                        item.command = 0;
                        item.set_address = 1;
                        for (int byte_c=0; byte_c<3; byte_c=byte_c+1) begin
                            for (int i=1; i>=0; i=i-1) begin
                                @(posedge vif.SCLK);
                                spi_byte[i*4 +: 4] = vif.SIO;
                            end
                            item.SPI_data = spi_byte;
                            spi_out_port.write(item);
                        end
                        item.set_address = 0;
                        // data
                        while (!vif.CS) begin
                            for (int i=1; i>=0; i=i-1) begin
                                @(posedge vif.SCLK);
                                spi_byte[i*4 +: 4] = vif.SIO;
                            end
                            item.SPI_data = spi_byte;
                            spi_out_port.write(item);
                        end
                end
                else begin // ignore command
                    @(posedge vif.CS);
                end
            end
        end
    endtask: run_phase
endclass