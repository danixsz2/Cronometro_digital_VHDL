library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        CLK_FREQ  : integer := 100_000_000;
        BAUD_RATE : integer := 9600
    );
    port (
        clk      : in  std_logic;
        tx_start : in  std_logic;
        tx_data  : in  std_logic_vector(7 downto 0);

        tx_line  : out std_logic;
        tx_busy  : out std_logic
    );
end entity;

architecture rtl of uart_tx is

    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    );

    signal state      : state_type := IDLE;
    signal baud_count : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index  : integer range 0 to 7 := 0;

    signal tx_shift : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_r     : std_logic := '1';
    signal busy_r   : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            case state is

                when IDLE =>
                    tx_r <= '1';
                    busy_r <= '0';
                    baud_count <= 0;
                    bit_index <= 0;

                    if tx_start = '1' then
                        tx_shift <= tx_data;
                        busy_r <= '1';
                        tx_r <= '0';
                        state <= START_BIT;
                    end if;

                when START_BIT =>
                    busy_r <= '1';
                    tx_r <= '0';

                    if baud_count = CLKS_PER_BIT - 1 then
                        baud_count <= 0;
                        state <= DATA_BITS;
                    else
                        baud_count <= baud_count + 1;
                    end if;

                when DATA_BITS =>
                    busy_r <= '1';
                    tx_r <= tx_shift(bit_index);

                    if baud_count = CLKS_PER_BIT - 1 then
                        baud_count <= 0;

                        if bit_index = 7 then
                            bit_index <= 0;
                            state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        baud_count <= baud_count + 1;
                    end if;

                when STOP_BIT =>
                    busy_r <= '1';
                    tx_r <= '1';

                    if baud_count = CLKS_PER_BIT - 1 then
                        baud_count <= 0;
                        busy_r <= '0';
                        state <= IDLE;
                    else
                        baud_count <= baud_count + 1;
                    end if;

            end case;
        end if;
    end process;

    tx_line <= tx_r;
    tx_busy <= busy_r;

end architecture;
