library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bcd2ascii is
 Port (bcd      : in    std_logic_vector(3 downto 0);
       ascii    : out   std_logic_vector(7 downto 0));
end bcd2ascii;

architecture Behavioral of bcd2ascii is
signal ascii_num    : unsigned(7 downto 0);
begin

ascii_num <= 8x"30" when bcd="0000" else
             8x"31" when bcd="0001" else
             8x"32" when bcd="0010" else
             8x"33" when bcd="0011" else
             8x"34" when bcd="0100" else
             8x"35" when bcd="0101" else
             8x"36" when bcd="0110" else
             8x"37" when bcd="0111" else
             8x"38" when bcd="1000" else
             8x"39" when bcd="1001" else
             "00000000";
        
ascii<=std_logic_vector(ascii_num); 
end Behavioral;
