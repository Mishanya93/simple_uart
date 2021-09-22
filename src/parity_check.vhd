LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY parity_check IS
	PORT (
			clk		: in  STD_LOGIC;
			areset_n	: in  STD_LOGIC;
			sreset	: in  STD_LOGIC;
			enable	: in  STD_LOGIC;
		   input		: in  STD_LOGIC;
			output   : out STD_LOGIC
			);
END ENTITY parity_check;

ARCHITECTURE rtl OF parity_check IS

	SIGNAL s_output  : STD_LOGIC := 'X';

BEGIN

	process(clk,areset_n)
	begin
		if(areset_n = '0') then
			s_output  <= '0';
		else
			if(rising_edge(clk)) then
				if((enable or sreset) = '1') then
					if(sreset = '1') then
						s_output <= '0';
					else
						s_output <= s_output xor input;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	output <= s_output;

END rtl;