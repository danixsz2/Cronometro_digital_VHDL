library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_segment_driver is
    port (
        clk          : in  std_logic;
        tick_refresh : in  std_logic;

        digit0       : in  std_logic_vector(3 downto 0);
        digit1       : in  std_logic_vector(3 downto 0);
        digit2       : in  std_logic_vector(3 downto 0);
        digit3       : in  std_logic_vector(3 downto 0);

        an           : out std_logic_vector(3 downto 0);
        seg          : out std_logic_vector(6 downto 0);
        dp           : out std_logic
    );
end entity;

architecture rtl of seven_segment_driver is

    signal sel : integer range 0 to 3 := 0;

    signal an_r  : std_logic_vector(3 downto 0) := "1111";
    signal seg_r : std_logic_vector(6 downto 0) := "1111111";
    signal dp_r  : std_logic := '1';

    function decode_7seg(bcd : std_logic_vector(3 downto 0))
        return std_logic_vector is
    begin
        case bcd is
            when "0000" => return "1000000";
            when "0001" => return "1111001";
            when "0010" => return "0100100";
            when "0011" => return "0110000";
            when "0100" => return "0011001";
            when "0101" => return "0010010";
            when "0110" => return "0000010";
            when "0111" => return "1111000";
            when "1000" => return "0000000";
            when "1001" => return "0010000";
            when others => return "1111111";
        end case;
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if tick_refresh = '1' then
                if sel = 3 then
                    sel <= 0;
                else
                    sel <= sel + 1;
                end if;
            end if;
        end if;
    end process;

    process(sel, digit0, digit1, digit2, digit3)
        variable d : std_logic_vector(3 downto 0);
    begin
        case sel is
            when 0 =>
                an_r <= "1110";
                d := digit0;
                dp_r <= '1';

            when 1 =>
                an_r <= "1101";
                d := digit1;
                dp_r <= '1';

            when 2 =>
                an_r <= "1011";
                d := digit2;
                dp_r <= '0';

            when others =>
                an_r <= "0111";
                d := digit3;
                dp_r <= '1';
        end case;

        seg_r <= decode_7seg(d);
    end process;

    an  <= an_r;
    seg <= seg_r;
    dp  <= dp_r;

end architecture;
