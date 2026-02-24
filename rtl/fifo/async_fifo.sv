module async_fifo #(parameter DATA_W = 32, parameter DEPTH = 4) (
    input  logic                w_clk,
    input  logic                w_rst,
    input  logic                w_en,
    input  logic [DATA_W-1:0]   w_data,
    output logic                full,

    input  logic                r_clk,
    input  logic                r_rst,
    input  logic                r_en,
    output logic [DATA_W-1:0]   r_data,
    output logic                empty
);
    /*
        PARAMS/HELPERS
    */
    localparam int AW = $clog2(DEPTH);
    localparam int PW = AW + 1; // Extra Wrap Bit

    function automatic logic [PW-1:0] bin2gray (input logic [PW-1:0] b);
        return (b>>1) ^ b;
    endfunction

    initial if ((DEPTH & (DEPTH - 1)) != 0) $error("DEPTH must be power of 2 for gray code");

    /*
        MEMORY
    */
    logic [DATA_W-1:0] mem [DEPTH-1:0];

    /*
        SIGNALS & FFs
    */
    logic [PW-1:0]  w_bin,  w_bin_next;
    logic [PW-1:0]  w_gray, w_gray_next;
    logic           full_next;
    (* ASYNC_REG = "TRUE" *) logic [PW-1:0] r_gray_wff1, r_gray_wff2;

    logic [PW-1:0]  r_bin,  r_bin_next;
    logic [PW-1:0]  r_gray, r_gray_next;
    logic           empty_next;
    (* ASYNC_REG = "TRUE" *) logic [PW-1:0] w_gray_rff1, w_gray_rff2;

    /*
        WRITE HANDLER
    */
    assign w_bin_next   = w_bin + (w_en && !full);
    assign w_gray_next  = bin2gray(w_bin_next);
    assign full_next    = (w_gray_next == {~r_gray_wff2[PW-1:PW-2], r_gray_wff2[PW-3:0]});

    always_ff @(posedge w_clk) begin
        if (w_rst) begin
            w_bin   <= '0;
            w_gray  <= '0;
            full    <= '0;
        end else begin
            w_bin   <= w_bin_next;
            w_gray  <= w_gray_next;
            full    <= full_next;
            
            if (w_en && !full)
                mem[w_bin[AW-1:0]] <= w_data;
        end
    end

    // Sync r_gray (READ) -> (WRITE)
    always_ff @(posedge w_clk) begin
        if (w_rst) begin
            r_gray_wff1 <= '0;
            r_gray_wff2 <= '0;
        end else begin
            r_gray_wff1 <= r_gray;
            r_gray_wff2 <= r_gray_wff1;
        end
    end

    /*
        READ HANDLER
    */
    assign r_bin_next   = r_bin + (r_en && !empty);
    assign r_gray_next  = bin2gray(r_bin_next);
    assign empty_next   = (r_gray_next == w_gray_rff2);

    always_ff @(posedge r_clk) begin
        if (r_rst) begin
            r_bin   <= '0;
            r_gray  <= '0;
            empty    <= '1;
        end else begin
            r_bin   <= r_bin_next;
            r_gray  <= r_gray_next;
            empty    <= empty_next;

            if (r_en && !empty)
                r_data <= mem[r_bin[AW-1:0]];
        end
    end

    // Sync w_gray (WRITE) -> (READ)
    always_ff @(posedge r_clk) begin
        if (r_rst) begin
            w_gray_rff1 <= '0;
            w_gray_rff2 <= '0;
        end else begin
            w_gray_rff1 <= w_gray;
            w_gray_rff2 <= w_gray_rff1;
        end
    end

endmodule