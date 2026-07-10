library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart is
end entity;

architecture sim of tb_uart is

    constant CLK_PERIOD : time := 10 ns;

    -- UART acelerado para simulación:
    -- CLK_FREQ / BAUD_RATE = 100_000_000 / 10_000_000 = 10 ciclos por bit
    constant CLK_FREQ_SIM  : integer := 100_000_000;
    constant BAUD_RATE_SIM : integer := 10_000_000;

    constant BIT_PERIOD      : time := 100 ns;
    constant HALF_BIT_PERIOD : time := 50 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal send_req : std_logic := '0';

    -- Tiempo fijo a transmitir: 12.34 s
    signal digit0 : std_logic_vector(3 downto 0) := "0100"; -- 4
    signal digit1 : std_logic_vector(3 downto 0) := "0011"; -- 3
    signal digit2 : std_logic_vector(3 downto 0) := "0010"; -- 2
    signal digit3 : std_logic_vector(3 downto 0) := "0001"; -- 1

    signal tx_busy  : std_logic;
    signal tx_start : std_logic;
    signal tx_data  : std_logic_vector(7 downto 0);

    signal sender_busy : std_logic;
    signal tx_line     : std_logic;

    -- Señales auxiliares para ver mejor la simulación
    signal tx_data_seen  : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_char_count : integer range 0 to 20 := 0;

    -- Monitor UART interno para reconstruir bytes desde tx_line
    signal rx_byte  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid : std_logic := '0';
    signal rx_count : integer range 0 to 20 := 0;

begin

    clk <= not clk after CLK_PERIOD / 2;

    U_UART_SENDER : entity work.uart_time_sender
        port map (
            clk      => clk,
            rst      => rst,

            send_req => send_req,

            digit0   => digit0,
            digit1   => digit1,
            digit2   => digit2,
            digit3   => digit3,

            tx_busy  => tx_busy,
            tx_start => tx_start,
            tx_data  => tx_data,

            busy     => sender_busy
        );

    U_UART_TX : entity work.uart_tx
        generic map (
            CLK_FREQ  => CLK_FREQ_SIM,
            BAUD_RATE => BAUD_RATE_SIM
        )
        port map (
            clk      => clk,
            tx_start => tx_start,
            tx_data  => tx_data,

            tx_line  => tx_line,
            tx_busy  => tx_busy
        );

    -- Captura cada byte entregado por uart_time_sender a uart_tx
    capture_tx_data : process(clk)
    begin
        if rising_edge(clk) then
            if tx_start = '1' then
                tx_data_seen <= tx_data;
                tx_char_count <= tx_char_count + 1;
            end if;
        end if;
    end process;

    -- Monitor simple de UART para reconstruir lo que sale por tx_line
    uart_rx_monitor : process
        variable data_v : std_logic_vector(7 downto 0);
    begin
        wait for 100 ns;

        loop
            -- Detecta bit de inicio
            wait until tx_line = '0';

            -- Espera hasta el centro del primer bit de dato
            wait for BIT_PERIOD + HALF_BIT_PERIOD;

            -- Lee los 8 bits de datos
            for i in 0 to 7 loop
                data_v(i) := tx_line;
                wait for BIT_PERIOD;
            end loop;

            rx_byte <= data_v;
            rx_valid <= '1';
            rx_count <= rx_count + 1;

            wait until rising_edge(clk);
            rx_valid <= '0';

            -- Espera parte del bit de parada
            wait for HALF_BIT_PERIOD;
        end loop;
    end process;

    stim_proc : process
    begin

        -- Reset inicial
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        -- Solicitar envío UART
        send_req <= '1';
        wait until rising_edge(clk);
        send_req <= '0';

        -- Tiempo suficiente para transmitir TIME=12.34s + salto de línea
        wait for 20 us;

        wait;
    end process;

end architecture;
