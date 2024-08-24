`timescale 1ns / 1ps

module uart_top_tb;

  // 参数定义
  parameter CLOCK_FREQ = 50_000_000; // 系统时钟频率
  parameter BAUD_RATE = 115_200;     // 串口波特率
  parameter DATA_BITS = 8;           // 数据位数
  parameter PARITY = "NONE";         // 奇偶校验类型: "NONE", "ODD", "EVEN"
  parameter STOP_BITS = 1;           // 停止位数

  // 计算每个比特位的时间
  real bit_time;
  initial bit_time = 1_000_000_000 / BAUD_RATE;

  // 时钟信号
  logic clk;
  always #10 clk = ~clk; // 50MHz 时钟

  // 复位信号
  logic rst_n;

  // UART 信号
  logic tx_out;
  logic rx_in;
  logic [3:0] count;

  // 实例化 UART 顶层模块
  uart_top #(
    .CLOCK_FREQ(CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .DATA_BITS(DATA_BITS),
    .PARITY(PARITY),
    .STOP_BITS(STOP_BITS)
  ) u_uart_top (
    .clk(clk),
    .rst_n(rst_n),
    .tx_out(tx_out),
    .rx_in(rx_in),
    .count(count)
  );

  // 初始条件
  initial begin
    $dumpfile("uart_top_wave.vcd");
    $dumpvars(2, uart_top_tb);
    clk = 1'b0;
    rx_in = 1'b1;
    rst_n = 0; // 复位
    #100; // 等待一段时间
    rst_n = 1; // 释放复位
    #100;
    // 测试序列
    test_sequence();
  end

  // 测试序列
  task test_sequence;
    begin
      // 初始化接收信号
      rx_in = 1'b1; // 空闲状态为高电平

      // 发送数据
      send_data(8'h5A); // 发送十六进制 5A (90)
      #1000; // 等待一段时间

      // 接收数据
      receive_data();

      // 结束测试
      $finish;
    end
  endtask

  // 发送数据
  task send_data(input logic [7:0] data);
    begin
      // 发送起始位
      rx_in = 1'b0;
      #bit_time; // 等待一个比特位的时间

      // 发送数据位
      for (int i = 0; i < DATA_BITS; i++) begin
        if (data[DATA_BITS-i-1]) begin
          rx_in = 1'b1;
        end else begin
          rx_in = 1'b0;
        end
        #bit_time; // 等待一个比特位的时间
      end

      // 发送奇偶校验位
      if (PARITY != "NONE") begin
        int parity_bit;
        parity_bit = calculate_parity(data);
        if (parity_bit) begin
          rx_in = 1'b1;
        end else begin
          rx_in = 1'b0;
        end
        #bit_time; // 等待一个比特位的时间
      end

      // 发送停止位
      rx_in = 1'b1;
      #(bit_time * STOP_BITS); // 等待停止位的时间
    end
  endtask

  // 计算奇偶校验位
  function int calculate_parity(input logic [7:0] data);
    int parity;
    parity = 0;
    for (int i = 0; i < DATA_BITS; i++) begin
      if (data[i]) begin
        parity++;
      end
    end
    if (PARITY == "ODD") begin
      return (parity % 2) == 0 ? 1 : 0;
    end else if (PARITY == "EVEN") begin
      return (parity % 2) == 0 ? 0 : 1;
    end
    return 0;
  endfunction

  // 接收数据
  task receive_data;
    begin
      // 模拟接收数据
      // 这里可以添加代码来模拟接收数据的过程
      // 由于这是一个示例，我们简单地等待一段时间来模拟数据接收
      #(bit_time * (STOP_BITS+DATA_BITS+10));
      #1000; // 模拟数据接收过程
      // 在这里可以添加代码来检查接收到的数据是否正确
    end
  endtask

endmodule