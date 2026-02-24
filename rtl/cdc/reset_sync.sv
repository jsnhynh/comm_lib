/* 
    Standard Reset Pattern:
        Async assert    (Can happen immediately)
        Sync deassert   (Release in clock domain safely)

    async_rst -> FF1 -> FF2 -> sync_rst
*/

module reset_sync0 (
    input  logic clk,
    input  logic rst_n,
    output logic rst_n_sync
);
    (* ASYNC_REG = "TRUE" *) logic ff1, ff2;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ff1 <= '0;
            ff2 <= '0;
        end else begin
            ff1 <= '1;
            ff2 <= ff1;
        end
    end
    assign rst_n_sync = ff2;
endmodule

module reset_sync1 (
    input  logic clk,
    input  logic rst,
    output logic rst_sync
);
    (* ASYNC_REG = "TRUE" *) logic ff1, ff2;
    always_ff @(posedge clk) begin
        if (rst) begin
            ff1 <= '1;
            ff2 <= '1;
        end else begin
            ff1 <= '0;
            ff2 <= ff1;
        end
    end
endmodule