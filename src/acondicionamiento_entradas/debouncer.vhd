library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    generic (
        STABLE_COUNT : integer := 2_000_000
    );
    port (
        clk       : in  std_logic;
        btn_in    : in  std_logic;
        btn_level : out std_logic;
        btn_pulse : out std_logic
    );
end entity;

architecture rtl of debouncer is
    signal sync0, sync1      : std_logic := '0';
    signal stable_state      : std_logic := '0';
    signal previous_state    : std_logic := '0';
    signal counter           : integer range 0 to STABLE_COUNT := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            sync0 <= btn_in;
            sync1 <= sync0;

            previous_state <= stable_state;

            if sync1 = stable_state then
                counter <= 0;
            else
                if counter = STABLE_COUNT - 1 then
                    stable_state <= sync1;
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    btn_level <= stable_state;
    btn_pulse <= stable_state and not previous_state;

end architecture;
