module ParToSer_ctrl (
    input  [7:0] X,
    input        clk,             // 메인 클럭 (125MHz)
    input        reset,
    input        save,
    input        start,
    output       serial_out,
    output [2:0] stored_cnt_led,
    output       ready_led,
    output       error_led
);

  localparam integer DEBOUNCE_COUNT_MAX = 70_000;
  localparam integer STORED_TARGET = 5;

  // FSM 상태 정의 
  localparam [2:0] S_STORE = 3'd0;
  localparam [2:0] S_WRITE = 3'd1;
  localparam [2:0] S_WAIT_START = 3'd2;
  localparam [2:0] S_READ_ADDR = 3'd3;
  localparam [2:0] S_READ_WAIT = 3'd4;
  localparam [2:0] S_LOAD = 3'd5;
  localparam [2:0] S_SHIFT = 3'd6;
  localparam [2:0] S_DONE = 3'd7;

  reg  [ 2:0] state;
  reg  [ 2:0] write_count;
  reg  [ 2:0] read_count;
  reg  [ 2:0] shift_count;
  reg  [ 2:0] bram_addr;
  reg  [ 7:0] bram_din;
  reg         error_latched;
  reg  [ 7:0] x0;
  reg  [ 7:0] x1;
  reg  [ 7:0] x2;
  reg  [ 7:0] x3;
  reg  [ 7:0] x4;

  wire [ 7:0] serializer_q;
  wire [ 7:0] bram_dout;
  wire [39:0] ila_data;
  wire [ 0:0] bram_wea;
  wire        clk_7M;
  wire        pll_locked;
  wire        safe_reset;
  wire        save_pulse;
  wire        start_pulse;
  wire        serializer_ld;
  wire        serializer_shift_en;

  assign safe_reset          = reset | ~pll_locked;
  assign stored_cnt_led      = write_count;
  assign ready_led           = (state == S_WAIT_START);
  assign error_led           = error_latched;
  assign ila_data            = {x4, x3, x2, x1, x0};
  assign bram_wea            = (state == S_WRITE) ? 1'b1 : 1'b0;
  assign serializer_ld       = (state == S_LOAD);
  assign serializer_shift_en = (state == S_SHIFT);

  debouncer #(
      .COUNT_MAX(DEBOUNCE_COUNT_MAX)
  ) i_save_debouncer (
      .clk      (clk_7M),
      .reset    (safe_reset),
      .btn_in   (save),
      .btn_level(),
      .btn_pulse(save_pulse)
  );

  debouncer #(
      .COUNT_MAX(DEBOUNCE_COUNT_MAX)
  ) i_start_debouncer (
      .clk      (clk_7M),
      .reset    (safe_reset),
      .btn_in   (start),
      .btn_level(),
      .btn_pulse(start_pulse)
  );

  ParToSer i_serializer (
      .X         (bram_dout),
      .clk       (clk_7M),
      .reset     (safe_reset),
      .ld        (serializer_ld),
      .shift_en  (serializer_shift_en),
      .serial_out(serial_out),
      .Q         (serializer_q)
  );

  blk_mem_gen_0 i_bram (
      .clka (clk_7M),
      .wea  (bram_wea),
      .addra(bram_addr),
      .dina (bram_din),
      .douta(bram_dout)
  );

  ila_0 i_ila (
      .clk   (clk_7M),
      .probe0(ila_data),
      .probe1(serial_out)
  );

  clk_wiz_0 i_clk_wiz (
      .reset   (reset),
      .clk_in1 (clk),
      .clk_out1(clk_7M),
      .locked  (pll_locked)
  );
  // FSM 구현
  // 리셋 -> 저장 대기 -> BRAM 쓰기 -> start 대기 -> BRAM 읽기 -> serializer load -> shift -> 완료

  always @(posedge clk_7M or posedge safe_reset) begin
    if (safe_reset) begin
      state         <= S_STORE;
      write_count   <= 3'd0;
      read_count    <= 3'd0;
      shift_count   <= 3'd0;
      bram_addr     <= 3'd0;
      bram_din      <= 8'd0;
      error_latched <= 1'b0;
      x0            <= 8'd0;
      x1            <= 8'd0;
      x2            <= 8'd0;
      x3            <= 8'd0;
      x4            <= 8'd0;
    end else begin
      case (state)
        S_STORE: begin
          bram_addr <= write_count;
          if (save_pulse) begin
            if (write_count < STORED_TARGET) begin
              bram_addr <= write_count;
              bram_din  <= X;
              state     <= S_WRITE;
            end else begin
              error_latched <= 1'b1;
            end
          end
          if (start_pulse) begin
            error_latched <= 1'b1;
          end
        end

        S_WRITE: begin
          case (write_count)
            3'd0: x0 <= bram_din;
            3'd1: x1 <= bram_din;
            3'd2: x2 <= bram_din;
            3'd3: x3 <= bram_din;
            3'd4: x4 <= bram_din;
            default: begin
            end
          endcase

          if (write_count == STORED_TARGET - 1) begin
            write_count <= STORED_TARGET[2:0];
            state       <= S_WAIT_START;
          end else begin
            write_count <= write_count + 1'b1;
            state       <= S_STORE;
          end
        end

        S_WAIT_START: begin
          if (save_pulse) begin
            error_latched <= 1'b1;
          end
          if (start_pulse) begin
            read_count <= 3'd0;
            bram_addr  <= 3'd0;
            state      <= S_READ_ADDR;
          end
        end

        S_READ_ADDR: begin
          bram_addr <= read_count;
          state     <= S_READ_WAIT;
        end

        S_READ_WAIT: begin
          state <= S_LOAD;
        end

        S_LOAD: begin
          shift_count <= 3'd7;
          state       <= S_SHIFT;
        end

        S_SHIFT: begin
          if (shift_count == 3'd1) begin
            if (read_count == STORED_TARGET - 1) begin
              state <= S_DONE;
            end else begin
              read_count <= read_count + 1'b1;
              state      <= S_READ_ADDR;
            end
          end
          shift_count <= shift_count - 1'b1;
        end

        S_DONE: begin
          state         <= S_STORE;
          write_count   <= 3'd0;
          read_count    <= 3'd0;
          shift_count   <= 3'd0;
          bram_addr     <= 3'd0;
          bram_din      <= 8'd0;
          error_latched <= 1'b0;
          x0            <= 8'd0;
          x1            <= 8'd0;
          x2            <= 8'd0;
          x3            <= 8'd0;
          x4            <= 8'd0;
        end

        default: begin
          state         <= S_STORE;
          write_count   <= 3'd0;
          read_count    <= 3'd0;
          shift_count   <= 3'd0;
          bram_addr     <= 3'd0;
          bram_din      <= 8'd0;
          error_latched <= 1'b1;
          x0            <= 8'd0;
          x1            <= 8'd0;
          x2            <= 8'd0;
          x3            <= 8'd0;
          x4            <= 8'd0;
        end
      endcase
    end
  end

endmodule
