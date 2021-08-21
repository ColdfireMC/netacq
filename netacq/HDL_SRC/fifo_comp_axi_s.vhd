library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNIMACRO;
use UNIMACRO.VComponents.all;
library UNISIM;
use UNISIM.VComponents.all;

entity fifo_comp_axi_s is
    generic (ram_width : natural:=32);
port (i2clk             : in std_logic;
      ---fuentes de interrupción------
      almost_full_irq   : out std_logic;
      almost_empty_irq  : out std_logic;
      full_irq          : out std_logic;
      empty_irq         : out std_logic;
      -- input interface
      in_ready          : out std_logic;
      in_valid          : in std_logic;
      in_data           : in std_logic_vector(ram_width - 1 downto 0);
--      -- output interface
--      out_ready         : in std_logic;
--      out_valid         : out std_logic;
--      out_data          : out std_logic_vector(ram_width - 1 downto 0);
      --------------------- AXI-Stream-out-------------
      aclk              : in  std_logic;
      areset            : in  std_logic;
      tvalid            : out std_logic;
      tdata             : out std_logic_vector(7 downto 0);
      tready            : in  std_logic;
      tlast             : out std_logic;
      tuser             : out std_logic;  
      ---------------------------------------------------------
      hdr_tvalid        : out std_logic;
      hdr_tready        : in  std_logic      
      );
end fifo_comp_axi_s;

architecture Behavioral of fifo_comp_axi_s is

type  state_i_control_process    is (init, wait_1st,is_full, wait_others, valid_in, write_1, write_2);
signal icontrol_state, next_icontrol_state      :     state_i_control_process;

type  state_o_control_process    is (init, 
                                     wait_1st,
                                     is_empty, 
--                                     wait_others, 
                                     read_1, 
                                     read_2, 
--                                     read_3, 
                                     read_byte0, 
                                     read_byte1, 
                                     read_byte2, 
                                     read_byte3, 
                                     read_byte4, 
                                     read_byte5, 
                                     read_byte6, 
                                     read_byte7, 
                                     valid_out, 
                                     header_send, 
                                     header_wait);
signal ocontrol_state, next_ocontrol_state      :     state_o_control_process;

type  state_m_control_process    is (init1, init2, init3, init4, init5, init6 , wait_empty1, wait_empty2, wait_empty3, ready);
signal mcontrol_state, next_mcontrol_state      :     state_m_control_process;


signal level_count                                            : unsigned(15 downto 0);

signal reg_input_data, input_data                             : std_logic_vector(ram_width - 1 downto 0);
signal reg_output_data, output_data                           : std_logic_vector(ram_width - 1 downto 0);

signal reset_timer                                            : integer range 0 to 10;
constant reset_delay                                          : integer:= 7;

signal fifo_reset                                             : std_logic;
signal almost_empty, almost_full, empty_i, full_i             : std_logic;
signal fifo_read_error, fifo_write_error                      : std_logic;
signal fifo_write_enable, fifo_read_enable                    : std_logic;
signal logic_fifo_read_ptr, logic_fifo_write_ptr              : std_logic_vector(8 downto 0);

signal fifo_data_out, fifo_data_in                            : std_logic_vector(ram_width - 1 downto 0);

signal reset                                                  : std_logic;

attribute mark_debug : string;
attribute keep       : string;

--attribute mark_debug of fifo_write_enable : signal is "true";
--attribute mark_debug of fifo_read_enable : signal is "true";
--attribute mark_debug of logic_fifo_write_ptr : signal is "true";
--attribute mark_debug of logic_fifo_read_ptr: signal is "true";
--attribute mark_debug of almost_empty: signal is "true";
--attribute mark_debug of almost_full: signal is "true";
--attribute mark_debug of empty_i: signal is "true";
--attribute mark_debug of full_i: signal is "true";
--attribute mark_debug of fifo_read_error: signal is "true";
--attribute mark_debug of fifo_write_error: signal is "true";
--attribute mark_debug of in_valid : signal is "true";
--attribute mark_debug of out_valid : signal is "true";
--attribute mark_debug of in_data : signal is "true";
--attribute mark_debug of out_data : signal is "true";

begin

-- out_data<=reg_output_data;
fifo_data_in<=reg_input_data;

FIFO_SYNC_MACRO_inst :  FIFO_DUALCLOCK_MACRO
generic map (DEVICE => "7SERIES",            -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
   ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
   ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
   DATA_WIDTH => ram_width,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
   FIFO_SIZE => "36Kb")            -- Target BRAM, "18Kb" or "36Kb" 
