----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.10.2020 12:50:18
-- Design Name: 
-- Module Name: udp_dummy - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
library xil_defaultlib;
use xil_defaultlib.CHAR82STD.all;

entity string_gen_4 is
  Port (------------------ input interface--------------------
        in_ready                      : out std_logic;
        in_valid                      : in  std_logic;
        in_data                       : in  std_logic_vector(63 downto 0);
       ---------------------------header ctl interface--------------------       
        hdr_tvalid                    : out std_logic;
        hdr_tready                    : in  std_logic;
       --------------------- AXI-Stream-data-out-------------
        aclk                          : in  std_logic;
        areset                        : in  std_logic;
        tvalid                        : out std_logic;
        tdata                         : out std_logic_vector(7 downto 0);
        tready                        : in  std_logic;
        tlast                         : out std_logic;
        tuser                         : out std_logic);
end string_gen_4;

architecture Behavioral of string_gen_4 is




type control is (init,
                 wait_input,
                 wait_ready,
                 valid_input,
                 header_set,
                 process_input_start,
                 process_input_send,
                 process_input_wait,
                 process_header_send,
                 process_header_wait,
                 string_start,
                 string_complete,
                 header_complete,
                 wait_next);
type  state_m_control_process    is (init1, init2, init3, init4, init5, init6 , wait_empty1, wait_empty2, wait_empty3, ready);
signal mcontrol_state, next_mcontrol_state      :     state_m_control_process;                 


signal wait_mcontrol                                    :       std_logic;

signal channel                                          :       std_logic_vector(3 downto 0);
signal sample                                           :       std_logic_vector(11 downto 0);
signal timestamp                                        :       std_logic_vector(31 downto 0);

signal sequence_slice                                   :       std_logic_vector(15 downto 0);

signal bcd_channel                                      :       std_logic_vector(3 downto 0);
signal bcd_sample                                       :       std_logic_vector(14 downto 0);
signal bcd_sample_s                                     :       std_logic_vector(15 downto 0);
signal bcd_timestamp                                    :       std_logic_vector(41 downto 0);
signal bcd_sequence                                     :       std_logic_vector(20 downto 0);

signal channel_string                                   :       std_logic_vector(7 downto 0);
signal sample_string                                    :       std_logic_vector(4*8-1 downto 0);
signal timestamp_string                                 :       std_logic_vector(10*8-1 downto 0);
signal sequence_string                                  :       std_logic_vector(5*8-1 downto 0);
signal pmod0, packed_sample,reg_packed_sample           :       std_logic_vector(63 downto 0);

signal byte_select, reg_byte_select                     :       natural range 0 to 80;

signal string_out, header_out, data_out                 :       std_logic_vector(7 downto 0);

signal byte_count,internal_reset                        :       std_logic;

signal string_control_state, next_string_control_state  :       control;

signal clock, reset                                     :       std_logic;

constant separator_char                                 :       std_logic_vector(7 downto 0) :=CHAR82STD(',');
constant newline_char                                   :       std_logic_vector(7 downto 0) :=CHAR82STD(lf);



attribute mark_debug : string;
attribute keep       : string;
attribute mark_debug of string_control_state: signal is "true";
attribute mark_debug of next_string_control_state: signal is "true";

attribute mark_debug of in_ready: signal is "true";
attribute mark_debug of in_valid: signal is "true";
attribute mark_debug of in_data:  signal is "true";
     
     
     
     
     
     
component bin2bcd
    generic (W   : integer);
    port (bin      : in std_logic_vector (W-1 downto 0);
          bcd      : out std_logic_vector (W+(W-4)/3 downto 0));
end component;

component bcd2ascii is
    Port (bcd      : in    std_logic_vector(3 downto 0);
          ascii    : out   std_logic_vector(7 downto 0));
end component;




begin


timestamp2bcd:              bin2bcd   generic map (W => 32)
                                      port map(bin   => timestamp,
                                               bcd   => bcd_timestamp);
sample2bcd:                 bin2bcd   generic map (W => 12)                                       
                                      port map(bin   => sample,                                  
                                               bcd   => bcd_sample);
sequence2bcd:               bin2bcd   generic map (W => 16)                                       
                                      port map(bin   => sequence_slice,                                  
                                               bcd   => bcd_sequence);  
                                                                         
bcd2channel_string_1:       bcd2ascii port map(bcd   => channel,
                                               ascii => channel_string(7 downto 0));
                                                                                     
bcd2sample_string_1:        bcd2ascii port map(bcd   => bcd_sample(3 downto 0),
                                               ascii => sample_string(7 downto 0));                                                                                                         
