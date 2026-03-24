`timescale 1ns / 1ps

module adder_subtractor_3bit_tb;

    // 1. 파라미터 및 신호 선언
    parameter N = 3;
    reg  [N-1:0] a, b;
    reg          mode;
    wire         c_out;
    wire [N:0]   sum;

    // 2. UUT (Unit Under Test) 인스턴스화
    adder_subtractor_3bit #(.N(N)) uut (
        .a(a), .b(b), .mode(mode),
        .c_out(c_out), .sum(sum)
    );

    // 3. GTKWave용 VCD 파일 생성
    initial begin
        $dumpfile("adder_subtractor_3bit_tb.vcd");
        $dumpvars(0, adder_subtractor_3bit_tb);
    end

    // 4. 통합 검증 루프 (전수조사 + 코너 케이스)
    integer m, i, j;
    initial begin
        $display("=====================================================================");
        $display(" Time | Mode |  A  |  B  | Result(Bin) | Cout | Result(Dec) | Note");
        $display("=====================================================================");

        for (m = 0; m < 2; m = m + 1) begin
            mode = m;
            $display("--- Mode: %s ---", (mode ? "SUBTRACT (-)" : "ADD (+)"));
            
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    a = i; b = j;
                    #10; // 신호 전파 대기

                    // 코너 케이스 및 주요 지점 레이블링
                    string note = "";
                    if (mode == 0 && a == 7 && b == 7) note = "<< MAX ADD (Corner)";
                    else if (mode == 1 && a == 0 && b == 7) note = "<< MIN SUB (Corner)";
                    else if (mode == 1 && a == 7 && b == 0) note = "<< MAX SUB (Corner)";
                    else if (a == 0 && b == 0) note = "<< ZERO CASE";

                    // 안정된 상태의 값을 출력 ($strobe 사용)
                    $strobe("%4t |  %b   | %d | %d |    %b     |  %b   |    %d      | %s", 
                            $time, mode, a, b, sum, c_out, (mode ? $signed(sum) : sum), note);
                end
            end
            $display("---------------------------------------------------------------------");
        end

        $display("Verification Task Completed Successfully.");
        $finish;
    end

endmodule