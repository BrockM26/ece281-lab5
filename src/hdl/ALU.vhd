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
--+----------------------------------------------------------------------------
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
-- TODO
    port(
        i_A: in std_logic_vector(7 downto 0);
        i_B: in std_logic_vector(7 downto 0);
        i_op: in std_logic_vector(2 downto 0);
        o_result: out std_logic_vector(7 downto 0);
        o_flags: out std_logic_vector(2 downto 0)
    );
end ALU;

architecture behavioral of ALU is 
  
	-- declare components and signals
  

    signal w_Cout: std_logic;
    signal w_add : std_logic_vector(7 downto 0);
    signal w_diff : std_logic_vector(7 downto 0);
    signal w_rightshift : std_logic_vector(7 downto 0);
    signal w_leftshift : std_logic_vector(7 downto 0);
    signal w_shift : std_logic_vector(7 downto 0);
    signal w_result : std_logic_vector(7 downto 0);
    signal w_and : std_logic_vector(7 downto 0);
    signal w_or : std_logic_vector(7 downto 0);
    
begin
	-- PORT MAPS ----------------------------------------
	
	-- CONCURRENT STATEMENTS ----------------------------
    w_shift <= w_rightshift when i_op = "000" else
               w_leftshift;
               
    w_rightshift <= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
    
    w_leftshift <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
    
    w_add <= std_logic_vector(unsigned(i_A) + unsigned(i_B));
             
    w_diff <= std_logic_vector(unsigned(i_A) - unsigned(i_B));
    
    w_and <= i_A and i_B;
    w_or <= i_A or i_B;
    
    w_result <= w_add when (i_op =  "000") else
                w_and when (i_op = "001") else
                w_or when (i_op = "100") else
                w_shift when (i_op = "110");
                
	o_flags(2) <= '1' when w_result(7) = '1';
	o_flags(1) <= '1' when w_result = "00000000";
	o_flags(0) <= w_Cout;
	
	o_result <= w_result;
	
end behavioral;