bcd2sample_string_10:       bcd2ascii port map(bcd   => bcd_sample(7 downto 4),
                                               ascii => sample_string(15 downto 8));                                       
bcd2sample_string_100:      bcd2ascii port map(bcd   => bcd_sample(11 downto 8),
                                               ascii => sample_string(23 downto 16));                                                                     
bcd2sample_string_1000:     bcd2ascii port map(bcd   => bcd_sample_s(15 downto 12),
                                               ascii => sample_string(31 downto 24));   
                                                                                         
                                                                      
bcd2timestamp_string_1:     bcd2ascii port map(bcd   => bcd_timestamp(3 downto 0),
                                               ascii => timestamp_string(7 downto 0));                                                                                                       
bcd2timestamp_string_10:    bcd2ascii port map(bcd   => bcd_timestamp(7 downto 4),
                                               ascii => timestamp_string(15 downto 8));                                         
bcd2timestamp_string_100:   bcd2ascii port map(bcd   => bcd_timestamp(11 downto 8),
                                               ascii => timestamp_string(23 downto 16));                                                                     
bcd2timestamp_string_1000:  bcd2ascii port map(bcd   => bcd_timestamp(15 downto 12),
                                               ascii => timestamp_string(31 downto 24));                                                      
bcd2timestamp_string_10000: bcd2ascii port map(bcd   => bcd_timestamp(19 downto 16),
                                               ascii => timestamp_string(39 downto 32));
                                               
                                               
bcd2timestamp_string_100000: bcd2ascii port map(bcd   => bcd_timestamp(23 downto 20),
                                             ascii => timestamp_string(47 downto 40)); 
bcd2timestamp_string_1000000: bcd2ascii port map(bcd   => bcd_timestamp(27 downto 24),
                                             ascii => timestamp_string(55 downto 48)); 
bcd2timestamp_string_10000000: bcd2ascii port map(bcd   => bcd_timestamp(31 downto 28),
                                             ascii => timestamp_string(63 downto 56));
bcd2timestamp_string_100000000: bcd2ascii port map(bcd   => bcd_timestamp(35 downto 32),
                                             ascii => timestamp_string(71 downto 64));
bcd2timestamp_string_1000000000: bcd2ascii port map(bcd   => bcd_timestamp(39 downto 36),
                                             ascii => timestamp_string(79 downto 72));

bcd2sequence_string_1:     bcd2ascii port map(bcd   => bcd_sequence(3 downto 0),
                                      ascii => sequence_string(7 downto 0));                                                                                                       
bcd2sequence_string_10:    bcd2ascii port map(bcd   => bcd_sequence(7 downto 4),
                                     ascii => sequence_string(15 downto 8));                                         
bcd2sequence_string_100:   bcd2ascii port map(bcd   => bcd_sequence(11 downto 8),
                                      ascii => sequence_string(23 downto 16));                                                                     
bcd2sequence_string_1000:  bcd2ascii port map(bcd   => bcd_sequence(15 downto 12),
                                      ascii => sequence_string(31 downto 24));                                                      
bcd2sequence_string_10000: bcd2ascii port map(bcd   => bcd_sequence(19 downto 16),
                                               ascii => sequence_string(39 downto 32));

latch_out_data: process(clock, reset)
begin
    if reset='1' then
         tdata   <=   8B"0";        
    elsif rising_edge(clock) then
         tdata<=data_out;          
    end if;
end process latch_out_data;

iocontrol_state: process(clock,reset)
begin
    if reset='1' then
        string_control_state <=  init;
    elsif rising_edge(clock) then
        string_control_state <= next_string_control_state;
end if;
end process iocontrol_state;

m_state: process (clock, reset)
begin
    if reset='1' then
        mcontrol_state<=init1;
    elsif rising_edge(clock) then
        mcontrol_state<=next_mcontrol_state;        
    end if;
end process m_state;

byte_select_register: process(clock, reset)
begin
    if reset='1' then
        reg_byte_select     <=   0;
         
    elsif rising_edge(clock) then
        reg_byte_select     <=  byte_select;        
    end if;
end process byte_select_register;

latch_in_data: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample   <=   64B"0";        
    elsif rising_edge(clock) then
        reg_packed_sample   <=  packed_sample;          
    end if;
end process latch_in_data;


pmod0         <=    reg_packed_sample;
timestamp     <=    pmod0(31 downto 0);
sample        <=    pmod0(43 downto 32);
channel       <=    pmod0(47 downto 44);
sequence_slice<=    pmod0(63 downto 48);
bcd_sample_s  <=    '0' & bcd_sample;
--bcd_sample_s  <=    bcd_sample;
clock       <=           aclk;   
reset       <=           areset; 

