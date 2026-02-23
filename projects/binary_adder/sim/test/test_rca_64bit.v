// iverilog -g2012 -Wall -s test_rca_64bit -o projects/binary_adder/sim/build/output/iverilog/test_rca_64bit.vvp projects/binary_adder/rtl/*.v projects/binary_adder/sim/test/test_rca_64bit.v
// vvp projects/binary_adder/sim/build/output/iverilog/test_rca_64bit.vvp

`timescale 1ns / 1ps

module test_rca_64bit ();
  reg [63:0] t_a;
  reg [63:0] t_b;
  wire [63:0] t_sum;
  wire t_c_out;

  reg [63:0] a_vec, b_vec, sum_exp;
  reg c_out_exp;
  integer c_out_raw;

  integer fd, n, err_cnt, line_no;

  rca_64bit uut (
      .a(t_a),
      .b(t_b),
      .c_out(t_c_out),
      .sum(t_sum)
  );

  initial begin
    err_cnt = 0;
    line_no = 0;
    // 실행 위치는 프로젝트 루트인 ~/dev/20_digital-systems-lab$
    fd = $fopen("projects/binary_adder/sim/vector/golden_vectors.hex", "r");
    if (fd == 0) $fatal(1, "cannot open vector file");

    n = $fscanf(fd, "%h %h %h %h", a_vec, b_vec, sum_exp, c_out_raw);
    while (n == 4) begin
      if ((c_out_raw != 0) && (c_out_raw != 1))
        $fatal(1, "Invalid c_out value near line %0d: %0h", line_no + 1, c_out_raw);

      c_out_exp = c_out_raw[0];
      line_no = line_no + 1;
      t_a = a_vec;
      t_b = b_vec;
      #1;

      if ({t_c_out, t_sum} !== {c_out_exp, sum_exp}) begin
        $display("Mismatch line %0d: a=%h b=%h got=%b_%h exp=%b_%h", line_no, t_a, t_b, t_c_out,
                 t_sum, c_out_exp, sum_exp);
        err_cnt = err_cnt + 1;
      end
      n = $fscanf(fd, "%h %h %h %h", a_vec, b_vec, sum_exp, c_out_raw);
    end

    if ((n != -1) && !$feof(fd)) begin
      $fatal(1, "Invalid vector format near line %0d", line_no + 1);
    end

    if (line_no == 0) $fatal(1, "No valid lines in vector file");

    $display("Finished processing %0d lines", line_no);

    $fclose(fd);

    if (err_cnt == 0) $display("PASS");
    else $fatal(1, "FAIL: err_cnt=%0d", err_cnt);

    $finish;
  end
endmodule
