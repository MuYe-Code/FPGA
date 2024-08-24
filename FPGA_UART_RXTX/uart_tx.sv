`ifndef UART_TX_
`define UART_TX_

module uart_tx #(
  parameter unsigned CLOCK_FREQ = 50_000_000, // 系统时钟频率
  parameter unsigned BAUD_RATE = 115_200,     // 串口波特率
  parameter unsigned DATA_BITS = 8,           // 数据位数
  parameter string   PARITY = "NONE",         // 奇偶校验类型: "NONE", "ODD", "EVEN"
  parameter unsigned STOP_BITS = 1            // 停止位数
)(
  input  logic       clk,            // 输入时钟信号
  input  logic       rst_n,          // 异步复位信号 (低电平有效)
  input  logic       tx_data_valid,  // 数据有效信号
  input  logic [7:0] tx_data,        // 待发送的数据
  output logic       tx_out          // 串行输出数据
);

// 计算波特率计数器的最大值
localparam unsigned UART_COUNTER_MAX = CLOCK_FREQ / BAUD_RATE; //>2
// 计算波特率计数器所需的位宽
localparam unsigned UART_COUNTER_WIDTH = $clog2(UART_COUNTER_MAX+1);
localparam unsigned DATA_COUNTER_WIDTH = $clog2(DATA_BITS);

// 波特率计数器
logic [UART_COUNTER_WIDTH-1:0] baud_counter;
logic baud_counter_last;

// 数据发送计数器
logic [DATA_COUNTER_WIDTH-1:0] bit_counter;
logic bit_counter_last;

// 数据寄存器
logic [DATA_BITS-1:0] data_reg;

// 奇偶校验位
logic parity_give;

// 枚举类型定义发送状态
typedef enum logic[2:0] {
  StIdle,
  StStart,
  StData,
  StParity,
  StStop
} fsm_tx_t;

fsm_tx_t tx_state;
fsm_tx_t tx_state_next;

// 生成波特率计数器
always_ff @(posedge clk or negedge rst_n) begin: BLK_BAUD_COUNTER
  if (!rst_n) baud_counter <= '0;
  else if (baud_counter_last || (tx_state == StIdle)) baud_counter <= '0;
  else baud_counter <= baud_counter + 1'b1;
end

// 生成波特率计数器最后时刻标志
always_ff @( posedge clk or negedge rst_n ) begin : BLK_BAUD_COUNTER_LAST
  if(!rst_n) baud_counter_last <= 1'b0;
  else if(baud_counter == UART_COUNTER_MAX-2) baud_counter_last <= 1'b1;
  else baud_counter_last <= 1'b0;
end

// 生成数据发送计数器最后时刻标志
always_ff @(posedge clk or negedge rst_n) begin : BLK_BIT_COUNTER_LAST
  if(!rst_n || (tx_state == StIdle))
    bit_counter_last <= 1'b0;
  else if (bit_counter == DATA_BITS - 1) bit_counter_last <= 1'b1;
  else bit_counter_last <= bit_counter_last;
end

// 生成状态机组合逻辑
always_comb begin : FSM_TX_COMB
  case(tx_state)
    StIdle  : tx_state_next = tx_data_valid ? StStart : StIdle;
    StStart : tx_state_next = baud_counter_last ? StData : StStart;
    StData  : tx_state_next = (baud_counter_last & bit_counter_last)
                                ? (PARITY == "NONE")
                                  ? StStop
                                  : StParity
                                : StData;
    StParity: tx_state_next = baud_counter_last ? StStop : StParity;
    StStop  : tx_state_next = baud_counter_last ? StIdle : StStop;
    default : tx_state_next = StIdle;
  endcase
end

// 生成状态机触发逻辑
always_ff @( posedge clk or negedge rst_n ) begin : FSM_TX_FF
  if(!rst_n) tx_state <= StIdle;
  else tx_state <= tx_state_next;
end

// 读取输入数据
always_ff @(posedge clk or negedge rst_n) begin : BLK_DATA_REG
  if ((!rst_n)) begin
    data_reg <= '0;
    bit_counter <= '0;
  end
  else if(tx_state == StIdle) begin
    bit_counter <= '0;
    if(tx_data_valid) begin
      data_reg <= tx_data;
    end
  end
  else if((tx_state == StData) & baud_counter_last) begin
      data_reg <= (data_reg >> 1); // Shift data to the right
      bit_counter <= bit_counter + 1'b1;
  end
  else begin
      data_reg <= data_reg;
      bit_counter <= bit_counter;
  end
end

// 生成奇偶校验位
generate
  if (PARITY != "NONE") begin
    always_ff @(posedge clk or negedge rst_n) begin : BLK_PARITY_GIVE
      if ((!rst_n) || (tx_state == StIdle)) parity_give <= 1'b0;
      else if ((tx_state == StParity)) begin
        if (PARITY == "ODD") parity_give <= (^data_reg);
        else parity_give <= (~^data_reg);
      end
      else parity_give <= parity_give;
    end
  end
  else begin
    assign parity_give = 1'b0;
  end
endgenerate

always_ff @( posedge clk or negedge rst_n ) begin : BLK_TX_OUT
  if(!rst_n) tx_out <= 1'b1;
  else begin
    case(tx_state)
      StIdle  : tx_out <= 1'b1;
      StStart : tx_out <= 1'b0;
      StData  : tx_out <= data_reg[0];
      StParity: tx_out <= parity_give;
      StStop  : tx_out <= 1'b1;
      default : tx_out <= 1'b1;
   endcase
  end
end

endmodule // uart_tx

`endif // UART_TX_