m_control: process(all)
begin
    case mcontrol_state is
        when init1 =>
            wait_mcontrol<='1';
            next_mcontrol_state<=init2;
        when init2 =>
            wait_mcontrol<='1';
            next_mcontrol_state<=init3;
        when init3 =>
            wait_mcontrol<='1';
            next_mcontrol_state<=init4;
        when init4 =>
            wait_mcontrol<='1';
            next_mcontrol_state<=init5;
        when init5 =>
            wait_mcontrol<='1';
            next_mcontrol_state<=init6;
        when init6 =>
            wait_mcontrol<='1'; 
            next_mcontrol_state<=wait_empty1;
        when wait_empty1 =>    
            wait_mcontrol<='1'; 
            next_mcontrol_state<=wait_empty2;
        when wait_empty2 =>     
            wait_mcontrol<='1'; 
            next_mcontrol_state<=wait_empty3;
        when wait_empty3 =>     
            wait_mcontrol<='1';
            next_mcontrol_state<=ready;
        when ready    => 
            wait_mcontrol<='0';
            next_mcontrol_state<=ready;
    end case;

end process m_control;



iocontrol: process(all)
begin
     case string_control_state is    
     when init              =>
                             byte_select<=0;
                             
                             tvalid        <=  '0';
                             tlast         <=  '0';
                             
                             hdr_tvalid    <=  '0';                                                                    
                             
                             tuser         <=  '0';
                             
                             in_ready      <=  '0';                            
                             
                             data_out      <=   8x"0";  
                             
                             packed_sample<=reg_packed_sample;
                             if wait_mcontrol='0' then
                               next_string_control_state<=wait_ready;
                             else
                               next_string_control_state<=init;                
                             end if;               
                             
     when wait_input        =>
                             byte_select    <=    0;
                             
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             
                             hdr_tvalid     <=  '0';  
                             
                             tuser          <=  '0';
                             
                             in_ready       <=  '1';
                             
                             data_out      <=   8x"0";        
                             
                             packed_sample<=in_data;                      
                             if in_valid='1' then
                               next_string_control_state<=valid_input;
                             else
                               next_string_control_state<=wait_input;                
                             end if;                         
                             
      
     when wait_ready        =>
                             byte_select<=0;
                             
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             
                             hdr_tvalid     <=  '0';  
                             
                             tuser          <=  '0';
                             
                             in_ready      <=  '0';
                             
                             data_out      <=   8x"0";  
                             
                             packed_sample<=reg_packed_sample;
                             if hdr_tready='1' then
                               next_string_control_state<=wait_input;
                             else
                               next_string_control_state<=wait_ready;                
                             end if;
     when valid_input       =>
                             byte_select<=0;
                             
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             hdr_tvalid     <=  '0';  
                                                        
                             tuser          <=  '0';
                             
                             in_ready      <=  '0';
                             
                             data_out      <=   8x"0";  
                             
                             packed_sample<=reg_packed_sample;
                             if tready='1'  then                           
                               next_string_control_state<=process_header_send;
                              else
                               next_string_control_state<=valid_input;
                             end if;         
  
     
     when process_header_send=>
                             byte_select<=0;
                             
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             hdr_tvalid     <=  '1';  
                             
                             tuser          <=  '0';
                             
                             in_ready      <=  '0';                             
                             
                             data_out      <=    8x"0";
                             
                             packed_sample<=reg_packed_sample;
                             
                             next_string_control_state<=process_header_wait;
                   
     
     when process_header_wait=>
                             byte_select<=0;
                             
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             
                             hdr_tvalid     <=  '0';  
                             
                             
                             tuser          <=  '0';
                             
                             in_ready      <=  '0';                    
                      
                             data_out      <=   8x"0";
                             
                             packed_sample<=reg_packed_sample;
                             if tready='1' then
                                next_string_control_state<=string_start;
                             else
                                next_string_control_state<=process_header_wait;
                             end if;           
--      when process_input_start=>
--                             byte_select<=0;
                             
--                             tvalid         <=  '0';  
--                             tlast          <=  '0';  
      
--                             hdr_tvalid     <=  '0';  
      
      
--                             tuser          <=  '0';  
      
--                             in_ready      <=  '0';
      
--                             data_out      <=   8x"0";
      
