module sync_fifo #(parameter DEPTH = 8; parameter DATA_W = 32;)(
    input  clk, rst,

    input  logic write, read,
    input  logic [DATA_W-1:0] wdata,

    output logic [DATA_W-1:0] rdata
    output logic full, empty
);
    localparam PTR_W = $clog2(DEPTH);

    logic [DATA_W-1:0] mem [DEPTH-1:0];
    logic [PTR_W:0] wptr, rptr;

    logic wr_en, rd_en;

    assign wr_en = write && (!full || read);
    assign rd_en = read && !empty;


    always_ff @(posedge clk) begin
        if (rst) begin
            wptr <= '0;
            rptr <= '0;
            rdata <= '0;
        end else begin
            // rdata <= '0; // Comment if holding
            if (wr_en) begin
                mem[wptr[PTR_W-1:0]] <= wdata;
                wptr <= wptr + 1;
            end
            
            if (rd_en) begin
                rdata <= mem[rptr[PTR_W-1:0]];
                rptr <= rptr + 1;
            end
        end
    end

    assign full     =   (wptr[PTR_W] != rptr[PTR_W]) &&
                        (wptr[PTR_W-1:0] == rptr[PTR_W-1:0]);
    assign empty    = wptr == rptr;

    initial begin
        if ((DEPTH & (DEPTH-1)) != 0)
            $error("DEPTH must be power of 2");
    end

    `ifndef SYNTHESIS 
        assert (@(posedge clk)
            disable iff (rst)
            !(full && empty)
        );

        assert (@(posedge clk)
            disable iff (rst)
            full && !read |-> !write
        );

        assert (@(posedge clk)
            disable iff (rst)
            empty |-> !read
        );

        assert (@(posedge clk)
            disable iff (rst)
            (wptr - rptr) <= DEPTH
        );
    `endif

endmodule