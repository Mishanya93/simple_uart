# simple_uart
Simple UART RTL-Model in VHDL.

**Disclaimer:**
This project was made mostly for educational purposes to show some of most powerful features of VHDL:
  1) hierarchical design;
  2) 'GENERIC-GENERIC MAP' construction to parametrise instances;
  3) 'CONSTANT' keyword to define local parameters (note: these parameters can be calculated from generic values and previous constants);
  4) 'GENERATE' statements to define specific code-regions, based on generic or local parameters;
  5) 'FOR-LOOP' statements for description of repetitive circuits;
  6) 'FUNCTION' keyword to define functions;
  7) 'PACKAGE-PACKAGE BODY' statement to define types, constants and components commonly used in several modules;
  8) 'ASSERT' keyword to generate notes, warnings and error messages to show up during simulation
  and so on.
  
Note, that some actions are performed in different ways (intentionally). For instance, in 'parity_check.vhd' module calculation of even parity bit is performed sequentially (step-by-step during several clock cycles), as in 'pkg_functions.vhd' this problem is solved with FUNCTION to generate a parallel circuit, consisting of several XOR-elements.


**GENERIC parameters** (of top-level module *'uart.vhd'*):
  1) *clk_freq_MHz* - internal clock frequency of corresponding FPGA-region in MHz;
  2) *baud_rate*    - UART baudrate;
  3) *data_bits*    - data bits count in single packet;
  4) *parity*       - parity check (valid values are: "N"-none, "E"-even, "O"-odd);
  5) *stop_bits*    - stop bits count (valid values are: 1.0, 1.5, 2.0).
Note, UART settings are made corresponding to how they are usually described (for instance, "8N1" stands for 8 data bits, No parity check, 1 stop bit).

**Ports description** (of top-level module *'uart.vhd'*):  
  *clk*      - **input**  - clock signal;  
  *areset_n* - **input**  - asynchronous reset signal (active LOW);  
--*UART transmitter*--  
  *irq_tx*   - **input**  - transmitter interrupt signal, used to start transaction (note, it is ignored when *busy* is high);  
  *data*     - **input**  - data to be transmitted (*data_bits*-wide);  
  *busy*     - **output** - signal, indicating that transmition is in progress;  
--*UART receiver*--  
  *irq_rx*   - **output** - receiver interrupt signal to indicate that new data have been received;  
  *q*        - **output** - received data (*data_bits*-wide).  
