/*
    a_signal -> a_pulse -> FF1 -> FF2 -> FF3 -> b_signal
*/
module pulse_sync (
    input  logic clk_a,
    input  logic rst_a,
    input  logic a,

    input  logic clk_b,
    input  logic rst_b,
    output logic b
);
    logic toggle_a;
    always_ff @(posedge clk_a) begin
        if (rst_a) begin
            toggle_a <= '0;
        end else  begin
            toggle_a <= (a)? ~toggle_a : toggle_a;
        end
    end

    (* ASYNC_REG = "TRUE" *) logic ff1, ff2;
    logic ff3;
    always_ff @(posedge clk_b) begin
        if (rst_b) begin
            ff1 <= '0;
            ff2 <= '0;
            ff3 <= '0;
        end else begin
            ff1 <= toggle_a;
            ff2 <= ff1;
            ff3 <= ff2;
        end
    end

    assign b = ff2 ^ ff3;

endmodule
