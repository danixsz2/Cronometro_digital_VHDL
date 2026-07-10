library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control_fsm is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        start_pulse : in  std_logic;
        stop_pulse  : in  std_logic;
        send_pulse  : in  std_logic;

        uart_busy   : in  std_logic;

        enable_count : out std_logic;
        reset_count  : out std_logic;
        send_req     : out std_logic;
        state_code   : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of control_fsm is

    type state_type is (
        IDLE,
        RUNNING,
        PAUSED,
        SEND_REQ_STATE,
        SENDING
    );

    signal state : state_type := IDLE;

    signal reset_count_r : std_logic := '0';
    signal send_req_r    : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            reset_count_r <= '0';
            send_req_r    <= '0';

            if rst = '1' then
                state <= IDLE;
                reset_count_r <= '1';
            else
                case state is

                    when IDLE =>
                        if start_pulse = '1' then
                            state <= RUNNING;
                        elsif send_pulse = '1' and uart_busy = '0' then
                            state <= SEND_REQ_STATE;
                        end if;

                    when RUNNING =>
                        if stop_pulse = '1' then
                            state <= SEND_REQ_STATE;
                        end if;

                    when PAUSED =>
                        if start_pulse = '1' then
                            state <= RUNNING;
                        elsif send_pulse = '1' and uart_busy = '0' then
                            state <= SEND_REQ_STATE;
                        end if;

                    when SEND_REQ_STATE =>
                        if uart_busy = '0' then
                            send_req_r <= '1';
                            state <= SENDING;
                        end if;

                    when SENDING =>
                        if uart_busy = '0' then
                            state <= PAUSED;
                        end if;

                end case;
            end if;
        end if;
    end process;

    enable_count <= '1' when state = RUNNING else '0';
    reset_count  <= reset_count_r;
    send_req     <= send_req_r;

    with state select
        state_code <= "000" when IDLE,
                      "001" when RUNNING,
                      "010" when PAUSED,
                      "011" when SEND_REQ_STATE,
                      "100" when SENDING;

end architecture;
