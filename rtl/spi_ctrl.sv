module spi_ctrl
(
    input clk,
    input rst_n,
    input i_ready,
    input i_dload,
    input i_dval,
    input i_read,
    input i_write,
    input i_tx_empty,
    input [7:0] i_byte_count, // not including cmd and addr
    output o_d_source, // 0: fifo, 1: spi_ctrl
    output [7:0] o_data,
    output o_start,
    output o_rw,
    output o_q_mode,
    output o_dummy,
    output o_complete,  // assert on r/w completion
    output o_tx_rd,
    output o_rx_wr,
    output o_wip  // write in progress
);
    // sets status and configuration register before entering idle
    typedef enum logic [2:0] {WREN, WRSR, STATUS_R, CONFIG_R, IDLE, ADDRESS, READ, WRITE} state_t;
    state_t state, next_state;

    logic [1:0] status_reg; // [1]: TX_full, [0] RX_full
    logic [7:0] byte_count;
    logic [2:0] add_counter; // counts r/w address bytes

    logic d_source;
    logic [7:0] data;
    logic start;
    logic rw;
    logic q_mode;
    logic dec;
    logic init;
    logic dummy;
    logic rx_wr;
    logic complete;
    logic inc;
    logic tx_rd;
    logic wip;

    assign o_d_source = d_source;
    assign o_data = data;
    assign o_start = start;
    assign o_rw = rw;
    assign o_q_mode = q_mode;
    assign o_dummy = dummy;
    assign o_rx_wr = rx_wr;
    assign o_tx_rd = tx_rd;
    assign o_complete = complete;
    assign o_wip = wip;

    // state
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= WREN;
        else
            state <= next_state;
    end

    // byte counter, counts bytes left to read
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            byte_count <= 0;
        else if (init)
            byte_count <= i_byte_count;
        else if (dec)
            byte_count <= byte_count - 1;
    end

    // address counter 
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            add_counter <= 0;
        else if (init)
            add_counter <= 0;
        else if (inc)
            add_counter <= add_counter + 1;
    end

    always_comb begin
        next_state = state;
        d_source = 0;
        data = 0;
        start = 0;
        rw = 0;
        q_mode = 0;
        dec = 0;
        init = 0;
        inc = 0;
        dummy = 0;
        complete = 0;
        wip = 0;

        case (state)
            WRSR: begin
                start = 1;
                d_source = 1;
                data = 8'h01;
                if (i_dload)
                    next_state = STATUS_R;
            end

            STATUS_R: begin
                start = 1;
                d_source = 1;
                data = 8'b01000011;
                if (i_dload)
                    next_state = CONFIG_R;
            end

            CONFIG_R: begin
                start = 1;
                d_source = 1;
                data = 8'b00000000;
                if (i_dload)
                    next_state = IDLE;
            end

            IDLE: begin
                if (i_ready) begin
                    if (i_read) begin
                        start = 1;
                        init = 1;
                        next_state = ADDRESS;
                        d_source = 1;
                        data = 8'h6B;
                    end
                    if (i_write) begin
                        start = 1;
                        init = 1;
                        next_state = ADDRESS;
                        d_source = 1;
                        data = 8'h38;
                    end
                end
            end

            ADDRESS: begin
                start = 1;  
                if (i_read) begin
                    if (add_counter == 3'b011)
                        dummy = 1;
                    if (add_counter == 3'b100) begin
                        rw = 1;
                        next_state = READ;
                        q_mode = 1;
                    end
                    else if (i_dload)
                        inc = 1;
                end
                else if (i_write) begin
                    q_mode = 1;
                    if (add_counter == 3'b011)
                        next_state = WRITE;
                    else if (i_dload)
                        inc = 1;
                end
            end

            READ: begin // QREAD, reads i_byte_count bytes, 256 byte max
                start = 1;
                q_mode = 1;
                rw = 1;
                if (i_dval) begin
                    rx_wr = 1;
                    dec = 1;
                end
                if (byte_count == 1 || byte_count == 0) begin
                    start = 0;
                end 
                if (i_ready) begin
                    next_state = IDLE;
                    complete = 1;
                end
            end

            WRITE: begin // 4PP, writes until tx buffer is empty
                wip = 1;
                start = 1;
                q_mode = 1;
                if (i_dload) begin
                    tx_rd = 1;
                end
                if (i_tx_empty) begin
                    start = 0;
                    if (i_ready) begin
                        next_state = IDLE;
                        complete = 1;
                    end
                end 
            end

            // WREN
            default: begin
                start = 1;
                d_source = 1;
                data = 8'h06;
                rw = 0;
                if (i_dload)
                    next_state = WRSR;
            end
        endcase 
    end
endmodule