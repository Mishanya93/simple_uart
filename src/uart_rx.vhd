LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.pkg_functions.g_getParityBitCount;

ENTITY uart_rx IS
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
END ENTITY uart_rx;

ARCHITECTURE rtl OF uart_rx IS

	CONSTANT c_ms_protection : STRING  := "ON";
	CONSTANT	c_stable_count  : INTEGER := 5;
	
	CONSTANT c_brate_cycles  : INTEGER := (clk_freq_MHz*1_000_000)/(2*baud_rate);
	CONSTANT c_total_bits    : INTEGER := data_bits + g_getParityBitCount(parity);
	
	COMPONENT debouncer IS
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
	END COMPONENT;
	
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
	
	TYPE t_rx_fsm IS (IDLE,
							START,
							RX,
							STOP);
	SIGNAL crnt_state,
			 next_state  : t_rx_fsm;
		
	SIGNAL s_half_bit  : STD_LOGIC := 'X';
	
	SIGNAL s_cntr_brate_enable,
			 s_cntr_brate_almost_over,
			 s_cntr_brate_over   : STD_LOGIC := 'X';
	
	SIGNAL s_cntr_bits_enable,
			 s_cntr_bits_over    : STD_LOGIC := 'X';
	
	SIGNAL s_rx_pin_db    : STD_LOGIC := 'X';
	SIGNAL s_rx_pin_db_d,
			 s_rx_pin_db_fe : STD_LOGIC := 'X';
	
	SIGNAL s_irq_rx	 : STD_LOGIC := 'X';
	SIGNAL s_q			 : STD_LOGIC_VECTOR(c_total_bits-1 downto 0) := (others => 'X');

BEGIN

	ASSERT (((clk_freq_MHz*1_000_000)/baud_rate) >= c_stable_count) REPORT ("Current 'c_stable_count' is greater than bit duration. It is strongly recommended to reduce the value.") SEVERITY WARNING;

-- Receiver FSM Description 
proc_fsm_comb:
	process(all)
	begin
		case crnt_state is
			when IDLE  =>
				if(s_rx_pin_db_fe = '1') then
					next_state <= START;
				else
					next_state <= IDLE;
				end if;
			--
			when START =>
				if(s_cntr_brate_over = '1') then
					if(s_rx_pin_db = '0') then
						next_state <= RX;
					else
						next_state <= IDLE;
					end if;
				else
					next_state <= START;
				end if;
			--
			when RX	  =>
				if((s_cntr_bits_enable and s_cntr_bits_over) = '1') then
					next_state <= STOP;
				else
					next_state <= RX;
				end if;
			--
			when STOP =>
				if(s_cntr_brate_over = '1') then
					next_state <= IDLE;
				else
					next_state <= STOP;
				end if;
			--
			when others =>
				next_state <= STOP;
		end case;
	end process;

proc_fsm_seq:
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			crnt_state <= IDLE;
		else
			if(rising_edge(clk)) then
				crnt_state <= next_state;
			end if;
		end if;
	end process;
	
-- Main Logic
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_rx_pin_db_d <= '0';
		else
			if(rising_edge(clk)) then
				s_rx_pin_db_d <= s_rx_pin_db;
			end if;
		end if;
	end process;
	--
	s_rx_pin_db_fe <= not(s_rx_pin_db) and s_rx_pin_db_d;
	
	process(clk,areset_n)
	begin
		if(areset_n = '0') then 
			s_cntr_brate_enable <= '0';
			--
			s_half_bit <= '0';
			--
			s_irq_rx   <= '0';
		else
			if(rising_edge(clk)) then
				case crnt_state is
					when IDLE =>
						s_cntr_brate_enable <= s_rx_pin_db_fe;
						s_irq_rx 			  <= '0';
					--	
					when START =>
						s_cntr_brate_enable <= not(s_cntr_brate_over and s_rx_pin_db);
					--
					when RX    => 
						if(s_cntr_brate_over = '1')  then
							s_half_bit <= not(s_half_bit);
						end if;
					--
					when STOP =>
						s_cntr_brate_enable <= not(s_cntr_brate_over and s_rx_pin_db);
						s_irq_rx				  <= s_cntr_brate_over and s_rx_pin_db;
					--
					when others =>
						NULL;
				end case;
			end if;
		end if;
	end process;
	--
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_cntr_bits_enable <= '0';
		else	
			if(rising_edge(clk)) then
				s_cntr_bits_enable <= s_cntr_brate_almost_over and s_half_bit;
			end if;
		end if;
	end process;
	
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_q <= (others => '0');
		else	
			if(rising_edge(clk)) then
				if(s_cntr_bits_enable = '1') then
					s_q(c_total_bits-1 downto 0) <= s_rx_pin_db & s_q(c_total_bits-1 downto 1);	
				end if;
			end if;
		end if;
	end process;

-- Component Instantiation 
debouncer_inst:
	debouncer GENERIC MAP (ms_protection => c_ms_protection,
								  stable_count  => c_stable_count)
				 PORT    MAP (clk		  => clk,
								  areset_n => areset_n,
								  enable	  => '1',
								  input	  => rx_pin,
								  output   => s_rx_pin_db);

cntr_brate_inst:
	counter_fixed GENERIC MAP (counter_value => c_brate_cycles)
					  PORT 	 MAP (clk	   => clk,
										areset_n 	=> areset_n,
										sreset		=> '0',
										enable   	=> s_cntr_brate_enable,
										almost_over => s_cntr_brate_almost_over,
										over			=> s_cntr_brate_over);
cntr_bits_inst:
	counter_fixed GENERIC MAP (counter_value => c_total_bits)
					  PORT 	 MAP (clk	   	=> clk,
										areset_n 	=> areset_n,
										sreset		=> '0',
										enable   	=> s_cntr_bits_enable,
										almost_over => OPEN,
										over			=> s_cntr_bits_over);

gen_no_prty_chk:
	if(parity = "N") generate
		parity_ok <= '1';
	end generate gen_no_prty_chk;
--	
gen_prty_chk:
	if(parity /= "N") generate
		COMPONENT parity_check IS
			PORT (
					clk		: in  STD_LOGIC;
					areset_n	: in  STD_LOGIC;
					sreset	: in  STD_LOGIC;
					enable	: in  STD_LOGIC;
					input		: in  STD_LOGIC;
					output   : out STD_LOGIC
					);
		END COMPONENT;
		--
		ALIAS  s_prty_enable IS s_cntr_bits_enable;
		SIGNAL s_prty_sreset : STD_LOGIC := 'X';
		SIGNAL s_prty_output : STD_LOGIC := 'X';
	begin
		process(clk,areset_n)
		begin
			if(areset_n = '0') then
				s_prty_sreset <= '0';
			else
				if(rising_edge(clk)) then
					if(crnt_state = IDLE) then
						s_prty_sreset <= not(s_rx_pin_db);
					else
						s_prty_sreset <= '0';
					end if;
				end if;
			end if;
		end process;
		--
	parity_check_inst:
		parity_check PORT MAP (clk		  => clk,
							  	     areset_n => areset_n,
							  	     sreset   => s_prty_sreset,
							  	     enable   => s_prty_enable,
									  input    => s_rx_pin_db,
									  output   => s_prty_output);
	--
		parity_ok <= s_prty_output when (parity = "O") else not(s_prty_output);	-- for odd/even parity check
	end generate gen_prty_chk;
	
	irq_rx <= s_irq_rx;
	q(data_bits-1 downto 0) <= s_q(data_bits-1 downto 0);

END rtl;

	