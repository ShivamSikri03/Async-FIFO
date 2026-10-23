
module sync_2ff #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                  dest_clk,   // Destination clock
    input  wire                  dest_rst_n, // Active-low asynchronous reset
    input  wire [ADDR_WIDTH:0]   async_in,   // Asynchronous Gray-code input
    output reg  [ADDR_WIDTH:0]   sync_out    // Synchronized output
);

    // Intermediate register between stage 1 and stage 2
    reg [ADDR_WIDTH:0] stage1_reg;

    always @(posedge dest_clk or negedge dest_rst_n) begin
        if (!dest_rst_n) begin
            stage1_reg <= {(ADDR_WIDTH+1){1'b0}};
            sync_out   <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            stage1_reg <= async_in;    // 1st flop: samples async signal (may go metastable)
            sync_out   <= stage1_reg; // 2nd flop: samples settled value
        end
    end

endmodule
