/*
    a -> FF1 -> FF2 -> b
*/
module dual_ff_sync (
    input logic clk_b,
    input logic rst_b,
    input logic a,
    output logic b
);
    (* ASYNC_REG = "TRUE" *) logic ff1, ff2;

    always_ff @(posedge clk_b) begin
        if (rst_b) begin
            ff1 <= '0;
            ff2 <= '0;
        end else begin
            ff1 <= a;
            ff2 <= ff1;
        end
    end
    assign b = ff2;

endmodule