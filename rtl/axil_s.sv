module axil_s
#(
    parameter AXI_ADDR_WIDTH = 4,
    localparam AXI_DATA_WIDTH = 32  // AXIL fixed width 
)
(
    input clk,
    input rst_n,
    // spi control signals
    input i_rx_empty,
    input [7:0] i_rx_byte,
    input i_complete,
    input i_wip,
    output o_rx_rd,
    output o_tx_wr,
    output o_tx_byte,
    output o_write,
    output o_read,
    output [7:0] o_byte_count,

    // read addr
    input i_arvalid,
    output o_arready,
    input [AXI_ADDR_WIDTH-1:0] i_araddr,

    // read data
    output o_rvalid,
    input i_rready,
    output [AXI_DATA_WIDTH-1:0] o_rdata,
    output [1:0] o_rresp,

    // write addr
    input i_awvalid,
    output o_awready,
    input [AXI_ADDR_WIDTH-1:0] i_awaddr,

    // write data
    input i_wvalid,
    output o_wready,
    input [AXI_DATA_WIDTH-1:0] i_wdata,
    input [AXI_DATA_WIDTH/8-1:0] i_wstrb,

    // write response
    output o_bvalid,
    input  i_bready,
    output [1:0] o_bresp
);

    localparam ADDR_LSB = $clog2(AXI_DATA_WIDTH)-3; // register addressable
    
    logic [AXI_ADDR_WIDTH-ADDR_LSB-1:0] w_addr, r_addr; 
    logic [AXI_DATA_WIDTH-1:0] cfg; // cfg[0]: read, cfg[1]: write, cfg[9:2]: byte_count, cfg[10] address
    logic [AXI_DATA_WIDTH-1:0] status;  // status[0]: WIP, status[1]: read available
    logic [AXI_DATA_WIDTH-1:0] tx, rx;
    logic [AXI_DATA_WIDTH-1:0] rx_next;
    logic [AXI_ADDR_WIDTH-1:0] read_data;
    logic [AXI_DATA_WIDTH-1:0] wstrb_status, wstrb_cfg, wstrb_tx;
    logic [1:0] bresp;
    logic bvalid, rvalid;
    logic aw_ready;
    wire [31:0] status_next;
    wire read_available;

    // tracks when rx can be read, is always set when fifo is empty, drops on read
    logic rx_dload_c;
    // tracks when tx can be written to, drops when all bytes written to fifo 
    logic tx_write_c;

    assign status_next = {30'h00000000, rx_dload_c, i_wip};

    assign o_read = cfg[0];
    assign o_write = cfg[1];
    assign o_byte_count = cfg[9:2];

    assign w_addr = i_awaddr[AXI_ADDR_WIDTH-1:ADDR_LSB];
    assign r_addr = i_araddr[AXI_ADDR_WIDTH-1:ADDR_LSB];
    assign wstrb_cfg = apply_wstrb(cfg, i_wdata, i_wstrb);
    assign wstrb_tx = apply_wstrb(tx, i_wdata, i_wstrb);

    assign read_ready = (i_arvalid & o_arready) & !((r_addr == 2'b11) & !rx_dload_c);
    assign write_ready = o_wready;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            aw_ready <= 0;
        else
            aw_ready <= (i_awvalid & i_wvalid) 
                        & (!o_bvalid | i_bready) // output stall
                        & !aw_ready;             // prevent response loss
    end
    
    assign o_awready = aw_ready;
    assign o_wready = aw_ready & !((w_addr == 2'b10) & !tx_write_c);

    assign o_arready = ~o_rvalid;

    // rx fifo read
    logic [1:0] rx_counter;
    logic load; // reads from rx fifo
    logic set; // sets rx_dload_c

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            rx_counter <= 0;
        else if (load)
            rx_counter <= rx_counter+1;
        else if (rvalid & (r_addr == 2'b11))
            rx_counter <= 0;
    end

    always_comb begin
        load = 0;
        set = 0;
        if (!i_rx_empty) begin
            if (!rx_dload_c) begin
                if (rx_counter != 2'b11)
                    load = 1;
                else 
                    set = 1;
            end
            case (rx_counter)
                2'b00: rx_next = {rx[31:8], i_rx_byte};
                2'b01: rx_next = {rx[31:16], i_rx_byte, rx[7:0]};
                2'b10: rx_next = {rx[31:24], i_rx_byte, rx[15:0]};
                2'b11: rx_next = {i_rx_byte, rx[23:0]};
            endcase
        end
        else if (rx_counter != 0)
            set = 1;
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            rx_dload_c <= 0;
        else if (set)
            rx_dload_c <= 1;
        else if (rvalid & (r_addr == 2'b11)) 
            rx_dload_c <= 0;
    end

    // tx fifo write
    logic [1:0] tx_counter;
    logic tx_wr;
    logic [7:0] tx_byte;
    logic complete_txwc, set_txwc;

    assign o_tx_wr = tx_wr;
    assign o_tx_byte = tx_byte;

    always_comb begin
        set_txwc = 0;
        complete_txwc = 0;
        tx_byte = tx[7:0];
        tx_wr = 0;

        if (o_wready && (w_addr == 2'b10) & !tx_write_c) begin
            set_txwc = 1;
        end
        else if (tx_write_c) begin
            tx_wr = 1;
            if (cfg[10]) 
                case (tx_counter)
                    2'b00: tx_byte = tx[23:16];
                    2'b01: tx_byte = tx[15:8];
                    2'b10: begin
                        tx_byte = tx[7:0];
                        complete_txwc = 1;
                    end
                endcase
            else begin 
                case (tx_counter)
                    2'b00: tx_byte = tx[7:0];
                    2'b01: tx_byte = tx[15:8];
                    2'b10: tx_byte = tx[23:16];
                    2'b11: begin 
                        tx_byte = tx[31:24];
                        complete_txwc = 1;
                    end
                endcase
            end
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            tx_write_c <= 0;
        else if (set_txwc)
            tx_write_c <= 1; 
        else if (complete_txwc)
            tx_write_c <= 0;
    end

    // write handshake
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            bresp <= 0;
        else if ((w_addr == 2'b10) | (w_addr == 2'b00) 
                | tx_write_c | cfg[0] | cfg[1])
            bresp <= 2'b10;
        else if (!i_bready)
            bresp <= 0;
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            bvalid <= 0;
        else if (o_wready) 
            bvalid <= 1;
        else if (i_bready)
            bvalid <= 0;
    end

    assign o_bresp = bresp;
    assign o_bvalid = bvalid;

    // read handshake
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            rvalid <= 0;
        else if (read_ready) 
            rvalid <= 1;
        else if (i_rready)
            rvalid <= 0;
    end

    assign o_rresp = 0;
    assign o_rvalid = rvalid;

    // register write
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cfg <= 0;
        end 
        else if (write_ready & (w_addr == 2'b01) 
                & ~(cfg[0] | cfg[1])) begin
            cfg <= wstrb_cfg;
        end
        else if (i_complete)
            cfg <= (cfg & 32'hFFFFFFFC);
        else if (complete_txwc)
            cfg <= (cfg & 32'hFFFFFBFF);
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            tx <= 0;
        end 
        else if (write_ready & (w_addr == 2'b10) & ~tx_write_c) begin
            tx <= wstrb_tx;
        end 
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            status <= 0;
        end
        else begin
            status <= status_next;
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            rx <= 0;
        else 
            rx <= rx_next;
    end

    // read data
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            read_data <= 0;
        else if (!o_rvalid | i_rready) begin
                case (r_addr)
                    2'b00:	read_data	<= status;
                    2'b01:	read_data	<= cfg;
                    2'b10:	read_data	<= tx;
                    2'b11:	read_data	<= rx;
                endcase
        end
    end

    assign o_rdata = read_data;

    // masks write data with wstrb
    function [AXI_DATA_WIDTH-1:0] apply_wstrb (
        input	[AXI_DATA_WIDTH-1:0]		old_data,
        input	[AXI_DATA_WIDTH-1:0]		new_data,
        input	[AXI_DATA_WIDTH/8-1:0]	    strb
    );
        
        integer	i;
        for(i = 0; i < AXI_DATA_WIDTH/8; i = i+1) begin
            apply_wstrb[i*8 +: 8]
                = strb[i] ? new_data[i*8 +: 8] : old_data[i*8 +: 8];
        end
    endfunction
endmodule