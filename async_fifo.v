// TOP MODULE
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4  // Depth = 2^4 = 16 words
)(
    // Write Interface (wclk domain)
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  winc,
    input  wire [DATA_WIDTH-1:0] wdata,
    output wire                  wfull,

    // Read Interface (rclk domain)
    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire                  rinc,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire                  rempty
);

    // Internal interconnects
    wire [ADDR_WIDTH-1:0] waddr, raddr;
    wire [ADDR_WIDTH:0]   wptr, rptr;
    wire [ADDR_WIDTH:0]   wq2_rptr, rq2_wptr;

    // 1. Dual-Port Memory Storage
    fifomem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifomem (
        .wclk   (wclk),
        .wclken (winc & ~wfull),
        .waddr  (waddr),
        .wdata  (wdata),
        .raddr  (raddr),
        .rdata  (rdata)
    );

    // 2. Synchronize Read Pointer into Write Clock Domain (wclk)
    sync_2ff #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_sync_r2w (
        .dest_clk   (wclk),
        .dest_rst_n (wrst_n),
        .async_in   (rptr),
        .sync_out   (wq2_rptr)
    );

    // 3. Synchronize Write Pointer into Read Clock Domain (rclk)
    sync_2ff #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_sync_w2r (
        .dest_clk   (rclk),
        .dest_rst_n (rrst_n),
        .async_in   (wptr),
        .sync_out   (rq2_wptr)
    );

    // 4. Write Pointer & Full Flag Generation
    wptr_full #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_wptr_full (
        .wclk     (wclk),
        .wrst_n   (wrst_n),
        .winc     (winc),
        .wq2_rptr (wq2_rptr),
        .wfull    (wfull),
        .waddr    (waddr),
        .wptr     (wptr)
    );

    // 5. Read Pointer & Empty Flag Generation
    rptr_empty #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_rptr_empty (
        .rclk     (rclk),
        .rrst_n   (rrst_n),
        .rinc     (rinc),
        .rq2_wptr (rq2_wptr),
        .rempty   (rempty),
        .raddr    (raddr),
        .rptr     (rptr)
    );

endmodule
