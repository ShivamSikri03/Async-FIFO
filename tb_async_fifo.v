`timescale 1ns / 1ps

// ==============================================================================
// Module: tb_async_fifo
// Description: Self-Checking Testbench for Dual-Clock Asynchronous FIFO
// Clock 1: wclk = 100 MHz (Period = 10ns)
// Clock 2: rclk = 40 MHz  (Period = 25ns)
// Author: Shivam Sikri
// ==============================================================================

module tb_async_fifo;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter DEPTH      = 1 << ADDR_WIDTH; // 16 words

    // DUT Signals
    reg                   wclk;
    reg                   wrst_n;
    reg                   winc;
    reg  [DATA_WIDTH-1:0] wdata;
    wire                  wfull;

    reg                   rclk;
    reg                   rrst_n;
    reg                   rinc;
    wire [DATA_WIDTH-1:0] rdata;
    wire                  rempty;

    // Testbench Variables & Statistics
    integer err_count = 0;
    integer i;
    reg [DATA_WIDTH-1:0] expected_queue [0:255];
    integer q_wr_ptr = 0;
    integer q_rd_ptr = 0;

    // -------------------------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------------------------
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .wdata  (wdata),
        .wfull  (wfull),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .rinc   (rinc),
        .rdata  (rdata),
        .rempty (rempty)
    );

    // -------------------------------------------------------------------------
    // Clock Generation (Uncorrelated Asynchronous Clocks)
    // -------------------------------------------------------------------------
    // wclk: 100 MHz (10 ns period)
    always #5 wclk = ~wclk;

    // rclk: 40 MHz (25 ns period: 12.5ns high / 12.5ns low)
    always #12.5 rclk = ~rclk;

    // -------------------------------------------------------------------------
    // Task: Write a Single Byte to FIFO
    // -------------------------------------------------------------------------
    task write_byte(input [DATA_WIDTH-1:0] data);
    begin
        @(posedge wclk);
        if (wfull) begin
            $display("[WARN @ %0t ns] Attempted to write to FULL FIFO! Data: 0x%02h dropped.", $time, data);
        end else begin
            winc  <= 1'b1;
            wdata <= data;
            expected_queue[q_wr_ptr] = data;
            q_wr_ptr = q_wr_ptr + 1;
            @(posedge wclk);
            winc  <= 1'b0;
            wdata <= 8'hxx;
        end
    end
    endtask

    // -------------------------------------------------------------------------
    // Task: Read a Single Byte from FIFO & Verify
    // -------------------------------------------------------------------------
    task read_byte();
        reg [DATA_WIDTH-1:0] expected_data;
    begin
        @(posedge rclk);
        if (rempty) begin
            $display("[WARN @ %0t ns] Attempted to read from EMPTY FIFO!", $time);
        end else begin
            rinc <= 1'b1;
            expected_data = expected_queue[q_rd_ptr];
            q_rd_ptr = q_rd_ptr + 1;
            
            // Wait for memory read data to be valid
            #1; // small delta for combinational read
            if (rdata !== expected_data) begin
                $display("[ERROR @ %0t ns] Data mismatch! Read: 0x%02h, Expected: 0x%02h", 
                         $time, rdata, expected_data);
                err_count = err_count + 1;
            end else begin
                $display("[PASS  @ %0t ns] Read Match: 0x%02h", $time, rdata);
            end

            @(posedge rclk);
            rinc <= 1'b0;
        end
    end
    endtask

    // -------------------------------------------------------------------------
    // Main Stimulus Procedure
    // -------------------------------------------------------------------------
    initial begin
        // Waveform Dump for GTKWave
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);

        // Initialize signals
        wclk   = 0;
        rclk   = 0;
        wrst_n = 0;
        rrst_n = 0;
        winc   = 0;
        rinc   = 0;
        wdata  = 8'h00;

        $display("============================================================");
        $display("       STARTING ASYNCHRONOUS FIFO VERIFICATION TEST         ");
        $display("   Write Clock: 100 MHz  |  Read Clock: 40 MHz              ");
        $display("============================================================");

        // Reset Pulse
        #40;
        wrst_n = 1;
        rrst_n = 1;
        #20;

        // ---------------------------------------------------------------------
        // TEST 1: Check Initial Reset State
        // ---------------------------------------------------------------------
        $display("\n--- TEST 1: Checking Reset State ---");
        if (rempty !== 1'b1 || wfull !== 1'b0) begin
            $display("[ERROR] Reset state incorrect! rempty=%b, wfull=%b", rempty, wfull);
            err_count = err_count + 1;
        end else begin
            $display("[PASS] Reset state confirmed: FIFO is EMPTY and NOT FULL.");
        end

        // ---------------------------------------------------------------------
        // TEST 2: Burst Write until FULL (Depth = 16)
        // ---------------------------------------------------------------------
        $display("\n--- TEST 2: Burst Writing 16 items to fill FIFO ---");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wclk);
            winc  <= 1'b1;
            wdata <= 8'hA0 + i;
            expected_queue[q_wr_ptr] = 8'hA0 + i;
            q_wr_ptr = q_wr_ptr + 1;
        end
        @(posedge wclk);
        winc  <= 1'b0;
        wdata <= 8'hxx;

        // Allow CDC synchronizer pipeline stages to propagate
        repeat (4) @(posedge wclk);

        if (wfull !== 1'b1) begin
            $display("[ERROR @ %0t ns] Expected wfull = 1 after 16 writes, but wfull = %b", $time, wfull);
            err_count = err_count + 1;
        end else begin
            $display("[PASS  @ %0t ns] FIFO FULL correctly asserted!", $time);
        end

        // ---------------------------------------------------------------------
        // TEST 3: Overflow Protection (Attempt write to FULL FIFO)
        // ---------------------------------------------------------------------
        $display("\n--- TEST 3: Testing Overflow Protection ---");
        @(posedge wclk);
        winc  <= 1'b1;
        wdata <= 8'hFF; // Should not be written
        @(posedge wclk);
        winc  <= 1'b0;
        wdata <= 8'hxx;
        $display("[INFO] Overflow write attempt completed without breaking FIFO.");

        // ---------------------------------------------------------------------
        // TEST 4: Burst Read until EMPTY
        // ---------------------------------------------------------------------
        $display("\n--- TEST 4: Burst Reading all 16 items from FIFO ---");
        for (i = 0; i < DEPTH; i = i + 1) begin
            read_byte();
        end

        // Allow CDC synchronizer pipeline stages to propagate
        repeat (4) @(posedge rclk);

        if (rempty !== 1'b1) begin
            $display("[ERROR @ %0t ns] Expected rempty = 1 after draining, but rempty = %b", $time, rempty);
            err_count = err_count + 1;
        end else begin
            $display("[PASS  @ %0t ns] FIFO EMPTY correctly asserted after read!", $time);
        end

        // ---------------------------------------------------------------------
        // TEST 5: Underflow Protection (Attempt read from EMPTY FIFO)
        // ---------------------------------------------------------------------
        $display("\n--- TEST 5: Testing Underflow Protection ---");
        read_byte(); // Should display warning and not corrupt pointers

        // ---------------------------------------------------------------------
        // TEST 6: Continuous Concurrent Write and Read
        // ---------------------------------------------------------------------
        $display("\n--- TEST 6: Concurrent Random Push & Pop Test ---");
        for (i = 0; i < 20; i = i + 1) begin
            write_byte(8'h10 + i);
            if (i % 2 == 0) begin
                read_byte();
            end
        end

        // Drain remaining items
        while (q_rd_ptr < q_wr_ptr) begin
            read_byte();
        end

        repeat (5) @(posedge rclk);

        // ---------------------------------------------------------------------
        // FINAL SUMMARY
        // ---------------------------------------------------------------------
        $display("\n============================================================");
        if (err_count == 0) begin
            $display("   *** ALL ASYNC FIFO TESTS PASSED WITH ZERO ERRORS! ***    ");
            $display("   Waveform generated: async_fifo.vcd                       ");
        end else begin
            $display("   *** TEST COMPLETED WITH %0d ERROR(S) ***                 ", err_count);
        end
        $display("============================================================\n");

        #100;
        $finish;
    end

endmodule
