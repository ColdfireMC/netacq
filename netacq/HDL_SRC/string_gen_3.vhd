----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.10.2020 16:27:44
-- Design Name: 
-- Module Name: string_gen_3 - Behavioral
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

entity string_gen_3 is
Port ( ------------------ input interface--------------------
       in_ready                      : out std_logic;
       in_valid                      : in  std_logic;
       in_data                       : in  std_logic_vector(63 downto 0);
       ----------------------config input--------------------
       local_ip_addr                 : in  std_logic_vector(31 downto 0);
       dest_ip_addr                  : in  std_logic_vector(31 downto 0);
       local_macaddr                 : in  std_logic_vector(47 downto 0);
       dscp                          : in  std_logic_vector(5 downto 0);
       ttl                           : in  std_logic_vector(7 downto 0);
       ecn                           : in  std_logic_vector(1 downto 0);
       src_port                      : in  std_logic_vector(15 downto 0);
       dest_port                     : in  std_logic_vector(15 downto 0);
       --------------------- AXI-Stream-data-out-------------
       aclk                          : in  std_logic;
       areset                        : in  std_logic;
       tvalid                        : out std_logic;
       tdata                         : out std_logic_vector(7 downto 0);
       tready                        : in  std_logic;
       tlast                         : out std_logic;
       tuser                         : out std_logic;  
       ---------------------- AXI-Stream-hdr-out-------------
       hdr_tvalid                    : out std_logic;                     
       hdr_tready                    : in  std_logic;                     
       hdr_ip_dscp                   : out std_logic_vector(5 downto 0);  
       hdr_ip_ecn                    : out std_logic_vector(1 downto 0);  
       hdr_ip_ttl                    : out std_logic_vector(7 downto 0);  
       hdr_ip_source_ip              : out std_logic_vector(31 downto 0); 
       hdr_ip_dest_ip                : out std_logic_vector(31 downto 0); 
       hdr_source_port               : out std_logic_vector(15 downto 0); 
       hdr_dest_port                 : out std_logic_vector(15 downto 0); 
       hdr_length                    : out std_logic_vector(15 downto 0); 
       hdr_checksum                  : out std_logic_vector(15 downto 0));
end string_gen_3;

architecture Behavioral of string_gen_3 is

component bin2bcd
    generic (W   : integer);
    port (bin      : in std_logic_vector (W-1 downto 0);
          bcd      : out std_logic_vector (W+(W-4)/3 downto 0));
end component;

component bcd2ascii is
    Port (bcd      : in    std_logic_vector(3 downto 0);
          ascii    : out   std_logic_vector(7 downto 0));
end component;



type control is (init, wait_input, valid_input,header_set,
                 process_input_send, process_input_wait, process_header_send, process_header_wait,
                 string_complete, header_complete);
type  state_m_control_process    is (init1, init2, init3, init4, init5, init6 , wait_empty1, wait_empty2, wait_empty3, ready);
signal mcontrol_state, next_mcontrol_state      :     state_m_control_process;                 


-----------------------------------------------------signals-------------------------------------------------------
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

signal space_string                                     :       std_logic_vector(7 downto 0):=8x"20";
signal enter_string                                     :       std_logic_vector(7 downto 0):=8x"0a";
signal comma_string                                     :       std_logic_vector(7 downto 0):=8x"2c";

signal byte_select, reg_byte_select                     :       natural range 0 to 80;

signal string_out, header_out, data_out                 :       std_logic_vector(7 downto 0);

signal byte_count,internal_reset                        :       std_logic;

signal string_control_state, next_string_control_state  :       control;

signal clock, reset                                     :       std_logic;

signal wait_mcontrol                                    :       std_logic;

attribute mark_debug : string;
attribute keep       : string;
    
--attribute mark_debug of DATA_IN : signal is "true";
--attribute mark_debug of DATA_SEND : signal is "true";
attribute mark_debug of in_ready: signal is "true";
attribute mark_debug of in_valid: signal is "true";
attribute mark_debug of in_data: signal is "true";
attribute mark_debug of byte_select: signal is "true";
attribute mark_debug of tready: signal is "true";
attribute mark_debug of hdr_ip_source_ip: signal is "true";
attribute mark_debug of hdr_ip_dest_ip  : signal is "true";
attribute mark_debug of hdr_source_port : signal is "true";
attribute mark_debug of hdr_dest_port   : signal is "true";
--attribute mark_debug of string_out: signal is "true";
--attribute mark_debug of out_valid: signal is "true";
--attribute mark_debug of out_ready: signal is "true";
attribute mark_debug of string_control_state: signal is "true";
attribute mark_debug of next_string_control_state: signal is "true";


constant    time_to_live           :                   natural:=64;
constant    udp_length             :                   natural:=8+79;
begin

pmod0         <=    reg_packed_sample;
timestamp     <=    pmod0(31 downto 0);
sample        <=    pmod0(43 downto 32);
channel       <=    pmod0(47 downto 44);
sequence_slice<=    pmod0(63 downto 48);
bcd_sample_s  <=    '0' & bcd_sample;
--bcd_sample_s  <=    bcd_sample;
clock       <=           aclk;   
reset       <=           areset; 


