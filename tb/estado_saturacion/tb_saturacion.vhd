library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_saturacion is
end entity;

architecture sim of tb_saturacion is

    constant CLK_PERIOD : time := 10 ns;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal tick_10ms : std_logic := '0';
    signal enable    : std_logic := '0';

    signal digit0 : std_logic_vector(3 downto 0);
    signal digit1 : std_logic_vector(3 downto 0);
    signal digit2 : std_logic_vector(3 downto 0);
    signal digit3 : std_logic_vector(3 downto 0);

    signal zero     : std_logic;
    signal overflow : std_logic;

    signal bcd_display : std_logic_vector(15 downto 0);

    signal led0  : std_logic;
    signal led15 : std_logic;

    signal marker_near_limit  : std_logic := '0';
    signal marker_saturation  : std_logic := '0';

begin

    clk <= not clk after CLK_PERIOD / 2;

    bcd_display <= digit3 & digit2 & digit1 & digit0;

    led0  <= enable and not overflow;
    led15 <= overflow;

    U_COUNTER : entity work.chrono_counter
        port map (
            clk        => clk,
            rst        => rst,
            tick_10ms  => tick_10ms,
            enable     => enable,

            digit0     => digit0,
            digit1     => digit1,
            digit2     => digit2,
            digit3     => digit3,

            zero       => zero,
            overflow   => overflow
        );

    stim_proc : process

        procedure tick_once is
        begin
            tick_10ms <= '1';
            wait until rising_edge(clk);
            tick_10ms <= '0';
            wait until rising_edge(clk);
        end procedure;

    begin

        -- Reset inicial
        rst <= '1';
        wait for 50 ns;
        rst <= '0';
        wait for 50 ns;

        enable <= '1';

        -- Avance rápido hasta 99.97
        -- Cada tick representa una centésima en la lógica del contador.
        for i in 1 to 9997 loop
            tick_once;
        end loop;

        marker_near_limit <= '1';

        -- Tick 9998: 99.98
        tick_once;
        wait for 80 ns;

        -- Tick 9999: 99.99
        tick_once;
        wait for 80 ns;

        -- Tick 10000: activa overflow/saturación
        tick_once;
        marker_saturation <= '1';

        wait for 300 ns;

        -- Intentamos seguir contando, pero debe permanecer en 99.99
        for i in 1 to 5 loop
            tick_once;
        end loop;

        wait for 300 ns;

        wait;
    end process;

end architecture;
