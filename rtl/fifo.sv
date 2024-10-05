module fifo
#(
    parameter width = 8,
    parameter depth = 256
)
(
    input i_clk,
    input i_rst_n,
    input [width-1:0] i_wdata,
    input i_wr,
    input i_rd,

    output o_full,
    output o_empty,
    output [width-1:0] o_rdata
);

    logic [width-1:0] mem [depth];
    logic [$clog2(depth):0] wptr, rptr;

    logic wen;

    assign o_rdata = mem[rptr];
    assign o_full = {~wptr[$clog2(depth)], wptr[$clog2(depth)-1:0]} == rptr;
    assign o_empty = wptr == rptr;

    assign wen = ~o_full & i_wr;

    always_ff @(posedge i_clk) begin
        if (wen)
            mem[wptr] <= i_wdata;
    end

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            wptr <= 0;
        else if (i_wr & !o_full)
            wptr <= wptr + 1;
    end

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            rptr <= 0;
        else if (i_rd & !o_empty)
            rptr <= rptr + 1;
    end

endmodule