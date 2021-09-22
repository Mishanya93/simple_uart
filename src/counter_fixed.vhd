LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY counter_fixed IS
	GENERIC (
				counter_value : INTEGER := 8
				);
	PORT 	  (
				clk	   : in  STD_LOGIC;
				areset_n : in  STD_LOGIC;
				sreset   : in  STD_LOGIC;
				enable   : in  STD_LOGIC;
				--
				almost_over : out STD_LOGIC;
				over		   : out STD_LOGIC
				);
END ENTITY counter_fixed;

ARCHITECTURE rtl OF counter_fixed IS
	
	SIGNAL cntr_reg : INTEGER range 0 to counter_value-1;
	
	SIGNAL s_cntr_over,
			 s_cntr_almost_over: STD_LOGIC := 'X';

BEGIN

	ASSERT (counter_value > 2) REPORT ("Increase 'counter_value' parameter.") SEVERITY ERROR;

	process(clk,areset_n)
	begin
		if(areset_n = '0') then
		
		else
			if(rising_edge(clk)) then
				if(enable = '1') then
					if((sreset or s_cntr_over) = '1') then
						cntr_reg <= 0;
					else
						cntr_reg <= cntr_reg + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	--
	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_cntr_over        <= '0';
			s_cntr_almost_over <= '0';
		else
			if(rising_edge(clk)) then
				if(enable = '1') then
					if(cntr_reg = counter_value-3) then
						s_cntr_almost_over <= '1';
					else
						s_cntr_almost_over <= '0';
					end if;
					--
					s_cntr_over <= s_cntr_almost_over;
				end if;
			end if;
		end if;
	end process;
	
	almost_over <= s_cntr_almost_over;
	over			<= s_cntr_over;

END rtl;