hdr_ip_dscp          <=6x"0";             
hdr_ip_ecn           <=2x"0";             
hdr_ip_ttl           <=std_logic_vector(to_unsigned(time_to_live,8));             
hdr_ip_source_ip     <=local_ip_addr;            
hdr_ip_dest_ip       <=dest_ip_addr;
hdr_source_port      <=src_port;             
hdr_dest_port        <=dest_port;             
hdr_length           <=std_logic_vector(to_unsigned(udp_length,16));             
hdr_checksum         <=16x"0";             

header_out           <="00000000";




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
                                                                                                                                                                                                                                                                                                                                                                   
latch_in_data: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample   <=   64B"0";        
    elsif rising_edge(clock) then
        reg_packed_sample   <=  packed_sample;          
    end if;
end process latch_in_data;
latch_out_data: process(clock, reset)
begin
    if reset='1' then
         tdata   <=   8B"0";        
    elsif rising_edge(clock) then
         tdata<=data_out;          
    end if;
end process latch_out_data;
byte_select_register: process(clock, reset)
begin
    if reset='1' then
        reg_byte_select     <=   0;
         
    elsif rising_edge(clock) then
        reg_byte_select     <=  byte_select;        
    end if;
end process byte_select_register;

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
                             byte_select   <=    0;
                             in_ready      <=  '0';
                             tvalid        <=  '0';
                             tlast         <=  '0';
                             
                             hdr_tvalid    <=  '0';                                                                    
                             
                             tuser         <=  '0';
                             
                             
                             packed_sample<=reg_packed_sample;
                             
                             if wait_mcontrol='0' then
                               next_string_control_state<=wait_input;
                             else
                               next_string_control_state<=init;                
                             end if;               
     when wait_input        =>
                             byte_select    <=    0;
                             in_ready       <=  '1';
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             
                             hdr_tvalid     <=  '0';  
                             
                             tuser          <=  '0';
                             
                             
                             packed_sample<=in_data;
                             if in_valid='1' then
                               next_string_control_state<=valid_input;
                             else
                               next_string_control_state<=wait_input;                
                             end if;
     when valid_input       =>
                             byte_select    <=    0;
                             in_ready       <=  '0';
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             hdr_tvalid     <=  '0';  
                                                        
                             tuser          <=  '0';
                             
                             packed_sample<=reg_packed_sample;
                             if hdr_tready='1'  then                           
                               next_string_control_state<=process_header_send;
                              else
                               next_string_control_state<=valid_input;
                             end if;       
     when process_header_send=>
                             byte_select    <=  reg_byte_select;
                             in_ready       <=  '0';
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             
                             hdr_tvalid     <=  '1';  
                             
                             
                             tuser          <=  '0';
                             
                             
                             
                             
                             packed_sample<=reg_packed_sample;
                             
                             if hdr_tready='0' then
                                next_string_control_state<=process_input_send;
                             else
                                next_string_control_state<=process_header_send;
                             end if;                     
           
           
     when process_input_send=>
                             byte_select<=reg_byte_select+1;
                             in_ready      <=  '0';
                             tvalid        <=  '1';
                             tlast         <=  '0';
                             
                             
                             hdr_tvalid    <=  '0';  
                             
                             
                             
                             
                             
                             tuser         <=  '0';
                             
                             
                             
                             
                             packed_sample<=reg_packed_sample;
                             if reg_byte_select>=79 then
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
                             packed_sample<=reg_packed_sample;
                             tlast          <=  '0';
                             
                             
                             
                             hdr_tvalid     <= '0';  
                             
                             
                             
                             
                             tuser          <='0';
                        
                             if tready='1' then
                               next_string_control_state<=process_input_send;
                             else
                               next_string_control_state<=process_input_wait;
                             end if;            
     when string_complete   =>
                             byte_select<=reg_byte_select;
                             in_ready       <=  '0';
                             tvalid         <=  '0';
                             tlast          <=  '1';
                             
                             
                             
                             
                             hdr_tvalid     <= '0';  
                             
                             
                             tuser          <='0';
                             
                             
                             packed_sample<=reg_packed_sample;
                             
                             
                             
                             if tready='0' then
                               next_string_control_state<=wait_input;
                             else
                               next_string_control_state<=string_complete;
                             end if;   
                             
                             
                             
     when others            =>
                             byte_select<=0;
                             in_ready  <=  '0';
                             tvalid <=  '0';
                             tlast         <=  '0';
                             
                             
                             hdr_tvalid    <= '0';  
                             
                             
                             
                             tuser<='0';
                             
                             
                             packed_sample<=64B"0";
                             next_string_control_state<=init;
end case;
end process iocontrol;


with reg_byte_select select

string_out <=comma_string when 4 downto 0,
             channel_string when 5,
             comma_string when 6,
             sample_string(7 downto 0) when 10,
             sample_string(15 downto 8) when 9,
             sample_string(23 downto 16) when 8,
             sample_string(31 downto 24) when  7,
             comma_string when 11,
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
             comma_string when    22,
             sequence_string(7 downto 0) when 27,
             sequence_string(15 downto 8) when 26,
             sequence_string(23 downto 16) when 25,
             sequence_string(31 downto 24) when 24,
             sequence_string(39 downto 32) when 23,
             comma_string when 78 downto 28,
             enter_string when 79,
             comma_string when others;
 
with string_control_state select                     
data_out     <= header_out when process_header_send | process_header_wait,
                string_out when others;
end Behavioral;
