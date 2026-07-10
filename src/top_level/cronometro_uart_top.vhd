library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cronometro_uart_top is
    port (
        clk       : in  std_logic;

        btn_start : in  std_logic;
        btn_stop  : in  std_logic;
        btn_reset : in  std_logic;
        btn_send  : in  std_logic;

        tx_line   : out std_logic;

        an        : out std_logic_vector(3 downto 0);
        seg       : out std_logic_vector(6 downto 0);
        dp        : out std_logic;

        led       : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of cronometro_uart_top is

    signal tick_10ms : std_logic;
    signal tick_1ms  : std_logic;

    signal start_pulse : std_logic;
    signal stop_pulse  : std_logic;
    signal reset_pulse : std_logic;
    signal send_pulse  : std_logic;

    signal enable_count : std_logic;
    signal reset_count  : std_logic;
    signal send_req     : std_logic;
    signal state_code   : std_logic_vector(2 downto 0);

    signal digit0 : std_logic_vector(3 downto 0);
    signal digit1 : std_logic_vector(3 downto 0);
    signal digit2 : std_logic_vector(3 downto 0);
    signal digit3 : std_logic_vector(3 downto 0);

    signal time_zero : std_logic;
    signal overflow  : std_logic;

    signal uart_tx_start : std_logic;
    signal uart_tx_data  : std_logic_vector(7 downto 0);
    signal uart_tx_busy  : std_logic;
    signal sender_busy   : std_logic;

    signal chrono_reset : std_logic;

begin

    chrono_reset <= reset_pulse or reset_count;

    U_CLK_DIV : entity work.clk_divider
        generic map (
            CLK_FREQ => 100_000_000
        )
        port map (
            clk        => clk,
            tick_10ms  => tick_10ms,
            tick_1ms   => tick_1ms
        );

    U_DEB_START : entity work.debounce_onepulse
        port map (
            clk       => clk,
            btn_in    => btn_start,
            btn_level => open,
            btn_pulse => start_pulse
        );

    U_DEB_STOP : entity work.debounce_onepulse
        port map (
            clk       => clk,
            btn_in    => btn_stop,
            btn_level => open,
            btn_pulse => stop_pulse
        );

    U_DEB_RESET : entity work.debounce_onepulse
        port map (
            clk       => clk,
            btn_in    => btn_reset,
            btn_level => open,
            btn_pulse => reset_pulse
        );

    U_DEB_SEND : entity work.debounce_onepulse
        port map (
            clk       => clk,
            btn_in    => btn_send,
            btn_level => open,
            btn_pulse => send_pulse
        );

    U_CONTROL : entity work.control_fsm
        port map (
            clk          => clk,
            rst          => reset_pulse,

            start_pulse  => start_pulse,
            stop_pulse   => stop_pulse,
            send_pulse   => send_pulse,

            uart_busy    => sender_busy,

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

            zero       => time_zero,
            overflow   => overflow
        );

    U_DISPLAY : entity work.seven_segment_driver
        port map (
            clk          => clk,
            tick_refresh => tick_1ms,

            digit0       => digit0,
            digit1       => digit1,
            digit2       => digit2,
            digit3       => digit3,

            an           => an,
            seg          => seg,
            dp           => dp
        );

    U_UART_SENDER : entity work.uart_time_sender
        port map (
            clk      => clk,
            rst      => reset_pulse,

            send_req => send_req,

            digit0   => digit0,
            digit1   => digit1,
            digit2   => digit2,
            digit3   => digit3,

            tx_busy  => uart_tx_busy,
            tx_start => uart_tx_start,
            tx_data  => uart_tx_data,

            busy     => sender_busy
        );

    U_UART_TX : entity work.uart_tx
        generic map (
            CLK_FREQ  => 100_000_000,
            BAUD_RATE => 9600
        )
        port map (
            clk      => clk,
            tx_start => uart_tx_start,
            tx_data  => uart_tx_data,

            tx_line  => tx_line,
            tx_busy  => uart_tx_busy
        );

    process(enable_count, state_code, sender_busy, uart_tx_busy, time_zero, overflow)
        variable leds_v : std_logic_vector(15 downto 0);
    begin
        leds_v := (others => '0');

        leds_v(0) := enable_count;

        if state_code = "010" then
            leds_v(1) := '1';
        end if;

        leds_v(2) := sender_busy or uart_tx_busy;
        leds_v(3) := time_zero;
        leds_v(15) := overflow;

        led <= leds_v;
    end process;

end architecture;
