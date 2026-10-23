
module wptr_full #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  winc,       // Write increment request
    input  wire [ADDR_WIDTH:0]   wq2_rptr,   // Synchronized rptr (from rclk domain)
    output reg                   wfull,      // FIFO full flag
    output wire [ADDR_WIDTH-1:0] waddr,      // Binary write address to memory
    output reg  [ADDR_WIDTH:0]   wptr        // Gray-code write pointer to rclk domain
);

    reg  [ADDR_WIDTH:0] wbin;
    wire [ADDR_WIDTH:0] wbinnext;
    wire [ADDR_WIDTH:0] wgraynext;
    wire                wfull_val;

    // Increment binary pointer only if write is requested and FIFO is not full
    assign wbinnext  = wbin + (winc & ~wfull);

    // Binary-to-Gray conversion
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    // Lower N bits address the dual-port memory
    assign waddr     = wbin[ADDR_WIDTH-1:0];

    // Full condition: MSB & 2nd MSB inverted, remaining bits identical
    assign wfull_val = (wgraynext == {~wq2_rptr[ADDR_WIDTH : ADDR_WIDTH-1], 
                                       wq2_rptr[ADDR_WIDTH-2 : 0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin  <= {(ADDR_WIDTH+1){1'b0}};
            wptr  <= {(ADDR_WIDTH+1){1'b0}};
            wfull <= 1'b0; // FIFO starts NOT full
        end else begin
            wbin  <= wbinnext;
            wptr  <= wgraynext;
            wfull <= wfull_val;
        end
    end

endmodule
