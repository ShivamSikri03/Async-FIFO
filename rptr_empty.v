module rptr_empty #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire                  rinc,       // Read increment request
    input  wire [ADDR_WIDTH:0]   rq2_wptr,   // Synchronized wptr (from wclk domain)
    output reg                   rempty,     // FIFO empty flag
    output wire [ADDR_WIDTH-1:0] raddr,      // Binary read address to memory
    output reg  [ADDR_WIDTH:0]   rptr        // Gray-code read pointer to wclk domain
);

    reg  [ADDR_WIDTH:0] rbin;
    wire [ADDR_WIDTH:0] rbinnext;
    wire [ADDR_WIDTH:0] rgraynext;
    wire                rempty_val;

    // Increment binary pointer only if read is requested and FIFO is not empty
    assign rbinnext  = rbin + (rinc & ~rempty);

    // Binary-to-Gray conversion
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;

    // Lower N bits address the dual-port memory
    assign raddr     = rbin[ADDR_WIDTH-1:0];

    // Empty condition: next read Gray pointer equals synchronized write Gray pointer
    assign rempty_val = (rgraynext == rq2_wptr);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin   <= {(ADDR_WIDTH+1){1'b0}};
            rptr   <= {(ADDR_WIDTH+1){1'b0}};
            rempty <= 1'b1; // FIFO starts EMPTY
        end else begin
            rbin   <= rbinnext;
            rptr   <= rgraynext;
            rempty <= rempty_val;
        end
    end

endmodule
