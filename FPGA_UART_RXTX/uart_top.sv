`ifndef UART_TOP_
`define UART_TOP_

module uart_top #(
  parameter unsigned CLOCK_FREQ = 50_000_000, // 系统时钟频率
  parameter unsigned BAUD_RATE = 115_200,     // 串口波特率
  parameter unsigned DATA_BITS = 8,           // 数据位数
  parameter string   PARITY = "NONE",         // 奇偶校验类型: "NONE", "ODD", "EVEN"
  parameter unsigned STOP_BITS = 1            // 停止位数，目前只支持1位
)(
  input  logic clk,            // 输入时钟信号
  input  logic rst_n,          // 异步复位信号 (低电平有效)
  input  logic rx_in,          // 串行输入数据
  output logic tx_out,         // 串行输出数据
  output logic [3:0] count    // 测试信号
);

// 信号声明
logic tx_en;
logic [7:0] tx_data;
logic rx_data_valid;
logic [7:0] rx_data;

// UART TX 模块实例
uart_tx #(
  .CLOCK_FREQ(CLOCK_FREQ),
  .BAUD_RATE(BAUD_RATE),
  .DATA_BITS(DATA_BITS),
  .PARITY(PARITY),
  .STOP_BITS(STOP_BITS)
) u_uart_tx (
  .clk(clk),
  .rst_n(rst_n),
  .tx_data_valid(tx_en),
  .tx_data(tx_data), // 使用处理后的数据
  .tx_out(tx_out)
);

// UART RX 模块实例
uart_rx #(
  .CLOCK_FREQ(CLOCK_FREQ),
  .BAUD_RATE(BAUD_RATE),
  .DATA_BITS(DATA_BITS),
  .PARITY(PARITY),
  .STOP_BITS(STOP_BITS)
) u_uart_rx (
  .clk(clk),
  .rst_n(rst_n),
  .rx_in(rx_in), // 使用顶层模块的输入
  .rx_data_valid(rx_data_valid),
  .rx_data(rx_data)
);

// 数据处理模块实例
data_processor #(
  .DATA_BITS(DATA_BITS)
) u_data_processor (
  .clk(clk),
  .rst_n(rst_n),
  .rx_data_valid(rx_data_valid),
  .rx_data(rx_data),
  .tx_en(tx_en),
  .data_out(tx_data)
);
// assign tx_en = rx_data_valid;
// assign tx_data = rx_data;

uart_counter u_uart_counter (
  .clk(clk),
  .rst_n(rst_n),
  .en(rx_data_valid),
  .count(count)
);

endmodule // uart_top

`endif // UART_TOP_