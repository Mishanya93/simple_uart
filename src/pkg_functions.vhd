LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE pkg_functions IS

	FUNCTION f_getEvenParityBit(op_A : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
	
	FUNCTION g_getParityBitCount(op_A : STRING) RETURN INTEGER;

END PACKAGE pkg_functions;
---

PACKAGE BODY pkg_functions IS

	FUNCTION f_getEvenParityBit(op_A : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
		VARIABLE v_temp : STD_LOGIC := '0';
	BEGIN
		for idx in (op_A'length-1) downto 0 loop
			v_temp := v_temp xor op_A(idx);
		end loop;
		--
		RETURN v_temp;
	END FUNCTION f_getEvenParityBit;
	
	FUNCTION g_getParityBitCount(op_A : STRING) RETURN INTEGER IS
	BEGIN
		if(op_A = "N") then 
			RETURN 0;
		else
			RETURN 1;
		end if;
	END FUNCTION g_getParityBitCount;

END PACKAGE BODY pkg_functions;

