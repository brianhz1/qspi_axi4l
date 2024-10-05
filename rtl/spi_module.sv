// operating in spi mode 3
module spi_module 
#(
    parameter sclk_divider = 4 // 100 MHZ base / 4 = 25 MHZ, only use powers of 2
) 
(
    input clk,
    input rst_n,
    input i_start,  // start rw command and stays high. returns to idle after i_start drops and byte is completed 
    input i_rw,     // 0: write, 1: read; sample after command byte is sent
    input i_q_mode, // 0: single data, 1: quad rw
    input i_dummy, // insert dummy byte in WRITE state
    input i_data_read, // knocks down o_dval
    input [7:0] i_data,
    output [7:0] o_data,  // read data
    output o_dval,  // read data valid, high for when data should be read
    output o_dload, // high when load data into shift register
    output o_ready, // high when module is ready to receive a new command
    output o_sclk,
    output o_cs,
    inout [3:0] SIO // SIO[0]: SI, SIO[1]: SO
);

    typedef enum logic [2:0] {IDLE, FRONT, COMMAND, WRITE, READ, READ_Q, WRITE_Q} state_t;

    state_t state, next_state;
    logic [$clog2(sclk_divider)-1:0] sclk_div;

    logic [7:0] spi_shift_reg;
    logic [3:0] sample_reg;
    logic [2:0] counter;
    logic dval_buffer;

    logic gen_sclk;
    logic ld_SCLK;
    logic shift;
    logic q_shift;
    logic load;
    logic sample;
    logic cs;
    logic dval;
    logic qsel;
    logic q_rw;
    logic ready;
    logic rst_count;

    assign o_ready = ready;
    assign o_dval = dval_buffer;
    assign o_cs = cs;
    assign o_dload = load;
    assign o_data = spi_shift_reg;
    assign SIO = qsel ? (q_rw ? 4'hz : spi_shift_reg[7:4]) : {3'hz, spi_shift_reg[7]};

    // counter
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            counter <= 0;
        else if (rst_count)
            counter <= 0;
        else if (shift | q_shift)
            counter <= counter + 1;
    end

    // sample reg
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            sample_reg <= 8'h00;
        else if (sample)
            sample_reg <= SIO;
    end

    // dval buffer
    always_ff @(posedge clk) begin
        if (!rst_n)
            dval_buffer <= 0;
        else if (i_data_read)
            dval_buffer <= 0;
        else if (shift | q_shift | load)
            dval_buffer <= dval;
    end

    // shift register
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            spi_shift_reg <= 8'h00;
        else if (load)
            spi_shift_reg <= i_data;
        else if (shift)
            spi_shift_reg <= {spi_shift_reg[6:0], sample_reg[1]};
        else if (q_shift)
            spi_shift_reg <= {spi_shift_reg[3:0], sample_reg};            
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        gen_sclk = 1;
        ld_SCLK = 0;
        shift = 0;
        q_shift = 0;
        load = 0;
        sample = 0;
        cs = 0;
        dval = 0;
        qsel = 0;
        q_rw = 1;
        ready = 0;
        rst_count = 0;

        case (state) 
            FRONT: begin
                if (&sclk_div) begin
                    next_state = COMMAND;
                end
            end
        
            COMMAND: begin
                if (&sclk_div) begin
                    shift = 1;
                    if (&counter) begin
                        if (i_rw) 
                            if (i_q_mode)
                                next_state = READ_Q;
                            else
                                next_state = READ;
                        else begin
                            load = 1;
                            if (i_q_mode)
                                next_state = WRITE_Q;
                            else
                                next_state = WRITE;
                        end
                    end
                end
            end

            WRITE: begin
                if (&sclk_div) begin
                    shift = 1;
                    if (&counter) begin
                        if (!i_start) begin
                            next_state = IDLE;
                            ld_SCLK = 1;
                        end 
                        else if (i_q_mode) begin 
                            if (i_rw)
                                next_state = READ_Q;
                            else begin
                                load = 1;
                                next_state = WRITE_Q;
                            end
                        end
                        else if (!i_dummy)
                            load = 1;
                    end
                end 
            end

            READ: begin
                if (&sclk_div) begin
                    shift = 1;
                    if (&counter) begin
                        dval = 1;
                        if (!i_start) begin
                            next_state = IDLE;
                            ld_SCLK = 1;
                        end 
                    end
                end if (sclk_div == {1'b0, {$clog2(sclk_divider)-1{1'b1}}}) begin
                    sample = 1;
                end
            end

            WRITE_Q: begin
                q_rw = 0;
                qsel = 1;
                if (&sclk_div) begin
                    q_shift = 1;
                    if (counter == 1) begin
                        rst_count = 1;
                        if (!i_start) begin
                            next_state = IDLE;
                            ld_SCLK = 1;
                        end 
                        else 
                            load = 1;
                    end
                end 
            end
            READ_Q: begin
                q_rw = 1;
                qsel = 1;
                if (&sclk_div) begin
                    q_shift = 1;
                    if (counter == 1) begin
                        rst_count = 1;
                        dval = 1;
                        if (!i_start) begin
                            next_state = IDLE;
                            ld_SCLK = 1;
                        end 
                    end
                end if (sclk_div == {1'b0, {$clog2(sclk_divider)-1{1'b1}}}) begin
                    sample = 1;
                end
            end

            default: begin  // IDLE
                cs = 1;
                ready = 1;
                gen_sclk = 0;
                if (i_start) begin
                    next_state = FRONT;
                    load = 1;
                    ld_SCLK = 1;
                end
            end
        endcase
    end

    // sclk generator
    always_ff @(posedge clk) begin
        if (ld_SCLK)
            sclk_div <= {1'b1, {$clog2(sclk_divider)-1{1'b0}}};
        else if (gen_sclk)
            sclk_div <= sclk_div + 1;
    end

    assign o_sclk = (sclk_div[$clog2(sclk_divider)-1]);

endmodule