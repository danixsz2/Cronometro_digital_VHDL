library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_divider is
    generic (
        CLK_FREQ : integer := 100_000_000
    );
    port (
        clk          : in  std_logic;
        tick_10ms    : out std_logic;
        tick_1ms     : out std_logic
    );
end entity;

architecture rtl of clk_divider is
    constant COUNT_10MS : integer := CLK_FREQ / 100;
    constant COUNT_1MS  : integer := CLK_FREQ / 1000;

    signal cnt_10ms : integer range 0 to COUNT_10MS - 1 := 0;
    signal cnt_1ms  : integer range 0 to COUNT_1MS - 1 := 0;

    signal tick_10ms_r : std_logic := '0';
    signal tick_1ms_r  : std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            tick_10ms_r <= '0';
            tick_1ms_r  <= '0';

            if cnt_10ms = COUNT_10MS - 1 then
                cnt_10ms <= 0;
                tick_10ms_r <= '1';
            else
                cnt_10ms <= cnt_10ms + 1;
            end if;

            if cnt_1ms = COUNT_1MS - 1 then
                cnt_1ms <= 0;
                tick_1ms_r <= '1';
            else
                cnt_1ms <= cnt_1ms + 1;
            end if;
        end if;
    end process;

    tick_10ms <= tick_10ms_r;
    tick_1ms  <= tick_1ms_r;

end architecture;
