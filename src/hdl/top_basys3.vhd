--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|

--| DOCUMENTATION STATEMENT: C2C Cho, C3C Culp, C3C Leong, C3C Morales
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
    port(
    -- inputs
    clk     :   in std_logic; -- native 100MHz FPGA clock
    sw      :   in std_logic_vector(7 downto 0);
    btnU    :   in std_logic;
    btnC    :   in std_logic;
    
    -- outputs
    led :   out std_logic_vector(15 downto 0);
    -- 7-segment display segments (active-low cathodes)
    seg :   out std_logic_vector(6 downto 0);
    
    an :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component regA is
        port ( i_D1   : in  STD_LOGIC_VECTOR(7 downto 0);
               i_adv  : in STD_LOGIC;
               o_Q1   : out STD_LOGIC_VECTOR (7 downto 0)           
             );
    end component regA;
    
    component regB is
        port ( i_D2   : in  STD_LOGIC_VECTOR(7 downto 0);
               i_adv  : in STD_LOGIC;
               o_Q2   : out STD_LOGIC_VECTOR (7 downto 0)           
             );
    end component regB;
    
    component elevator_controller_fsm is
        port ( i_reset   : in  STD_LOGIC;
               i_adv     : in  STD_LOGIC;
               i_clk     : in  STD_LOGIC;
               o_cycle   : out STD_LOGIC_VECTOR (3 downto 0)           
             );
    end component elevator_controller_fsm;


    component sevenSegDecoder is
      port (
          i_D : in std_logic_vector(3 downto 0);
          o_S : out std_logic_vector(6 downto 0)
          );
    end component sevenSegDecoder;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        port ( i_clk        : in  STD_LOGIC;
               i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data        : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel        : out STD_LOGIC_VECTOR (3 downto 0)
        );
     end component TDM4;
        
    component clock_divider is
        generic ( constant k_DIV : natural := 2    );
        port (  i_clk    : in std_logic;           
                o_clk    : out std_logic          
        );
    end component clock_divider;
    
    component twoscomp_decimal is
    port (
        i_binary: in std_logic_vector(7 downto 0);
        o_negative: out std_logic;
        o_hundreds: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twoscomp_decimal;
    
    component ALU is
    port (
        i_A: in std_logic_vector(7 downto 0);
        i_B: in std_logic_vector(7 downto 0);
        i_op: in std_logic_vector(2 downto 0);
        o_result: out std_logic_vector(7 downto 0);
        o_flags: out std_logic_vector(2 downto 0)
    );
    end component ALU;
    
    signal w_clk: std_logic;
    signal w_A: std_logic_vector(7 downto 0);
    signal w_B: std_logic_vector(7 downto 0);
    signal w_cycle: std_logic_vector(3 downto 0);
    signal w_result: std_logic_vector(7 downto 0);
    signal w_Y: std_logic_vector(7 downto 0);
    signal w_neg: std_logic;
    signal w_sign: std_logic_vector(3 downto 0);
    signal w_hund: std_logic_vector(3 downto 0);
    signal w_tens: std_logic_vector(3 downto 0);
    signal w_ones: std_logic_vector(3 downto 0);
    signal w_data: std_logic_vector(3 downto 0);
    signal w_sel: std_logic_vector(3 downto 0);

begin
	-- PORT MAPS ----------------------------------------
    regA_inst: regA
        port map(  
           i_D1 => sw(7 downto 0),
           i_adv => btnC,
           o_Q1 => w_A        
     );
    
    regB_inst: regB
         port map(  
            i_D2 => sw(7 downto 0),
            i_adv => btnC,
            o_Q2 => w_B      
      );
    
    elevator_controller_fsm_inst: elevator_controller_fsm
        port map(
            i_reset => btnU,
            i_adv => btnC,
            i_clk => w_clk,
            o_cycle => w_cycle
        );
        
    sevenSegDecoder_inst: sevenSegDecoder
            port map(
                i_D => w_data,
                o_S => seg
            );
            
    clock_divider_inst: clock_divider 
            generic map ( k_DIV => 250000 )
            port map(
                i_clk => clk,
                o_clk => w_clk
            );
            
    TDM4_inst: TDM4
            port map(
                i_clk => w_clk,
                i_D3 => w_sign,
                i_D2 => w_hund,
                i_D1 => w_tens,
                i_D0 => w_ones,
                o_data => w_data,
                o_sel => an
            );
          
            
    twoscomp_decimal_inst: twoscomp_decimal
            port map(
                i_binary => w_Y,
                o_negative => w_neg,
                o_hundreds => w_hund,
                o_tens => w_tens,
                o_ones => w_ones
            );
            
    w_sign <= x"A" when (w_neg = '1') 
              else x"B";
            
    ALU_inst: ALU
            port map(
                i_A => w_A,
                i_B => w_B,
                i_op(0) => sw(0),
                i_op(1) => sw(1),
                i_op(2) => sw(2),
                o_flags => led(15 downto 13),
                o_result => w_result
            );
    
	w_Y <= w_A when (w_cycle = "0010") else
              w_B when (w_cycle = "0100") else
              w_result when (w_cycle = "1000") else
              "00000000";
	
	-- CONCURRENT STATEMENTS ----------------------------
	led(3 downto 0) <= w_cycle;
	an(3 downto 0) <= w_sel;
	
end top_basys3_arch;
