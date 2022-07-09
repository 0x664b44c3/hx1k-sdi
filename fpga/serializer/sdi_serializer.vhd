library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use ice40.all;
--use	work.std_logic_SBT.all;

entity sdi_serializer is
Port (
    reset : in std_logic;
    data: in  STD_LOGIC_VECTOR(9 downto 0);
    clk_27M : in std_logic; -- word clock
    clk_135M : in std_logic; -- serializer bit clock/2
    dp : inout std_logic; --sdi differential out p
    dn : inout std_logic --sdi differential out n
);
end sdi_serializer;


architecture Behavioral of sdi_serializer IS

--INPUT SYNC
signal in_reg : std_logic_vector(9 downto 0) := "1111100000";

-- sdi encoded word
signal sdi_data: std_logic_vector(9 downto 0) :=   "1110010010";

-- registered sdi word
signal sdi_data_reg: std_logic_vector(9 downto 0) := "1110010010";

--sdi word in the highspeed domain
signal sdi_data_q: std_logic_vector(9 downto 0) := "1110010010";

--serializer word (output bits coe from here)
signal serializer_word : std_logic_vector(9 downto 0) := "1111100000";

--actual bits
signal ser_d0 : std_logic;
signal ser_d1 : std_logic;

--bits, registered
signal ser_q0 : std_logic;
signal ser_q1 : std_logic;
signal ser_q0r: std_logic;

signal ser_q1n : std_logic;
signal ser_q0nr: std_logic;

--curretn output data and negated data
signal sdo: std_logic;
signal sdo_n: std_logic;

--latched clock, synchronized to ck135M
signal int_ck27 : std_logic := '0';


type serStates is (
   s_init,
   s_sync0,
   s_bits0,
   s_bits1,
   s_bits2,
   s_bits3,
   s_bits4
);

signal serializer_state : serStates;

--smpte/nrzi encoder core
component sdi_encoder IS
    port (
        clk:        in  std_logic;      -- word rate clock (74.25 MHz)
        rst:        in  std_logic;      -- async reset
        nrzi:       in  std_logic;      -- 1 enables NRZ-to-NRZI conversion
        scram:      in  std_logic;      -- 1 enables SDI scrambler
        d:          in  std_logic_vector(9 downto 0);  -- Y channel input data port
        q:          out std_logic_vector(9 downto 0)); -- output data port
end COMPONENT;


component SB_GB
port (
		GLOBAL_BUFFER_OUTPUT			:	out	std_logic;
		USER_SIGNAL_TO_GLOBAL_BUFFER	:	in	std_logic
);
end component;

COMPONENT SB_IO is

	generic (
			NEG_TRIGGER : bit;
			PIN_TYPE	: bit_vector (5 downto 0);
			PULLUP		: bit;
			IO_STANDARD	: string
			);
	port
		(
		D_OUT_1      : in std_logic;
		D_OUT_0      : in std_logic;
		CLOCK_ENABLE : in std_logic;
		LATCH_INPUT_VALUE : in std_logic;
		INPUT_CLK    : in std_logic;

		D_IN_1 : out std_logic;
		D_IN_0 : out std_logic;
		OUTPUT_ENABLE : in std_logic;
		OUTPUT_CLK : in std_logic;
		PACKAGE_PIN : inout	std_ulogic
		);

end COMPONENT;

BEGIN


encoder: sdi_encoder
PORT MAP (
    clk => clk_27M,
    rst => reset,
    nrzi =>'1',
    scram => '1',
    d => in_reg,
    q => sdi_data
);

process (clk_135M, reset)
BEGIN

if (falling_edge(clk_135M)) THEN
    ser_q0r <= ser_q0;
    ser_q0nr <= NOT ser_q0;
END IF;

if (reset='1') then
    ser_q0 <= '0';
    ser_q1 <= '1';
    ser_q1n <='0';
    serializer_state <= s_init;

else

    if (rising_edge(clk_135M)) THEN
        --load current slow clock
        int_ck27 <= clk_27M;
        -- latch output bits
        ser_q0 <= ser_d0;
        ser_q1 <= ser_d1;
        ser_q1n <= NOT ser_d1;

        CASE serializer_state is
        WHEN s_init =>
            if (int_ck27 = '0') then
                serializer_state <= s_sync0;
            end if;

        WHEN s_sync0 =>
            if (int_ck27 = '1') then
                serializer_state <= s_bits0;
            end if;

        when s_bits0 =>

            --latch next dataword
            sdi_data_q <= sdi_data_reg;
            --check for clock out of sync
            if (int_ck27 = '0') THEN
                serializer_state <= s_sync0;
            end if;

            ser_d1 <= serializer_word(0);
            ser_d0 <= serializer_word(1);

            serializer_state <= s_bits1;


        when s_bits1 =>
            ser_d1 <= serializer_word(2);
            ser_d0 <= serializer_word(3);

            serializer_state <= s_bits2;

        when s_bits2 =>
            ser_d1 <= serializer_word(4);
            ser_d0 <= serializer_word(5);

            serializer_state <= s_bits3;

        when s_bits3 =>
            ser_d1 <= serializer_word(6);
            ser_d0 <= serializer_word(7);

            serializer_state <= s_bits4;

        when s_bits4 =>
            ser_d1 <= serializer_word(8);
            ser_d0 <= serializer_word(9);

            --load latched dataword into serializer registers
            serializer_word <= sdi_data_q;

            serializer_state <= s_bits0;

        when others =>
            serializer_state <= s_init;

        end case;
        END IF; --clock
end if;

END PROCESS;


PROCESS(clk_27M)
BEGIN
if rising_edge(clk_27M) then
    in_reg<=data;
end if;
if falling_edge(clk_27M) then
    sdi_data_reg <= sdi_data;
end if;
end process;

--generic out impl (jitter from hell)
--dp <= ser_q1 when (clk_135M = '1') ELSE ser_q0r;
--dn <= ser_q1n when (clk_135M = '1') ELSE ser_q0nr;

--
data_p : SB_IO
GENERIC MAP (
    NEG_TRIGGER => '0',
    PIN_TYPE => "010000",
    PULLUP => '0',
    IO_STANDARD => "SB_LVCMOS"
) PORT MAP (
    LATCH_INPUT_VALUE => '0',
    CLOCK_ENABLE => '1',
    INPUT_CLK => '0',
    OUTPUT_CLK  =>  clk_135M,
    PACKAGE_PIN => dp,
    OUTPUT_ENABLE => '1',
    D_OUT_0 => ser_q0r,
    D_OUT_1 => ser_q1
);


data_n : SB_IO
GENERIC MAP (
    NEG_TRIGGER => '0',
    PIN_TYPE => "010000",
    PULLUP => '0',
    IO_STANDARD => "SB_LVCMOS"
) PORT MAP (
    LATCH_INPUT_VALUE => '0',
    CLOCK_ENABLE => '1',
    INPUT_CLK => '0',
    OUTPUT_CLK  => clk_135M,
    PACKAGE_PIN => dn,
    OUTPUT_ENABLE => '1',
    D_OUT_0 => ser_q0nr,
    D_OUT_1 => ser_q1n

);



end Behavioral;