--                             packed_sample<=reg_packed_sample;    
--                             if tready='1' then                                
--                                next_string_control_state<=valid_input;        
--                             else                                              
--                                next_string_control_state<=process_header_wait;
--                             end if;
                             
                             
      when string_start=>
                             byte_select<=reg_byte_select+1;
                             
                             tvalid         <=  '0';  
                             tlast          <=  '0';  
                       
                             hdr_tvalid     <=  '0';  
                       
                             tuser          <=  '0';  
                       
                             in_ready      <=  '0';
                       
                             data_out      <=   8x"0";
                             
                             packed_sample<=reg_packed_sample;
                              
                             next_string_control_state<=process_input_send;                     
      when process_input_send=>
                             byte_select<=reg_byte_select+1;
                             
                             in_ready      <=  '0';
                             tvalid        <=  '1';
                             tlast         <=  '0';
                             
                             
                             hdr_tvalid    <=  '0';  
                                                      
                             
                             tuser         <=  '0';
                             
                             in_ready      <=  '0';
                             
                             data_out      <=   string_out;
                             
                             packed_sample<=reg_packed_sample;
                             if reg_byte_select=79 then
                               next_string_control_state<=string_complete;
                             elsif tready='0' then
                               next_string_control_state<=process_input_wait;
                             else 
                               next_string_control_state<=process_input_send;                          
                             end if;
       when process_input_wait=>
                             byte_select<=reg_byte_select;
                             in_ready       <=  '0';
                             tvalid         <=  '0';
 
                             tlast          <=  '0';
                             
                                                         
                             hdr_tvalid     <= '0';  
                                                       
                             
                             tuser          <='0';
                             
                             in_ready      <=  '0';
                             
                             data_out      <=   8x"0";
                             
                             packed_sample<=reg_packed_sample;
                             if tready='1' then
                               next_string_control_state<=process_input_send;
                             else
                               next_string_control_state<=process_input_wait;
                             end if;    
                      
      
       when string_complete   =>
                             byte_select<=reg_byte_select;
                             
                             tvalid         <= '1';
                             tlast          <= '1';                           
                             
                             hdr_tvalid     <= '0';                               
                             
                             tuser          <= '0';
                             
                             in_ready      <=  '0';
                             
                             data_out      <=   8x"0";
                             
                             packed_sample<=reg_packed_sample; 
                             if tready='1' then
                               next_string_control_state<=wait_next;
                             else
                               next_string_control_state<=string_complete;
                             end if;   
                             
     when wait_next       =>
                              byte_select<=0;
                              
                              tvalid        <=  '0';
                              tlast         <=  '0';                             
                              
                              hdr_tvalid    <=  '0';                               
                              
                              tuser         <=  '0';
                              
                              in_ready      <=  '0';
                              
                              data_out      <=  8x"0";
                              
                              packed_sample<=reg_packed_sample;
                              if hdr_tready='1' then
                                next_string_control_state<=wait_ready;
                              else
                                next_string_control_state<=wait_next;
                              end if;                     
                                 
     when others       =>
                              byte_select<=0;
                              
                              tvalid        <=  '0';
                              tlast         <=  '0';
                              
                              
                              hdr_tvalid    <= '0';  
                              
                              
                              tuser<='0';
                              
                              in_ready      <=  '0';
                              
                              data_out      <=   8x"0";
                              
                              packed_sample<=reg_packed_sample;
                              
                              next_string_control_state<=init;
end case;
end process iocontrol;









with reg_byte_select select

string_out   <=separator_char when 4 downto 0,
             channel_string when 5,
             separator_char when 6,
             sample_string(7 downto 0) when 10,
             sample_string(15 downto 8) when 9,
             sample_string(23 downto 16) when 8,
             sample_string(31 downto 24) when  7,
             separator_char when 11,
             timestamp_string(7 downto 0) when 21,
             timestamp_string(15 downto 8) when 20,
             timestamp_string(23 downto 16) when 19,
             timestamp_string(31 downto 24) when 18,
             timestamp_string(39 downto 32) when 17,
             timestamp_string(47 downto 40) when 16,
             timestamp_string(55 downto 48) when 15,
             timestamp_string(63 downto 56) when 14,
             timestamp_string(71 downto 64) when 13,
             timestamp_string(79 downto 72) when 12,
             separator_char when    22,
             sequence_string(7 downto 0) when 27,
             sequence_string(15 downto 8) when 26,
             sequence_string(23 downto 16) when 25,
             sequence_string(31 downto 24) when 24,
             sequence_string(39 downto 32) when 23,
             separator_char when 78 downto 28,
             newline_char when 79,
             separator_char when others;
end Behavioral;
