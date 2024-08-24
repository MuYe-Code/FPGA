`ifndef DATA_PROCESSOR_
`define DATA_PROCESSOR_

module data_processor #(
  parameter DATA_BITS = 8
)(
  input  logic       clk,            // 输入时钟信号
  input  logic       rst_n,          // 异步复位信号 (低电平有效)
  input  logic       rx_data_valid,  // 数据有效信号
  input  logic [7:0] rx_data,        // 接收的数据
  output logic       tx_en,          // 发送使能信号
  output logic [7:0] data_out        // 输出数据
);

// 数据寄存器
logic [7:0] data_reg;
logic data_valid;

always_ff @( posedge clk or negedge rst_n ) begin : BLK_DATA_REG
  if(!rst_n) begin
    data_reg <= '0;
    data_valid <= 1'b0;
  end
  else begin
    data_reg <= rx_data;
    data_valid <= rx_data_valid;
  end
end

always_ff @( posedge clk or negedge rst_n ) begin : BLK_TX
  if(!rst_n) begin
    tx_en <= 1'b0;
    data_out <= '0;
  end
  else begin
    tx_en <= data_valid;
    data_out <= data_reg + 1'b1;
  end
end

endmodule // data_processor

`endif // DATA_PROCESSOR_