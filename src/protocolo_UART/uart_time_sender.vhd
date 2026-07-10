library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_time_sender is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;

        send_req : in  std_logic;

        digit0   : in  std_logic_vector(3 downto 0);
        digit1   : in  std_logic_vector(3 downto 0);
        digit2   : in  std_logic_vector(3 downto 0);
        digit3   : in  std_logic_vector(3 downto 0);

        tx_busy  : in  std_logic;
        tx_start : out std_logic;
        tx_data  : out std_logic_vector(7 downto 0);

        busy     : out std_logic
    );
end entity;

architecture rtl of uart_time_sender is

    constant MSG_LEN : integer := 12;

    type state_type is (
        IDLE,
        SEND_CHAR,
        WAIT_BUSY_HIGH,
        WAIT_BUSY_LOW
    );

    signal state : state_type := IDLE;
    signal index : integer range 0 to MSG_LEN - 1 := 0;

    signal tx_start_r : std_logic := '0';
    signal tx_data_r  : std_logic_vector(7 downto 0) := (others => '0');
    signal busy_r     : std_logic := '0';

    function ascii_digit(d : std_logic_vector(3 downto 0))
        return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(48 + to_integer(unsigned(d)), 8));
    end function;

    function get_char(
        i  : integer;
        d3 : std_logic_vector(3 downto 0);
        d2 : std_logic_vector(3 downto 0);
        d1 : std_logic_vector(3 downto 0);
        d0 : std_logic_vector(3 downto 0)
    ) return std_logic_vector is
    begin
        case i is
            when 0  => return x"54"; -- T
            when 1  => return x"49"; -- I
            when 2  => return x"4D"; -- M
            when 3  => return x"45"; -- E
            when 4  => return x"3D"; -- =
            when 5  => return ascii_digit(d3);
            when 6  => return ascii_digit(d2);
            when 7  => return x"2E"; -- .
            when 8  => return ascii_digit(d1);
            when 9  => return ascii_digit(d0);
            when 10 => return x"73"; -- s
            when others => return x"0A"; -- salto de línea
        end case;
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            tx_start_r <= '0';

            if rst = '1' then
                state <= IDLE;
                index <= 0;
                busy_r <= '0';
                tx_start_r <= '0';
                tx_data_r <= (others => '0');
            else
                case state is

                    when IDLE =>
                        busy_r <= '0';

                        if send_req = '1' then
                            index <= 0;
                            busy_r <= '1';
                            state <= SEND_CHAR;
                        end if;

                    when SEND_CHAR =>
                        busy_r <= '1';

                        if tx_busy = '0' then
                            tx_data_r <= get_char(index, digit3, digit2, digit1, digit0);
                            tx_start_r <= '1';
                            state <= WAIT_BUSY_HIGH;
                        end if;

                    when WAIT_BUSY_HIGH =>
                        busy_r <= '1';

                        if tx_busy = '1' then
                            state <= WAIT_BUSY_LOW;
                        end if;

                    when WAIT_BUSY_LOW =>
                        busy_r <= '1';

                        if tx_busy = '0' then
                            if index = MSG_LEN - 1 then
                                busy_r <= '0';
                                state <= IDLE;
                            else
                                index <= index + 1;
                                state <= SEND_CHAR;
                            end if;
                        end if;

                end case;
            end if;
        end if;
    end process;

    tx_start <= tx_start_r;
    tx_data  <= tx_data_r;
    busy     <= busy_r;

end architecture;
