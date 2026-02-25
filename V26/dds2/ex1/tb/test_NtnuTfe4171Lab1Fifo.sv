//====================================================================
//        Copyright (c) 2025 
// Created : omqa at 2025-12-01
//====================================================================

module test_NtnuTfe4171Lab1Fifo;

    // Parameters
    localparam WIDTH = 8;
    localparam DEPTH = 32;

    // DUT signals
    logic clk;
    logic arst;  // Active-high async reset
    logic wr_en;
    logic rd_en;
    logic flush;
    logic [WIDTH-1:0] wr_data;
    logic [WIDTH-1:0] rd_data;
    logic full;
    logic empty;

    bit   resetComplete;

    // ------------------------------
    // -- DUT and assignments
    // ------------------------------

    // Instantiate DUT
    NtnuTfe4171Lab1Fifo #(
         .WIDTH (WIDTH)
        ,.DEPTH (DEPTH)
    ) u_NtnuTfe4171Lab1Fifo (
         .clk     (clk)
        ,.arst    (arst)
        ,.wr_en   (wr_en)
        ,.wr_data (wr_data)
        ,.rd_en   (rd_en)
        ,.flush   (flush)
        ,.rd_data (rd_data)
        ,.full    (full)
        ,.empty   (empty)
    );

    // -----------------------------
    // Simple scoreboard using an array FIFO (queue behavior)
    // -----------------------------
    integer expectedWriteIndex = 0;
    integer expectedReadIndex = 0;
    logic [WIDTH-1:0] expectedDataQueue [$];  // ample size for test
    integer errors = 0;

    // -------------------------------------------------------------------------
    // Push expected data (on successful write)
    // -------------------------------------------------------------------------
    task scoreBoardQueuePush(input [WIDTH-1:0] data);
      begin
        expectedDataQueue[expectedWriteIndex] = data;
        expectedWriteIndex = expectedWriteIndex + 1;
      end
    endtask

    // -------------------------------------------------------------------------
    // Pop and compare expected vs actual (on successful read)
    // -------------------------------------------------------------------------
    task scoreBoardPopAndCheck(input [WIDTH-1:0] actual);
      logic [WIDTH-1:0] expected;
      begin
        if (expectedReadIndex >= expectedWriteIndex) begin
          $display("[%0t] ERROR: Read with empty scoreboard!", $time);
          errors = errors + 1;
          $error;
        end
        expected = expectedDataQueue[expectedReadIndex];
        if (actual !== expected) begin
          $display("[%0t] MISMATCH: expected=0x%0h actual=0x%0h (index %0d)",
                    $time, expected, actual, expectedReadIndex);
          errors = errors + 1;
          $error;
        end
        expectedReadIndex = expectedReadIndex + 1;
      end
    endtask

    // -------------------------------------------------------------------------
    // Clear scoreboard indices (used on flush)
    // -------------------------------------------------------------------------
    task scoreBoardReset;
      begin
        expectedWriteIndex = 0;
        expectedReadIndex = 0;
      end
    endtask

    // -----------------------------
    // Helper tasks for write/read
    // -----------------------------

    // -------------------------------------------------------------------------
    task writeWordIntoFifo(input [WIDTH-1:0] data);
      begin
        @(posedge clk);
        if (!full) begin
          wr_en   <= 1'b1;
          wr_data <= data;
          scoreBoardQueuePush(data);           // track expected data when write is accepted
        end else begin
          wr_en   <= 1'b0;
          wr_data <= '0;
        end
        @(posedge clk);
        wr_en   <= 1'b0;
        wr_data <= '0;
      end
    endtask

    // -------------------------------------------------------------------------

    task readWordFromFifo;
      begin
        @(posedge clk);
        if (!empty) begin
          rd_en <= 1'b1;
        end else begin
          rd_en <= 1'b0;
        end
        @(posedge clk);
        if (rd_en && !empty) begin
          scoreBoardPopAndCheck(rd_data);
        end
        rd_en <= 1'b0;
      end
    endtask

    // -------------------------------------------------------------------------
    // Burst write N bytes (handles full)
    // -------------------------------------------------------------------------

    task writeBurstData(input integer n, input integer seed);
      integer i;
      logic [WIDTH-1:0] data;
      begin
        for (i = 0; i < n; i = i + 1) begin
          data = (seed + i) & {WIDTH{1'b1}};  // deterministic pattern
          writeWordIntoFifo(data);
        end
      end
    endtask

    // -------------------------------------------------------------------------
    // Burst read N bytes (handles empty)
    // -------------------------------------------------------------------------

    task readBurstData(input integer n);
      integer i;
      begin
        for (i = 0; i < n; i = i + 1) begin
          readWordFromFifo();
        end
        @(posedge clk);
      end
    endtask

    // -------------------------------------------------------------------------
    // Assert and deassert asynchronous reset
    // -------------------------------------------------------------------------

    task doReset;
      begin
        arst <= 1'b1;
        wr_en <= 1'b0;
        rd_en <= 1'b0;
        flush <= 1'b0;
        wr_data <= '0;
        scoreBoardReset();
        repeat (3) @(posedge clk);
        arst <= 1'b0;
        repeat (2) @(posedge clk);
        // Sanity: FIFO should be empty and not full
        if (!empty) begin
          $display("[%0t] ERROR: empty should be 1 after reset", $time);
          errors = errors + 1;
          $fatal(1);
        end
        if (full) begin
          $display("[%0t] ERROR: full should be 0 after reset", $time);
          errors = errors + 1;
          $fatal(1);
        end
      end
    endtask

    // -------------------------------------------------------------------------
    // Perform a flush and validate FIFO empty and scoreboard reset
    // -------------------------------------------------------------------------

    task flushFifo;
      begin
        @(posedge clk);
        flush <= 1'b1;
        @(posedge clk);
        flush <= 1'b0;
        // Reset scoreboard because logical contents are discarded
        scoreBoardReset();
        @(posedge clk);
        if (!empty) begin
          $display("[%0t] ERROR: empty should be 1 after flush", $time);
          errors = errors + 1;
          $fatal(1);
        end
        if (full) begin
          $display("[%0t] ERROR: full should be 0 after flush", $time);
          errors = errors + 1;
          $fatal(1);
        end
      end
    endtask

    // ------------------------------
    // -- Test program
    // ------------------------------

    // Clock generation: 16 MHz
    realtime clock_period= (1s/16e6);
    initial begin
      clk = 0;
      forever #(clock_period/2.0) clk = !clk;
    end

    // -----------------------------
    // Main stimulus
    // -----------------------------
    // Initialize
    initial begin
      arst = 0;
      wr_en = 0;
      rd_en = 0;
      flush = 0;
      wr_data = 0;
      resetComplete = 0;

      // Apply reset
      #10;
      doReset;
      resetComplete = 1;
    end

    initial begin
      wait (resetComplete);
      #10;

      // 1) Write a partial packet (e.g., 16 bytes) then read them back
      writeBurstData(16, 8'h10);
      readBurstData(16);
      if (!empty) begin
        $display("[%0t] ERROR: (1) FIFO should be empty after equal write/read", $time);
        errors = errors + 1;
        $error;
      end
      else
        $display("[%0t] SUCCESS: (1) FIFO data pushed and emptied after equal write/read\n", $time);

      // 2) Write near-full, then flush, ensure empty and no further reads occur
      writeBurstData(DEPTH - 2, 8'h20);
      if (empty) begin
        $display("[%0t] ERROR: (2) FIFO should not be empty after writes", $time);
        errors = errors + 1;
        $error;
      end
      else
        $display("[%0t] SUCCESS: (2) FIFO data pushed and empty de-asserted\n", $time);
      flushFifo();     // logical empty; memory not cleared, as per spec

      // Attempt to read after flush�should not return anything, scoreboard is reset
      readBurstData(4);

      // 3) Fill to full, then read all back and compare
      writeBurstData(DEPTH, 8'h40);
      // It may take a cycle for full to assert depending on implementation; allow a cycle
      @(posedge clk);
      if (!full) begin
        $display("[%0t] WARNING: (3a) full is not asserted after DEPTH writes (check pointer/flag logic)", $time);
      end
      else
        $display("[%0t] SUCCESS: (3a) FIFO filled and full asserted\n", $time);
      readBurstData(DEPTH);
      if (!empty) begin
        $display("[%0t] ERROR: (3b) FIFO should be empty after draining", $time);
        errors = errors + 1;
        $error;
      end
      else
        $display("[%0t] SUCCESS: (3b) FIFO emptied after filling and empty asserted\n", $time);

      // 4) Interleaved read/write (same-cycle ops) to exercise FIFO data integrity
      //    Write 12 bytes while reading in parallel after some delay
      fork
        begin : writerThread
          writeBurstData(27, 8'h80);
        end
        begin : readerThread
          // small delay before starting reads to allow some fill
          repeat (5) @(posedge clk);
          readBurstData(27);
        end
      join

      if (!empty) begin
        $display("[%0t] ERROR: (4) FIFO should be empty after draining", $time);
        errors = errors + 1;
        $error;
      end
      else
        $display("[%0t] SUCCESS: (4) FIFO emptied and empty asserted\n", $time);

      // Final checks
      if (errors == 0) begin
        $display("[%0t] TEST PASSED: All data matched and flags behaved correctly.", $time);
      end else begin
        $display("[%0t] TEST FAILED: %0d errors detected.", $time, errors);
      end

      // Finish
      #50;
      $finish;
    end

    // Optional live monitor
    initial begin
      $display("   time     | wrEn   wrData | rdEn  rdData | full empty flush");
      forever begin
        @(posedge clk);
        $display("%9t |   %b    0x%03h  |   %b   0x%03h  |   %b     %b     %b",
                 $time, wr_en, wr_data, rd_en, rd_data, full, empty, flush);
      end
    end

endmodule

