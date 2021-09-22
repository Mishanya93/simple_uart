# simple_uart
Simple UART RTL-Model in VHDL.

This project was made mostly for educational purposes to show some of most powerful features of VHDL:
  1) hierarchical design;
  2) 'GENERIC-GENERIC MAP' construction to parametrise instances;
  3) 'CONSTANT' keyword to define local parameters (note: these parameters can be calculated from generic values and previous constants);
  4) 'GENERATE' statements to define specific code-regions, based on generic or local parameters;
  5) 'FOR-LOOP' statements for description of repetitive circuits;
  6) 'FUNCTION' keyword to define functions;
  7) 'PACKAGE-PACKAGE BODY' statement to define types, constants and components commonly used in several modules;
  and so on.
  
Note, that some actions are performed in different ways (intentionally). For instance, in 'parity_check.vhd' module calculation of even parity bit is performed sequentially (step-by-step during several clock cycles), as in 'pkg_functions.vhd' this problem is solved with FUNCTION to generate a parallel circuit, consisting of several XOR-elements.


PS: Top-level module of the project is 'uart.vhd'.
