library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chrono_counter is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        tick_10ms  : in  std_logic;
        enable     : in  std_logic;

        digit0     : out std_logic_vector(3 downto 0);
        digit1     : out std_logic_vector(3 downto 0);
        digit2     : out std_logic_vector(3 downto 0);
        digit3     : out std_logic_vector(3 downto 0);

        zero       : out std_logic;
        overflow   : out std_logic
    );
end entity;

architecture rtl of chrono_counter is

    signal cs_units  : integer range 0 to 9 := 0;
    signal cs_tens   : integer range 0 to 9 := 0;
    signal sec_units : integer range 0 to 9 := 0;
    signal sec_tens  : integer range 0 to 9 := 0;

    signal overflow_r : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cs_units  <= 0;
                cs_tens   <= 0;
                sec_units <= 0;
                sec_tens  <= 0;
                overflow_r <= '0';

            elsif tick_10ms = '1' and enable = '1' and overflow_r = '0' then

                if sec_tens = 9 and sec_units = 9 and cs_tens = 9 and cs_units = 9 then
                    overflow_r <= '1';
                else
                    if cs_units < 9 then
                        cs_units <= cs_units + 1;
                    else
                        cs_units <= 0;

                        if cs_tens < 9 then
                            cs_tens <= cs_tens + 1;
                        else
                            cs_tens <= 0;

                            if sec_units < 9 then
                                sec_units <= sec_units + 1;
                            else
                                sec_units <= 0;

                                if sec_tens < 9 then
                                    sec_tens <= sec_tens + 1;
                                else
                                    sec_tens <= 9;
                                    sec_units <= 9;
                                    cs_tens <= 9;
                                    cs_units <= 9;
                                    overflow_r <= '1';
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    digit0 <= std_logic_vector(to_unsigned(cs_units, 4));
    digit1 <= std_logic_vector(to_unsigned(cs_tens, 4));
    digit2 <= std_logic_vector(to_unsigned(sec_units, 4));
    digit3 <= std_logic_vector(to_unsigned(sec_tens, 4));

    zero <= '1' when cs_units = 0 and cs_tens = 0 and sec_units = 0 and sec_tens = 0 else '0';
    overflow <= overflow_r;

end architecture;
