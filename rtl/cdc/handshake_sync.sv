/*
    This Handshake Synchronizer Synchronizes the Control Signals &
    Handles the Handshake FSM in both producer and consumer.
*/

module handshake_sync0 #(parameter DATA_W = 32)(
    input  logic clk_a,
    input  logic rst_a,
    input  logic valid_a,
    input  logic [DATA_W-1:0] data_a,
    output logic ready_a,

    input  logic clk_b,
    input  logic rst_b,
    input  logic ready_b,
    output logic valid_b,
    output logic [DATA_W-1:0] data_b
);  
    logic req_a;
    logic ack_a;
    // A-side FSM: generate req
    always_ff @(posedge clk_a) begin
        if (rst_a) begin
            req_a <= 0;
        end else begin
            if (valid_a && ready_a) // Start transfer
                req_a <= 1;
            else if (ack_a)        // Clear when ack seen
                req_a <= 0;
        end
    end
    assign ready_a = !req_a;

    // SYNC req A -> B
    wire req_b;
    (* ASYNC_REG = "TRUE" *) logic ff1, ff2;
    always_ff @(posedge clk_b) begin
        if (rst_b) begin
            ff1 <= '0;
            ff2 <= '0;
        end else begin 
            ff1 <= req_a;
            ff2 <= ff1;
        end
    end
    assign req_b = ff2;

    // HANDSHAKE DATA
    logic ack_b;
    always_ff @(posedge clk_b) begin
        if (rst_b) begin
            ack_b  <= 0;
            valid_b <= 0;
            data_b <= '0;
        end else begin
            // New request arrives
            if (req_b && !ack_b) begin
                data_b  <= data_a;
                valid_b <= 1;
            end

            // Destination consumes data
            if (valid_b && ready_b) begin
                valid_b <= 0;
                ack_b   <= 1;
            end

            // Clear ack when request drops
            if (!req_b)
                ack_b <= 0;
        end
    end

    // SYNC ack B -> A
    (* ASYNC_REG = "TRUE" *) logic ff3, ff4;
    always_ff @(posedge clk_a) begin
        if (rst_a) begin
            ff3 <= '0;
            ff4 <= '0;
        end else begin

            ff3 <= ack_b;
            ff4 <= ff3;
        end
    end
    assign ack_a = ff4;

    `ifndef SYNTHESIS
        assert (@(posedge clk_a)
            disable iff (rst_a)
            req_a |-> $stable(data_a)
        );
    `endif
endmodule

/* 
    This Handshake Synchronizer Only Synchronizes the Control Signals.
    Ownership of the FSM is handled outside this module. 
*/
module handshake_sync1 #(parameter DATA_W = 32) (
    input  logic clk_a,
    input  logic rst_a,
    input  logic req_a,
    output logic ack_a,

    input  logic clk_b,
    input  logic rst_b,
    output logic req_b,
    input  logic ack_b
);

    (* ASYNC_REG = "TRUE" *) logic ff1, ff2;
    always_ff @(posedge clk_b) begin
        if (rst_b) begin
            ff1 <= '0;
            ff2 <= '0;
        end else begin
            ff1 <= req_a;
            ff2 <= ff1;
        end
    end
    assign req_b = ff2;

    (* ASYNC_REG = "TRUE" *) logic ff3, ff4;
    always_ff @(posedge clk_a) begin
        if (rst_a) begin
            ff3 <= '0;
            ff4 <= '0;
        end else begin
            ff3 <= ack_b;
            ff4 <= ff3;
        end
    end
    assign ack_a = ff4;

    `ifndef SYNTHESIS
        assert (@(posedge clk_a)
            disable iff (rst_a)
            req_a |-> $stable(data_a)
        );
    `endif
endmodule