port map (
   ALMOSTEMPTY   => almost_empty,   -- 1-bit output almost empty
   ALMOSTFULL    => almost_full,     -- 1-bit output almost full
   DO            => fifo_data_out,               -- Output data, width defined by DATA_WIDTH parameter
   EMPTY         => empty_i,               -- 1-bit output empty
   FULL          => full_i,                 -- 1-bit output full
   RDCOUNT       => logic_fifo_read_ptr,           -- Output read count, width determined by FIFO depth
   RDERR         => fifo_read_error,               -- 1-bit output read error
   WRCOUNT       => logic_fifo_write_ptr,           -- Output write count, width determined by FIFO depth
   WRERR         => fifo_write_error,               -- 1-bit output write error
   WRCLK         => i2clk,
   RDCLK         => aclk,                   -- 1-bit input clock
   DI            => fifo_data_in,                -- Input data, width defined by DATA_WIDTH parameter
   RDEN          => fifo_read_enable,                 -- 1-bit input read enable
   RST           => fifo_reset,                   -- 1-bit input reset
   WREN          => fifo_write_enable);                 -- 1-bit input write enable



input_data_register: process(i2clk, reset)
begin
    if reset='1' then
        reg_input_data <= 64B"0";
    elsif rising_edge(i2clk) then
        reg_input_data<=input_data;
    end if;
end process input_data_register;


--output_data_register: process(clock, reset)
--begin
--    if reset='1' then
--        reg_output_data <= 64B"0";
--    elsif rising_edge(clock) then
--        reg_output_data<=output_data;
--    end if;
--end process output_data_register;


o_state: process (aclk, reset)
begin
    if reset='1' then
        ocontrol_state<=init;
    elsif rising_edge(aclk) then
        ocontrol_state<=next_ocontrol_state;        
    end if;
end process o_state; 
i_state: process (i2clk, reset)
begin
    if reset='1' then
        icontrol_state<=init;
    elsif rising_edge(i2clk) then
        icontrol_state<=next_icontrol_state;        
    end if;
end process i_state;

m_state: process (i2clk, reset)
begin
    if reset='1' then
        mcontrol_state<=init1;
    elsif rising_edge(i2clk) then
        mcontrol_state<=next_mcontrol_state;        
    end if;
end process m_state;

m_control: process(all)
begin
    case mcontrol_state is
        when init1 =>
            fifo_reset          <='1';
            next_mcontrol_state<=init2;
        when init2 =>
            fifo_reset          <='1';
            next_mcontrol_state<=init3;
        when init3 =>
            fifo_reset          <='1';
            next_mcontrol_state<=init4;
        when init4 =>
            fifo_reset          <='1';
            next_mcontrol_state<=init5;
        when init5 =>
            fifo_reset          <='1';
            next_mcontrol_state<=init6;
        when init6 =>
            fifo_reset          <='1';
            next_mcontrol_state<=wait_empty1;
        when wait_empty1 =>    
            fifo_reset          <='0';
            next_mcontrol_state<=wait_empty2;
        when wait_empty2 =>     
            fifo_reset          <='0';
            next_mcontrol_state<=wait_empty3;
        when wait_empty3 =>     
            fifo_reset          <='0';
            next_mcontrol_state<=ready;
        when ready    => 
            fifo_reset          <='0';
            next_mcontrol_state<=ready;
    end case;

end process m_control;
  
icontrol: process(all)
begin
    case icontrol_state is
        when init           =>
        
            in_ready   <= '0';

            fifo_write_enable<='0';
            
            input_data          <= reg_input_data;
            
            if mcontrol_state/= ready then
                next_icontrol_state<=init;
            else
                next_icontrol_state<=wait_1st;   
            end if;    
 
        when wait_1st       =>
        
            in_ready   <= '1';
            
            input_data          <= reg_input_data;

            fifo_write_enable<='0';
              
            if in_valid ='1' then
                next_icontrol_state<=valid_in;
            else 
                next_icontrol_state<=wait_1st;
            end if;
        when is_full    =>
            in_ready   <= '0';
            
            input_data          <= reg_input_data;
            
            fifo_write_enable<='0';
            
            if almost_full='0' then
                next_icontrol_state<=wait_1st;
            else 
                next_icontrol_state<=is_full;
            end if;        
        when wait_others       =>
            
           in_ready   <= '0';
           
           input_data          <= in_data;
    
           fifo_write_enable<='0';
             
           if (in_valid and (not almost_full))='1' then
               next_icontrol_state<=wait_1st;
           else 
               next_icontrol_state<=wait_others;
           end if;                             
        when valid_in    =>
            in_ready   <= '1';
            
            input_data          <= in_data;
            
            fifo_write_enable<='0';
            
            next_icontrol_state<=write_1;

        when write_1         =>
            in_ready   <= '0';
        
            input_data          <= reg_input_data;
            
            fifo_write_enable<='1';            
            
            next_icontrol_state<=write_2;

        when write_2         =>
            in_ready   <= '0';

            input_data          <= reg_input_data;
            
            fifo_write_enable<='0';            

            next_icontrol_state<=is_full;
          
        end case;     
end process icontrol;

