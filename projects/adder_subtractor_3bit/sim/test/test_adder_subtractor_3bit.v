`timescale 1ns / 1ps

module test_adder_subtractor_3bit;

  // 1. 파라미터 및 신호 선언
  parameter integer N = 3;
  reg [N-1:0] a, b;
  reg        mode;
  wire       c_out;
  wire [N:0] sum;

  // 2. UUT (Unit Under Test) 인스턴스화
  adder_subtractor_3bit #(
      .N(N)
  ) uut (
      .a(a),
      .b(b),
      .mode(mode),
      .c_out(c_out),
      .sum(sum)
  );

  // 3. GTKWave용 VCD 파일 생성
  initial begin
    $dumpfile("test_adder_subtractor_3bit.vcd");
    $dumpvars(0, test_adder_subtractor_3bit);
  end

  // 4. 통합 검증 루프 (전수조사 + 코너 케이스)
  integer m, i, j;
  integer result_dec;
  integer expected_dec;
  integer error_count;
  reg [N:0] expected_sum;
  reg expected_c_out;
  reg [8*24-1:0] note;
  initial begin
    error_count = 0;
    $display("=====================================================================");
    $display(" Time | Mode |  A  |  B  | Result(Bin) | C/B  | Result(Dec) | Note");
    $display("=====================================================================");
    $display(" C/B : Carry for ADD, Borrow for SUB");

    for (m = 0; m < 2; m = m + 1) begin
      mode = m;
      $display("--- Mode: %s ---", (mode ? "SUBTRACT (-)" : "ADD (+)"));
      for (i = 0; i < 8; i = i + 1) begin
        for (j = 0; j < 8; j = j + 1) begin
          a = i;
          b = j;
          #10;  // 신호 전파 대기

          // 코너 케이스 및 주요 지점 레이블링
          note = "";
          if (mode == 0 && a == 7 && b == 7) note = "<< MAX ADD (Corner)";
          else if (mode == 1 && a == 0 && b == 7) note = "<< MIN SUB (Corner)";
          else if (mode == 1 && a == 7 && b == 0) note = "<< MAX SUB (Corner)";
          else if (a == 0 && b == 0) note = "<< ZERO CASE";

          if (mode == 0) begin
            expected_sum = i + j;
            expected_c_out = expected_sum[N];
            expected_dec = expected_sum;
          end else begin
            expected_sum = i - j;
            expected_c_out = (i < j);
            expected_dec = i - j;
          end

          if (mode == 0) begin
            result_dec = sum;
          end else if (sum[N]) begin
            result_dec = sum - (1 << (N + 1));
          end else begin
            result_dec = sum;
          end

          $display("%4t |  %b   | %d | %d |    %b     |  %b   |    %d      | %s", $time, mode, a,
                   b, sum, c_out, result_dec, note);

          if ((sum !== expected_sum) || (c_out !== expected_c_out) ||
              (result_dec !== expected_dec)) begin
            error_count = error_count + 1;
            $display("ERROR: expected sum=%b, c_out=%b, dec=%0d", expected_sum, expected_c_out,
                     expected_dec);
          end
        end
      end
      $display("---------------------------------------------------------------------");
    end

    if (error_count == 0) $display("Verification Task Completed Successfully.");
    else $display("Verification failed: %0d mismatches found.", error_count);
    $finish;
  end

endmodule
