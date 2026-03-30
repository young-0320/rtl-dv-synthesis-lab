`timescale 1ns / 1ps

module test_debouncer;

  parameter integer COUNT_MAX = 4;

  reg clk;
  reg reset;
  reg btn_in;
  wire btn_level;
  wire btn_pulse;

  integer cycle_count;
  integer pulse_count;
  integer error_count;
  reg [8*28-1:0] note;

  debouncer #(
      .COUNT_MAX(COUNT_MAX)
  ) uut (
      .clk(clk),
      .reset(reset),
      .btn_in(btn_in),
      .btn_level(btn_level),
      .btn_pulse(btn_pulse)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always @(posedge clk) begin
    #1;
    cycle_count = cycle_count + 1;
    if (btn_pulse) pulse_count = pulse_count + 1;
    $display("%4d |   %b    |   %b   |   %b   |     %0d      | %s", cycle_count, btn_in, btn_level,
             btn_pulse, pulse_count, note);
  end

  task automatic expect_state;
    input exp_level;
    input integer exp_pulse_count;
    input [8*28-1:0] label;
    begin
      if ((btn_level !== exp_level) || (pulse_count !== exp_pulse_count)) begin
        error_count = error_count + 1;
        $display("ERROR: %0s expected level=%0b pulse_count=%0d got level=%0b pulse_count=%0d",
                 label, exp_level, exp_pulse_count, btn_level, pulse_count);
      end
    end
  endtask

  initial begin
    $dumpfile("sim/output/test_debouncer.vcd");
    $dumpvars(0, test_debouncer);
  end

  initial begin
    cycle_count = 0;
    pulse_count = 0;
    error_count = 0;
    reset = 1'b1;
    btn_in = 1'b0;
    note = "reset";

    $display("======================================================================");
    $display("Step | BTN_IN | LEVEL | PULSE | Pulse Count | Note");
    $display("======================================================================");

    repeat (2) @(posedge clk);
    #1;
    expect_state(1'b0, 0, "reset_state");

    reset = 1'b0;
    note  = "idle";
    repeat (2) @(posedge clk);
    #1;
    expect_state(1'b0, 0, "idle_state");

    note   = "press bounce";
    btn_in = 1'b1;
    @(posedge clk);
    btn_in = 1'b0;
    @(posedge clk);
    btn_in = 1'b1;
    @(posedge clk);
    btn_in = 1'b0;
    @(posedge clk);
    #1;
    expect_state(1'b0, 0, "bounce_ignored");

    note   = "stable high";
    btn_in = 1'b1;
    repeat (8) @(posedge clk);
    #1;
    expect_state(1'b1, 1, "stable_press_detected");

    note = "held high";
    repeat (4) @(posedge clk);
    #1;
    expect_state(1'b1, 1, "no_repeat_pulse");

    note   = "release bounce";
    btn_in = 1'b0;
    @(posedge clk);
    btn_in = 1'b1;
    @(posedge clk);
    btn_in = 1'b0;
    @(posedge clk);
    btn_in = 1'b1;
    @(posedge clk);
    btn_in = 1'b0;
    repeat (8) @(posedge clk);
    #1;
    expect_state(1'b0, 1, "release_without_pulse");

    note   = "second press";
    btn_in = 1'b1;
    repeat (8) @(posedge clk);
    #1;
    expect_state(1'b1, 2, "second_press_detected");

    $display("----------------------------------------------------------------------");
    if (error_count == 0) $display("Verification Task Completed Successfully.");
    else $display("Verification failed: %0d mismatches found.", error_count);
    $display("TEST_RESULT: %s", (error_count == 0) ? "PASS" : "FAIL");
    $finish;
  end

endmodule