ocontrol: process(all)
begin
    case ocontrol_state is
        when init           =>
        
            tvalid  <= '0';
            
            fifo_read_enable<='0';
            
            tdata         <= 8x"0";
            
            tlast         <= '0';
            
            hdr_tvalid     <=  '0';
            
            if mcontrol_state/= ready then
                next_ocontrol_state<=init;
            else
                next_ocontrol_state<=is_empty;   
            end if;    
 
        when wait_1st       =>
        
            tvalid  <= '0';
            
            tdata         <= 8x"0"; 

            fifo_read_enable<='0';
            
            tlast         <= '0';
            
            hdr_tvalid     <=  '0';
            
            if hdr_tready='1' then
                next_ocontrol_state<=header_send;
            else 
                next_ocontrol_state<=wait_1st;
            end if;
        when is_empty    =>
  
            tvalid  <= '0';
        
            tdata         <=8x"0"; 
  
            fifo_read_enable<='0';
            
            tlast         <= '0';
            
            hdr_tvalid     <=  '0';
        
            if (empty_i)='1' then
                hdr_tvalid     <=  '0';
               next_ocontrol_state<=is_empty;
            elsif hdr_tready='1' then
                hdr_tvalid     <=  '1';
                next_ocontrol_state<=header_wait;
            else
                hdr_tvalid     <=  '0';
                next_ocontrol_state<=wait_1st;
            end if;

        when valid_out    =>

            tvalid  <= '0';
            tdata         <= 8x"0";

            fifo_read_enable<='0';
            
            tlast         <= '0';
            
            hdr_tvalid     <=  '0';

            next_ocontrol_state<=is_empty;          

         when header_send=>
            
            tvalid         <=  '0';
            tlast          <=  '0';
            
            fifo_read_enable<='0';
            
            hdr_tvalid     <=  '1';  
            
            tdata         <= 8x"0";
                                                           
            
            next_ocontrol_state<=header_wait;
                                     
         when header_wait=>
            
            tvalid         <=  '0';
            tlast          <=  '0';
            
            fifo_read_enable<='0';
            
            hdr_tvalid     <=  '0';  
            
            tdata         <= 8x"0";
                              
            
            if tready='1' then
                next_ocontrol_state<=read_1;
            else
                next_ocontrol_state<=header_wait;
            end if;
        
        when read_1   =>
            tvalid  <= '0';
        
            fifo_read_enable<='1';
            
            tlast         <= '0'; 

            tdata         <= 8x"0";
            
            hdr_tvalid     <=  '0';     

            next_ocontrol_state<=read_2;
        
        when read_2   => ----------latencia, ver Xilinx ug473, FIFO OPERATIONS

            tvalid  <= '0';
        
            fifo_read_enable<='0';
        
            tdata         <= 8x"0";
            
            hdr_tvalid     <=  '0';
            
            tlast         <= '0';
            
            next_ocontrol_state<=read_byte0;    
        when read_byte0   =>
        
           tvalid  <= '1';
       
           fifo_read_enable<='0'; 
       
           tdata         <= fifo_data_out(63 downto 56) ;
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '0';       

           next_ocontrol_state<=read_byte1; 
        when read_byte1   =>
           
           tvalid  <= '1';
          
           fifo_read_enable<='0'; 
          
           tdata         <= fifo_data_out(55 downto 48);
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '0';       
   
           next_ocontrol_state<=read_byte2;
        when read_byte2   =>
              
           tvalid  <= '1';
           
           fifo_read_enable<='0'; 
           
           tdata         <= fifo_data_out(47 downto 40);
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '0';       
      
           next_ocontrol_state<=read_byte3;
            
        when read_byte3   =>
           
           tvalid  <= '1';
           
           fifo_read_enable<='0'; 
           
           tdata         <= fifo_data_out(39 downto 32);
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '0';       
         
           next_ocontrol_state<=read_byte4;
              
        when read_byte4   =>
                    
           tvalid  <= '1';
           
           fifo_read_enable<='0'; 
           
           tdata         <= fifo_data_out(31 downto 24);
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '0';       
           
           next_ocontrol_state<=read_byte5;

        when read_byte5   =>
                       
           tvalid  <= '1';
           
           fifo_read_enable<='0'; 
           
           tdata         <= fifo_data_out(23 downto 16);
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '0';       
           
           next_ocontrol_state<=read_byte6;
                          
                          
        when read_byte6   =>
                          
           tvalid  <= '1';
           
           fifo_read_enable<='0'; 
           
           tdata         <= fifo_data_out(15 downto 8);
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '0';       
           
           next_ocontrol_state<=read_byte7;                          

        when read_byte7   =>
                             
           tvalid  <= '1';
           
           fifo_read_enable<='0'; 
           
           tdata         <= fifo_data_out(7 downto 0);
           
           hdr_tvalid     <=  '0';
           
           tlast         <= '1';       
           
           next_ocontrol_state<=valid_out;               
        end case;     
end process ocontrol;

reset<=areset;
end Behavioral;