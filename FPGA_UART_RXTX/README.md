### Device Information
Zynq 7010 FPGA
50 MHz Clock

### Modules
1. uart_rx
    - UART Receiver
    - CLOCK_FREQ, default 50 MHz, configurable
    - BAUD_RATE, default 115200, configurable
    - DATA_BITS, default 8, configurable
    - PARITY, default NONE, configurable
    - STOP_BITS, 1 bit only
2. uart_tx
    - UART Transmitter
    - CLOCK_FREQ, default 50 MHz, configurable
    - BAUD_RATE, default 115200, configurable
    - DATA_BITS, default 8, configurable
    - PARITY, default NONE, configurable
    - STOP_BITS, 1 bit only
3. uart_counter
    - UART Counter
    - count from 0 to 15, show on LED
    - count the number of received data
4. data_processor
    - Data Processor
    - receive data from uart_rx, send (data + 1) to uart_tx
5. uart_top
    - UART Top Module
    - CLOCK_FREQ, default 50 MHz, configurable
    - BAUD_RATE, default 115200, configurable
    - DATA_BITS, default 8, configurable
    - PARITY, default NONE, configurable
    - STOP_BITS, 1 bit only

### Simulation
1. uart_top_tb
    - Testbench for uart_top
    - send data to uart_top, receive data from uart_top

### Constraints
1. pll_uart_pin.xdc
    - Constraints for PL Part of Zynq 7010 FPGA
    - Bind Pins for UART
    - Bind Pins for LED
    - Set IO Standard as LVCMOS33