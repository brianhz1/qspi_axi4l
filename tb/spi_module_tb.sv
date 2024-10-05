module spi_module_tb ();
    logic clk;
    logic rst_n;
    logic i_start;
    logic i_rw;
    logic i_q_mode;
    logic [7:0] i_data;
    logic [3:0] SIO_data;
    wire [3:0] SIO;
    logic [7:0] o_data;

    assign SIO = SIO_data;

    spi_module u_spi_module (
        .clk         (clk),
        .rst_n       (rst_n),
        .i_start     (i_start),
        .i_rw        (i_rw),
        .i_q_mode    (i_q_mode),
        .i_data      (i_data),
        .o_data      (o_data),
        .o_dval      (o_dval),
        .o_dload     (o_dload),
        .o_sclk      (o_sclk),
        .o_cs        (o_cs),
        .SIO         (SIO),
        .o_ready     (o_ready)
    );  

    // quad test
    initial begin
        clk = 0;
        rst_n = 0;
        i_start = 0;
        i_rw = 0;
        i_q_mode = 1;
        i_data = 0;
        SIO_data = 4'hz;

        @(negedge clk);
        rst_n = 1;
        @(posedge clk);
        #1;
        i_data = 8'haa;
        i_start = 1;
        @(posedge o_dload);
        i_data = 8'h5A;

        repeat(2) @(posedge o_dload);
        @(posedge clk);
        i_start = 0;

        @(posedge o_ready);
        #1;
        i_data = 8'h55;
        i_start = 1;
        i_rw = 1;
        SIO_data = 4'h5;
        @(posedge o_dval);
        SIO_data = 4'hA;
        @(posedge clk);
        i_start = 0;
        @(posedge o_dval)
        #100;
        $stop();
    end

    // non quad test
    /* initial begin
        clk = 0;
        rst_n = 0;
        i_start = 0;
        i_rw = 0;
        i_q_mode = 0;
        i_data = 0;
        SIO_data = 4'hz;

        @(negedge clk);
        rst_n = 1;
        @(posedge clk);
        #1;
        i_data = 8'haa;
        i_start = 1;
        @(posedge o_dload);
        i_data = 8'h55;

        repeat (2) @(posedge o_dload);
        @(posedge clk);
        i_start = 0;

        @(posedge o_ready);
        #1;
        i_data = 8'haa;
        i_start = 1;
        i_rw = 1;
        SIO_data = 4'bzz1z;
        @(posedge o_dval);
        @(posedge clk);
        i_start = 0;
        @(posedge o_dval)
        #100;
        $stop();
    end
    */

    always
        #10 clk = ~clk; 

endmodule