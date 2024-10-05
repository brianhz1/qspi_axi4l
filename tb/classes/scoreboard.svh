import axil_pkg::*;

`uvm_analysis_imp_decl(_spi)
`uvm_analysis_imp_decl(_axil)
class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_axil #(axil_m_item, scoreboard) axil_export;  // axil input
    uvm_analysis_imp_spi #(spi_item, scoreboard) spi_export;  // spi input

    byte mem[int];
    bit [7:0] last_cmd;

    byte tx_buffer[256];
    bit [23:0] spi_address;
    bit [23:0] axil_address;
    int spi_byte_count; // index into tx buffer
    int tx_word;
    int tx_word_last;
    int address_index; // loading spi address

    int spi_bytes_sent; // count bytes written over spi
    int bytes_written;  // count expected bytes written over spi

    // coverage variables
    real cov_report;
    register_t axil_reg;
    rw_t axil_rw;

    covergroup axil_func;
        cp_register: coverpoint axil_reg {
            bins registers[] = {STATUS, CFG, TX, RX};
        }
        cp_rw: coverpoint axil_rw {
            bins rw_op[] = {WRITE, READ};
        }
        cp_addr_edge: coverpoint axil_address {
            bins addr_low[] = {[0:255]};
            bins addr_high[] = {[24'h3FFF00:24'h3FFFFF]};
        }
        register_op: cross cp_register, cp_rw;
        register_addr: cross cp_register, cp_rw, cp_addr_edge {
            bins tx = register_addr with ((axil_reg == TX) && (axil_rw == WRITE));
            bins rx = register_addr with ((axil_reg == RX) && (axil_rw == READ));
        }
    endgroup: axil_func

    function new(string name="scoreboard", uvm_component parent=null);
        super.new(name, parent);
        axil_func = new();

        mem = '{default:0};
        tx_word = 0;
        spi_byte_count = 0;
        spi_bytes_sent = 0;
        bytes_written = 0;
        address_index = 2;
    endfunction: new

    extern function write_axil(axil_m_item item);
    extern function write_spi(spi_item item);
    extern function void build_phase(uvm_phase phase);
    extern function void extract_phase(uvm_phase phase);
    extern function void report_phase(uvm_phase phase);
endclass: scoreboard

function void scoreboard::build_phase(uvm_phase phase);
    axil_export = new("axil_export", this);
    spi_export = new("spi_export", this);
endfunction

function scoreboard::write_axil(axil_m_item item);
    axil_reg = item.register;
    axil_rw = item.rw;
    axil_func.sample();
    if (item.register == TX && item.rw == 0) begin
        if (tx_word == 0) begin
            tx_buffer[tx_word] = item.data[7:0];
            tx_buffer[tx_word+1] = item.data[15:8];
            tx_buffer[tx_word+2] = item.data[23:16];
            tx_word = tx_word+3;

        end
        else begin
            tx_buffer[tx_word] = item.data[7:0];
            tx_buffer[tx_word+1] = item.data[15:8];
            tx_buffer[tx_word+2] = item.data[23:16];
            tx_buffer[tx_word+3] = item.data[31:24];
            tx_word = tx_word+4;
        end
    end
    else if (item.register == CFG && item.rw == 0) begin
        if (item.data[1]) begin // start write
            tx_word = 0;
            tx_word_last = tx_word;
            axil_address = {tx_buffer[0], tx_buffer[1], tx_buffer[2]};
            axil_func.sample();
            for (int i=0; i<tx_word-3; i=i+1) begin
                mem[axil_address+i] = tx_buffer[3+i]; 
                bytes_written++;
                spi_byte_count = 0;
            end
        end
        else if (item.data[0]) begin // start read
            spi_byte_count = 0;
        end
    end
    else if (item.register == RX && item.rw == 1) begin // rx read
        if (item.data != {mem[axil_address+3], mem[axil_address+2], mem[axil_address+1], mem[axil_address]}) begin
            `uvm_error("scoreboard", $psprintf("incorrect data word read at addr: %h", axil_address))
        end
        axil_address = axil_address+4;
    end
endfunction

function scoreboard::write_spi(spi_item item);
    if (item.set_address) begin
        spi_address[address_index*8 +: 8] = item.SPI_data;
        if (address_index != 0)
            address_index = address_index-1;
        else
            address_index = 2;
    end
    else if (item.rw == 0 & item.command == 0) begin
        if (item.SPI_data != tx_buffer[spi_byte_count]) begin
            `uvm_error("scoreboard", "incorrent byte written over SPI")
        end
        spi_bytes_sent++;
        spi_byte_count++;
    end
    else if (item.rw == 1) begin
        if (item.SPI_data != mem[spi_address]) begin
            `uvm_error("scoreboard", $psprintf("incorrent byte read over SPI, addr: %h", spi_address))
        end
        spi_address++;
    end
endfunction

function void scoreboard::extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    cov_report = axil_func.get_inst_coverage();
endfunction: extract_phase

function void scoreboard::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_name(), $psprintf("total bytes written: %d of %d expected", spi_bytes_sent, bytes_written), UVM_NONE)
    `uvm_info(get_name(), $sformatf("Coverage = %0.2f %%", cov_report), UVM_NONE)    
endfunction: report_phase