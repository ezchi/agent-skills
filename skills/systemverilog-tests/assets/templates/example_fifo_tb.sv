module fifo_tb;

  localparam int LP_WIDTH          = 32;
  localparam int LP_DEPTH          = 16;
  localparam int LP_NUM_STRESS_TXNS = 10_000;
  localparam int LP_MAX_GAP        = 8;
  localparam int LP_DATA_MASK      = (1 << LP_WIDTH) - 1;

  logic                  clk;
  logic                  rst;
  logic                  push;
  logic                  pop;
  logic [LP_WIDTH-1:0]   data_in;
  logic [LP_WIDTH-1:0]   data_out;
  logic                  full;
  logic                  empty;

  fifo #(
    .WIDTH (LP_WIDTH),
    .DEPTH (LP_DEPTH)
  ) dut (.*);

  // Clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Watchdog
  initial begin
    #100ms;
    $error("FIFO Simulation Timeout!");
    $finish;
  end

  // Random seed — accept +seed=<N> for reproducibility
  int unsigned seed;
  initial begin
    if (!$value$plusargs("seed=%d", seed)) seed = $urandom;
    $display("Random seed: %0d  (reproduce with +seed=%0d)", seed, seed);
  end

  task automatic delay_cc(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask : delay_cc

  // Reset
  task automatic reset_dut();
    rst  <= 1;
    push <= 0;
    pop  <= 0;
    data_in <= $urandom;  // random data even during reset
    delay_cc(5);
    rst <= 0;
    delay_cc(1);
  endtask

  // Drive a single push transaction — random garbage on data when push is low
  task automatic push_one(input logic [LP_WIDTH-1:0] data);
    push    <= 1;
    data_in <= data;
    delay_cc(1);
    push    <= 0;
    data_in <= $urandom;  // random data when push is deasserted
  endtask

  // ──────────────────────────────────────────────
  // Directed test: back-to-back push then pop
  // ──────────────────────────────────────────────
  task automatic test_back_to_back();
    automatic logic [LP_WIDTH-1:0] expected_q[$];

    $display("[test_back_to_back] START");
    reset_dut();

    // Back-to-back pushes — no idle cycles
    for (int i = 0; i < LP_DEPTH; i++) begin
      automatic logic [LP_WIDTH-1:0] d = $urandom;
      expected_q.push_back(d);
      push    <= 1;
      data_in <= d;
      delay_cc(1);
    end
    push    <= 0;
    data_in <= $urandom;  // random when invalid

    // Back-to-back pops — no idle cycles
    for (int i = 0; i < LP_DEPTH; i++) begin
      pop <= 1;
      delay_cc(1);
      assert (data_out == expected_q[i])
        else $error("[test_back_to_back] Mismatch at %0d: got %0h, expected %0h",
                     i, data_out, expected_q[i]);
    end
    pop <= 0;

    $display("[test_back_to_back] DONE");
  endtask

  // ──────────────────────────────────────────────
  // Random test: random gaps between transactions
  // ──────────────────────────────────────────────
  task automatic test_random_gaps();
    automatic logic [LP_WIDTH-1:0] expected_q[$];
    automatic int num_txns = 32;

    $display("[test_random_gaps] START");
    reset_dut();

    for (int i = 0; i < num_txns; i++) begin
      automatic logic [LP_WIDTH-1:0] d = $urandom;
      expected_q.push_back(d);
      push_one(d);
      // Random idle gap — data stays random while push is low
      repeat ($urandom_range(0, LP_MAX_GAP)) begin
        data_in <= $urandom;
        delay_cc(1);
      end
    end

    for (int i = 0; i < num_txns; i++) begin
      pop <= 1;
      delay_cc(1);
      assert (data_out == expected_q[i])
        else $error("[test_random_gaps] Mismatch at %0d: got %0h, expected %0h",
                     i, data_out, expected_q[i]);
      pop <= 0;
      // Random gap between pops too
      repeat ($urandom_range(0, LP_MAX_GAP)) delay_cc(1);
    end

    $display("[test_random_gaps] DONE");
  endtask

  // ──────────────────────────────────────────────
  // Stress test: sustained random push/pop traffic
  // ──────────────────────────────────────────────
  task automatic test_stress();
    automatic logic [LP_WIDTH-1:0] scoreboard_q[$];
    automatic int push_count = 0;
    automatic int pop_count  = 0;
    automatic int errors     = 0;

    $display("[test_stress] START — %0d transactions", LP_NUM_STRESS_TXNS);
    reset_dut();

    while (push_count < LP_NUM_STRESS_TXNS || pop_count < LP_NUM_STRESS_TXNS) begin
      automatic bit do_push = (push_count < LP_NUM_STRESS_TXNS) && !full
                              && ($urandom_range(0, 1) == 1);
      automatic bit do_pop  = (pop_count < push_count) && !empty
                              && ($urandom_range(0, 1) == 1);

      if (do_push) begin
        automatic logic [LP_WIDTH-1:0] d = $urandom;
        scoreboard_q.push_back(d);
        push    <= 1;
        data_in <= d;
        push_count++;
      end else begin
        push    <= 0;
        data_in <= $urandom;  // random garbage when not pushing
      end

      if (do_pop) begin
        pop <= 1;
        // Check on next cycle after pop is registered
      end else begin
        pop <= 0;
      end

      delay_cc(1);

      if (do_pop && scoreboard_q.size() > 0) begin
        automatic logic [LP_WIDTH-1:0] expected = scoreboard_q.pop_front();
        if (data_out !== expected) begin
          $error("[test_stress] Pop %0d: got %0h, expected %0h", pop_count, data_out, expected);
          errors++;
        end
        pop_count++;
      end
    end

    push <= 0;
    pop  <= 0;
    data_in <= $urandom;

    if (errors == 0)
      $display("[test_stress] PASS — %0d transactions verified", LP_NUM_STRESS_TXNS);
    else
      $display("[test_stress] FAIL — %0d errors in %0d transactions", errors, LP_NUM_STRESS_TXNS);
  endtask

  // ──────────────────────────────────────────────
  // Test sequencer
  // ──────────────────────────────────────────────
  initial begin
    test_back_to_back();
    test_random_gaps();
    test_stress();

    delay_cc(2);
    $finish;
  end

endmodule
