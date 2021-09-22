LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;	

LIBRARY work;
USE work.pkg_functions.ALL;
	
ENTITY uart_tx IS
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
END ENTITY uart_tx;

ARCHITECTURE rtl OF uart_tx IS

	-- internal parameters evaluation (do not change)
	CONSTANT c_brate_cycles  : INTEGER := (clk_freq_MHz*1_000_000)/(2*baud_rate);
	CONSTANT c_total_bits    : INTEGER := data_bits + g_getParityBitCount(parity);
	--
	CONSTANT c_cntr_bits_value   : INTEGER := 2*(c_total_bits+1) + stop_halfbits;
	CONSTANT c_output_reg_length : INTEGER := c_total_bits+3;

	COMPONENT counter_fixed IS
		GENERIC (
					counter_value : INTEGER := 8
					);
		PORT 	  (
					clk	   	: in  STD_LOGIC;
					areset_n 	: in  STD_LOGIC;
					sreset   	: in  STD_LOGIC;
					enable   	: in  STD_LOGIC;
					--
					almost_over : out STD_LOGIC;
					over			: out STD_LOGIC
					);
	END COMPONENT;
	
	SIGNAL s_half_bit   : STD_LOGIC := 'X';

	SIGNAL s_output_enable : STD_LOGIC := 'X';

	SIGNAL s_data_reg   : STD_LOGIC_VECTOR(c_total_bits-1 downto 0) 		  := (others => 'X');
	SIGNAL s_output_reg : STD_LOGIC_VECTOR(c_output_reg_length-1 downto 0) := (others => 'X');

	ALIAS  s_cntr_brate_enable IS s_output_enable;
	SIGNAL s_cntr_brate_over   : STD_LOGIC := 'X';
	
	ALIAS  s_cntr_bits_enable  IS s_cntr_brate_over;
	SIGNAL s_cntr_bits_over    : STD_LOGIC := 'X';
			 
BEGIN

gen_no_prty:
	if(parity = "N") generate
	begin
		s_data_reg(c_total_bits-1 downto 0) <= data(data_bits-1 downto 0);
	end generate gen_no_prty;
--	
gen_odd_prty:
	if(parity = "O") generate
	begin
		s_data_reg(c_total_bits-1 downto 0) <= not(f_getEvenParityBit(data(data_bits-1 downto 0))) & data(data_bits-1 downto 0);
	end generate gen_odd_prty;
--
gen_even_prty:
	if(parity = "E") generate
	begin
		s_data_reg(c_total_bits-1 downto 0) <= f_getEvenParityBit(data(data_bits-1 downto 0)) & data(data_bits-1 downto 0);
	end generate gen_even_prty;
	
-- Logic Description
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_output_reg <= (others => '0');
		else
			if(rising_edge(clk)) then
				if   ((irq_tx and not(s_output_enable)) = '1') then
					s_output_reg(s_output_reg'length-1 downto 0) <= "11" & s_data_reg & '0';
				elsif((s_cntr_bits_enable and s_half_bit) = '1') then
					s_output_reg(s_output_reg'length-1 downto 0) <= s_output_reg(0) & s_output_reg(s_output_reg'length-1 downto 1);
				end if;
			end if;
		end if;
	end process;
	--
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_output_enable <= '0';
		else	
			if(rising_edge(clk)) then
				if   (irq_tx = '1') then
					s_output_enable <= '1';
				elsif((s_cntr_bits_enable and s_cntr_bits_over) = '1') then
					s_output_enable <= '0';
				end if;
			end if;
		end if;
	end process;
	--
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_half_bit <= '0';
		else	
			if(rising_edge(clk)) then
				if   (irq_tx = '1') then
					s_half_bit <= '0';
				elsif(s_cntr_brate_over = '1') then
					s_half_bit <= not(s_half_bit);
				end if;
			end if;
		end if;
	end process;
		
-- Component Instantiation 			
cntr_brate_inst:
	counter_fixed GENERIC MAP (counter_value => c_brate_cycles)
					  PORT 	 MAP (clk	      => clk,
										areset_n    => areset_n,
										sreset	   => '0',
										enable      => s_cntr_brate_enable,
										almost_over => OPEN,
										over		   => s_cntr_brate_over);
cntr_bits_inst:
	counter_fixed GENERIC MAP (counter_value => c_cntr_bits_value)
					  PORT 	 MAP (clk	      => clk,
										areset_n    => areset_n,
										sreset	   => '0',
										enable      => s_cntr_bits_enable,
										almost_over => OPEN,
										over			=> s_cntr_bits_over);
										
	busy   <= s_output_enable;
	tx_pin <= s_output_reg(0);
	
END rtl;