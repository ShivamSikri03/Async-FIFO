module fifomem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH      = 1 << ADDR_WIDTH // 2^ADDR_WIDTH (e.g., 2^4 = 16)
)(
    input  wire                  wclk,
    input  wire                  wclken,   // Write enable (winc & !wfull)
    input  wire [ADDR_WIDTH-1:0] waddr,    // Write address (lower N bits)
    input  wire [DATA_WIDTH-1:0] wdata,    // Write data input
    input  wire [ADDR_WIDTH-1:0] raddr,    // Read address (lower N bits)
    output wire [DATA_WIDTH-1:0] rdata     // Read data output
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Synchronous write
    always @(posedge wclk) begin
        if (wclken) begin
            mem[waddr] <= wdata;
        end
    end

    // Asynchronous read (or register output if preferred)
    assign rdata = mem[raddr];

endmodule
