`ifndef UART_COUNTER_
`define UART_COUNTER_

module uart_counter (
  input  logic clk,
  input  logic rst_n,
  input  logic en,
  output logic [3:0] count
);

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    count <= '0;
  end
  else if (en) begin
    count <= count + 1'b1;
  end
  else begin
    count <= count;
  end
end

endmodule

`endif