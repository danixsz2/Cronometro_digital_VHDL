library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_control_counter is
end entity;

architecture sim of tb_control_counter is

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';

    signal start_pulse : std_logic := '0';
    signal stop_pulse  : std_logic := '0';
    signal reset_pulse : std_logic := '0';
    signal send_pulse  : std_logic := '0';

    signal uart_busy   : std_logic := '0';

    signal enable_count : std_logic;
    signal reset_count  : std_logic;
    signal send_req     : std_logic;
    signal state_code   : std_logic_vector(2 downto 0);

    signal tick_10ms    : std_logic := '0';
    signal chrono_reset : std_logic;

    signal digit0 : std_logic_vector(3 downto 0);
    signal digit1 : std_logic_vector(3 downto 0);
    signal digit2 : std_logic_vector(3 downto 0);
    signal digit3 : std_logic_vector(3 downto 0);

    signal zero     : std_logic;
    signal overflow : std_logic;

    signal bcd_display : std_logic_vector(15 downto 0);

begin

    clk <= not clk after CLK_PERIOD / 2;

    chrono_reset <= reset_pulse or reset_count;

    bcd_display <= digit3 & digit2 & digit1 & digit0;

    U_CONTROL : entity work.control_fsm
        port map (
            clk          => clk,
            rst          => reset_pulse,

            start_pulse  => start_pulse,
            stop_pulse   => stop_pulse,
            send_pulse   => send_pulse,

            uart_busy    => uart_busy,

            enable_count => enable_count,
            reset_count  => reset_count,
            send_req     => send_req,
            state_code   => state_code
        );

    U_COUNTER : entity work.chrono_counter
        port map (
            clk        => clk,
            rst        => chrono_reset,
            tick_10ms  => tick_10ms,
            enable     => enable_count,

            digit0     => digit0,
            digit1     => digit1,
            digit2     => digit2,
            digit3     => digit3,

            zero       => zero,
            overflow   => overflow
        );

    stim_proc : process

        procedure pulse_signal(signal s : out std_logic) is
        begin
            s <= '1';
            wait until rising_edge(clk);
            s <= '0';
            wait until rising_edge(clk);
        end procedure;

        procedure tick_once is
        begin
            tick_10ms <= '1';
            wait until rising_edge(clk);
            tick_10ms <= '0';
            wait until rising_edge(clk);
        end procedure;

    begin

        -- Reset inicial
        reset_pulse <= '1';
        wait for 50 ns;
        reset_pulse <= '0';
        wait for 50 ns;

        -- START: IDLE -> RUNNING
        pulse_signal(start_pulse);

        -- Simulamos varios ticks de 10 ms
        for i in 1 to 25 loop
            tick_once;
        end loop;

        wait for 100 ns;

        -- STOP: RUNNING -> SEND_REQ_STATE/SENDING/PAUSED
        pulse_signal(stop_pulse);

        -- Simulamos que UART se ocupa un momento
        uart_busy <= '1';
        wait for 100 ns;
        uart_busy <= '0';

        wait for 200 ns;

        -- START nuevamente: PAUSED -> RUNNING
        pulse_signal(start_pulse);

        for i in 1 to 10 loop
            tick_once;
        end loop;

        wait for 100 ns;

        -- RESET: cualquier estado -> IDLE
        pulse_signal(reset_pulse);

        wait for 300 ns;

        wait;
    end process;

end architecture;
