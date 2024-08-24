`ifndef UART_RX_
`define UART_RX_

module uart_rx #(
  parameter unsigned CLOCK_FREQ = 50_000_000, // 系统时钟频率
  parameter unsigned BAUD_RATE = 115_200,     // 串口波特率
  parameter unsigned DATA_BITS = 8,           // 数据位数
  parameter string   PARITY = "NONE",         // 奇偶校验类型: "NONE", "ODD", "EVEN"
  parameter unsigned STOP_BITS = 1            // 停止位数
)(
  input  logic                 clk,            // 输入时钟信号
  input  logic                 rst_n,          // 异步复位信号 (低电平有效)
  input  logic                 rx_in,          // 串行输入数据
  output logic                 rx_data_valid,  // 数据有效信号
  output logic                 rx_data_error,  // 数据错误信号
  output logic [DATA_BITS-1:0] rx_data         // 接收的数据
);

// 计算波特率计数器的最大值
localparam unsigned UART_COUNTER_MAX = CLOCK_FREQ / BAUD_RATE; //>2
// 计算波特率计数器所需的位宽
localparam unsigned UART_COUNTER_WIDTH = $clog2(UART_COUNTER_MAX+1);
localparam unsigned DATA_COUNTER_WIDTH = $clog2(DATA_BITS+1);

// 波特率计数器
logic [UART_COUNTER_WIDTH-1:0] baud_counter;
logic baud_counter_last;
logic baud_counter_half;

// 数据接收计数器
logic [DATA_COUNTER_WIDTH-1:0] bit_counter;
logic bit_counter_last;
// 数据寄存器
logic [DATA_BITS-1:0] data_reg;
// 奇偶校验位
logic parity_give;
logic parity_calc;
// 数据有效标志
logic data_valid;


typedef enum logic[2:0] { 
  StIdle  ,
  StStart ,
  StData  ,
  StParity,
  StStop
} fsm_rx_t;

fsm_rx_t rx_state;
fsm_rx_t rx_state_next;

always_ff @( posedge clk or negedge rst_n ) begin : BLK_BAUD_COUNTER_LAST
  if(!rst_n) baud_counter_last <= 1'b0;
  else if(baud_counter == UART_COUNTER_MAX-2) baud_counter_last <= 1'b1;
  else baud_counter_last <= 1'b0;
end

always_ff @( posedge clk or negedge rst_n ) begin : BLK_BAUD_COUNTER_HALF
  if(!rst_n) baud_counter_half <= 1'b0;
  else if(baud_counter == UART_COUNTER_MAX/2) baud_counter_half <= 1'b1;
  else baud_counter_half <= 1'b0;
  
end

// 生成波特率计数器
always_ff @(posedge clk or negedge rst_n) begin: BLK_BAUD_COUNTER
  if (!rst_n) baud_counter <= '0;
  else if (baud_counter_last || (rx_state == StIdle)) baud_counter <= '0;
  else baud_counter <= baud_counter + 1'b1;
end

always_comb begin : FSM_RX_COMB
  case(rx_state)
    StIdle  : rx_state_next = rx_in ? StIdle : StStart;
    StStart : rx_state_next = baud_counter_last ? StData : StStart;
    StData  : rx_state_next = (baud_counter_last & bit_counter_last)
                                ? (PARITY == "NONE")
                                  ? StStop
                                  : StParity
                                : StData;
    StParity: rx_state_next = baud_counter_last ? StStop : StParity;
    StStop  : rx_state_next = baud_counter_last ? StIdle : StStop;
    default : rx_state_next = StIdle;
  endcase
end

always_ff @( posedge clk or negedge rst_n ) begin : FSM_RX_FF
  if(!rst_n) rx_state <= StIdle;
  else rx_state <= rx_state_next;
end

// 读取输入数据
always_ff @(posedge clk or negedge rst_n) begin : BLK_DATA_REG
  if ((!rst_n) || (rx_state == StIdle)) begin
    data_reg <= '0;
    bit_counter <= '0;
  end
  else if((rx_state == StData) & baud_counter_half) begin
      data_reg <= {rx_in, data_reg[DATA_BITS-1:1]};
      bit_counter <= bit_counter + 1'b1;
  end
  else begin
      data_reg <= data_reg;
      bit_counter <= bit_counter;
  end
end

generate
  if (PARITY != "NONE") begin
    always_ff @(posedge clk or negedge rst_n) begin : BLK_PARITY_GIVE
      if ((!rst_n) || (rx_state == StIdle)) parity_give <= 1'b0;
      else if ((rx_state == StParity) && baud_counter_half) parity_give <= rx_in;
      else parity_give <= parity_give;
    end

    if(PARITY == "ODD") begin
      always_ff @(posedge clk or negedge rst_n) begin : BLK_PARITY_CAL
        if (!rst_n) parity_calc <= 1'b0;
        else if (rx_state == StParity) parity_calc <= ^data_reg;
        else parity_calc <= parity_calc;
      end
    end
    else begin
      always_ff @(posedge clk or negedge rst_n) begin : BLK_PARITY_CAL
        if (!rst_n) parity_calc <= 1'b0;
        else if (rx_state == StParity) parity_calc <= ~^data_reg;
        else parity_calc <= parity_calc;
      end
    end

  end
  else begin
    assign parity_give = 1'b0;
    assign parity_calc = 1'b0;
  end
endgenerate

always_ff @(posedge clk or negedge rst_n) begin : BLK_BIT_COUNTER_LAST
  if(!rst_n || (rx_state == StIdle))
    bit_counter_last <= 1'b0;
  else if (bit_counter == DATA_BITS) bit_counter_last <= 1'b1;
  else bit_counter_last <= bit_counter_last;
end

// 生成数据有效信号和输出数据
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    rx_data_valid <= 1'b0;
    rx_data <= '0;
    rx_data_error <= 1'b0;
  end
  else if((rx_state == StStop) && baud_counter_last) begin
    rx_data_valid <= 1'b1;
    rx_data <= data_reg;
    rx_data_error <= (parity_give != parity_calc) ? 1'b1 : 1'b0;
  end
  else begin
    rx_data_valid <= 1'b0;
    rx_data <= rx_data;
    rx_data_error <= 1'b0;
  end
end

endmodule // uart_rx

`endif // UART_RX_