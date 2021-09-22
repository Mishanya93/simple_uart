LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY uart IS
	GENERIC (
				clk_freq_MHz  : INTEGER := 50;			-- internal clock frequency [MHz]
				--
				baud_rate     : INTEGER := 19_200;	-- UART baudrate
				data_bits	  : INTEGER := 8;			-- data bits count 
				parity        : STRING  := "N";		-- parity check    (valid values: "N" - no check / "E" - even check / "O" - odd check)
				stop_bits     : REAL    := 1.0		-- stop bits count (valid values: 1.0 / 1.5 / 2.0)	
				);
	PORT	  (
				clk	   : in  STD_LOGIC;
				areset_n : in  STD_LOGIC;
				-- uart Tx
				irq_tx   : in  STD_LOGIC;
				data     : in  STD_LOGIC_VECTOR(data_bits-1 downto 0);
				busy	   : out STD_LOGIC;
				-- uart Rx
				irq_rx   : out STD_LOGIC;
				q		   : out STD_LOGIC_VECTOR(data_bits-1 downto 0);
				--
				rx_pin	: in  STD_LOGIC;
				tx_pin   : out STD_LOGIC
				);
END ENTITY uart;

ARCHITECTURE rtl OF uart IS

	CONSTANT c_stop_halfbits : INTEGER := 2*INTEGER(stop_bits);

	COMPONENT uart_rx IS
		GENERIC (
					clk_freq_MHz  : INTEGER := 50;		
					baud_rate     : INTEGER := 19_200;	
					data_bits	  : INTEGER := 8;			
					parity        : STRING  := "N"		
					);
		PORT	  (
					clk		 : in  STD_LOGIC;
					areset_n  : in  STD_LOGIC;
					rx_pin	 : in  STD_LOGIC;
					irq_rx    : out STD_LOGIC;
					parity_ok : out STD_LOGIC;
					q			 : out STD_LOGIC_VECTOR(data_bits-1 downto 0)
					);
	END COMPONENT;
	
	COMPONENT uart_tx IS
		GENERIC (
					clk_freq_MHz  : INTEGER := 50;		
					baud_rate     : INTEGER := 19_200;	
					data_bits	  : INTEGER := 8;			
					parity        : STRING  := "N";
					stop_halfbits : INTEGER := 2		
					);
		PORT	  (
					clk		: in  STD_LOGIC;
					areset_n : in  STD_LOGIC;
					irq_tx   : in  STD_LOGIC;
					busy     : out STD_LOGIC;
					data   	: in  STD_LOGIC_VECTOR(data_bits-1 downto 0);
					tx_pin	: out STD_LOGIC
					);
	END COMPONENT;
	
	SIGNAL s_irq_rx    : STD_LOGIC := 'X';
	SIGNAL s_parity_ok : STD_LOGIC := 'X';
	
BEGIN

rx_inst:
	uart_rx GENERIC MAP (clk_freq_MHz => clk_freq_MHz,		
			               baud_rate    => baud_rate,	
			               data_bits	 => data_bits,		
			               parity       => parity)
			  PORT	 MAP (clk		 => clk,
								areset_n  => areset_n,
								rx_pin	 => rx_pin,
								irq_rx    => s_irq_rx,
								parity_ok => s_parity_ok,
								q			 => q);
	--
	irq_rx <= s_irq_rx and s_parity_ok;		-- only messages with successful parity check generate rx interrupt (change, if needed)
	
tx_inst:
	uart_tx GENERIC MAP (clk_freq_MHz  => clk_freq_MHz,		
			               baud_rate     => baud_rate,	
			               data_bits	  => data_bits,		
			               parity        => parity,
								stop_halfbits => c_stop_halfbits)
			  PORT	 MAP (clk		 => clk,
								areset_n  => areset_n,
								irq_tx    => irq_tx,
								busy      => busy,
								data   	 => data,
								tx_pin	 => tx_pin);

END rtl;