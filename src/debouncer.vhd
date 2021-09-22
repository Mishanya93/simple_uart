LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY debouncer IS
	GENERIC (
				ms_protection : STRING  := "ON";
				stable_count  : INTEGER := 5
				);
	PORT	  (
				clk		: in  STD_LOGIC;
				areset_n : in  STD_LOGIC;
				enable	: in  STD_LOGIC;
				input		: in  STD_LOGIC;
				output   : out STD_LOGIC 
				);
END ENTITY debouncer;

ARCHITECTURE rtl OF debouncer IS

	CONSTANT c_msp_stages : INTEGER := 1;

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
	
	SIGNAL s_input,
			 s_input_d : STD_LOGIC := 'X';
	
	SIGNAL s_cntr_deb_sreset,
			 s_cntr_deb_enable,
			 s_cntr_deb_over	  : STD_LOGIC := 'X';
	
	SIGNAL s_output  : STD_LOGIC := 'X';

BEGIN

	ASSERT (ms_protection = "OFF") REPORT ("Additional FFs generated for metastability protection.") SEVERITY NOTE;		-- generate notification in simulator console, if 'ms_protection' is set to "ON"
	ASSERT (stable_count > 1) REPORT ("No input signal filtration is performed.") SEVERITY WARNING;							   -- generate warning message in simulator console, if 'stable_count' is less than 2

-- Metastability Protection	
gen_no_msp:
	if(ms_protection = "OFF") generate
	begin
		process(clk,areset_n)
		begin
			if(areset_n = '0') then
				s_input <= '0';
			else
				if(rising_edge(clk)) then
					s_input <= input;
				end if;
			end if;
		end process;
	end generate gen_no_msp;
--
gen_msp:
	if(ms_protection = "ON") generate	
		SIGNAL s_msp_reg : STD_LOGIC_VECTOR(c_msp_stages downto 0) := (others => 'X');
	begin	
		ASSERT (c_msp_stages > 0) REPORT ("Value of 'c_msp_stages' must be a positive integer.") SEVERITY ERROR;
		--
		process(clk,areset_n)
		begin
			if(areset_n = '0') then
				s_msp_reg <= (others => '0');
			else
				if(rising_edge(clk)) then
					s_msp_reg(s_msp_reg'length-1 downto 0) <= input & s_msp_reg(s_msp_reg'length-1 downto 1);
				end if;
			end if;
		end process;
		--
		s_input <= s_msp_reg(0);
	end generate gen_msp;

--	
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_input_d <= '0';
		else
			if(rising_edge(clk)) then
				s_input_d <= s_input;
			end if;
		end if;
	end process;
	--
	s_cntr_deb_sreset <= s_input xor s_input_d;
	--
	
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_cntr_deb_enable <= '0';
		else
			if(rising_edge(clk)) then
				if   (s_cntr_deb_sreset = '1') then
					s_cntr_deb_enable <= '1';
				elsif(s_cntr_deb_over = '1') then
					s_cntr_deb_enable <= '0';
				end if;
			end if;
		end if;
	end process;
	--
	
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_output <= '0';
		else
			if(rising_edge(clk)) then
				if(s_cntr_deb_over = '1') then
					s_output <= s_input;
				end if;
			end if;
		end if;
	end process;
	
-- Component Instantiation
cntr_deb_inst:
	counter_fixed GENERIC MAP (counter_value => stable_count)
					  PORT 	 MAP (clk	  	   => clk,
										areset_n 	=> areset_n,
										sreset  		=> s_cntr_deb_sreset,
										enable   	=> s_cntr_deb_enable,
										almost_over => OPEN,
										over			=> s_cntr_deb_over);
										
	output <= s_output;
		
END rtl;