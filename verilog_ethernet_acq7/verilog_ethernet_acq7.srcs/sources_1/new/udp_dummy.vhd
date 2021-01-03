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

entity udp_dummy is
  Port (hdr_tvalid                     : out std_logic;
        hdr_tready                     : in  std_logic;
        --------------------- AXI-Stream-data-out-------------
         aclk                          : in  std_logic;
         areset                        : in  std_logic;
         tvalid                        : out std_logic;
         tdata                         : out std_logic_vector(7 downto 0);
         tready                        : in  std_logic;
         tlast                         : out std_logic;
         tuser                         : out std_logic);
end udp_dummy;

architecture Behavioral of udp_dummy is




type control is (init, wait_ready, wait_input, valid_input,header_set,
                 process_input_send, process_input_wait, process_header_send, process_header_wait,
                 string_1, string_2, string_3, string_4, string_5, string_complete, header_complete, wait_next);
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

signal space_string                                     :       std_logic_vector(7 downto 0):=8x"20";
signal enter_string                                     :       std_logic_vector(7 downto 0):=8x"0a";
signal comma_string                                     :       std_logic_vector(7 downto 0):=8x"2c";

signal byte_select, reg_byte_select                     :       natural range 0 to 80;

signal string_out, header_out, data_out                 :       std_logic_vector(7 downto 0);

signal byte_count,internal_reset                        :       std_logic;

signal string_control_state, next_string_control_state  :       control;

signal clock, reset                                     :       std_logic;

attribute mark_debug : string;
attribute keep       : string;
attribute mark_debug of string_control_state: signal is "true";
attribute mark_debug of next_string_control_state: signal is "true";



begin

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

reset<=areset;
clock<=aclk;


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
                             tvalid        <=  '0';
                             tlast         <=  '0';
                             
                             hdr_tvalid    <=  '0';                                                                    
                             
                             tuser         <=  '0';
                             
                             
                             data_out      <=   tdata;  
                             
                             if wait_mcontrol='0' then
                               next_string_control_state<=wait_ready;
                             else
                               next_string_control_state<=init;                
                             end if;               
     when wait_ready        =>
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             
                             hdr_tvalid     <=  '0';  
                             
                             tuser          <=  '0';
                             
                             data_out      <=   tdata;  
                             
                             if hdr_tready='1' then
                               next_string_control_state<=process_header_send;
                             else
                               next_string_control_state<=wait_input;                
                             end if;
     when valid_input       =>
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             hdr_tvalid     <=  '0';  
                                                        
                             tuser          <=  '0';
                             
                             data_out      <=   tdata;  
                             
                             if tready='1'  then                           
                               next_string_control_state<=string_1;
                              else
                               next_string_control_state<=valid_input;
                             end if;         
  
     
     when process_header_send=>
                             tvalid         <=  '0';
                             tlast          <=  '0';
                             
                             
                             hdr_tvalid     <=  '1';  
                             
                             
                             tuser          <=  '0';
                             
                             
                             
                             
                             data_out      <=   tdata;
                             
                             if hdr_tready='0' then
                                next_string_control_state<=valid_input;
                             else
                                next_string_control_state<=process_header_send;
                             end if;                     
           
             
                            
      when string_1=>
                            tvalid        <=  '1';
                            tlast         <=  '0';
                            
                            
                            hdr_tvalid    <=  '0';  
                            
                            
                            
                            
                            
                            tuser         <=  '0';
                            
                            
                            
                            
                            data_out      <=   8x"40";
                            
                            if tready='1' then
                               next_string_control_state<=string_2;
                            else
                               next_string_control_state<=string_1;
                            end if;                     
          
      when string_2=>
                            tvalid        <=  '1';
                            tlast         <=  '0';
                            
                            
                            hdr_tvalid    <=  '0';  
                            
                            
                            
                            
                            
                            tuser         <=  '0';
                            
                            
                            
                            
                            data_out      <=   8x"41";
                            
                            if tready='1' then
                               next_string_control_state<=string_3;
                            else
                               next_string_control_state<=string_2;
                            end if;    
      when string_3=>
                            tvalid        <=  '1';
                            tlast         <=  '0';
                            
                            
                            hdr_tvalid    <=  '0';  
                            
                            
                            
                            
                            
                            tuser         <=  '0';
                            
                            
                            
                            
                            data_out      <=   8x"42";
                            
                            if tready='1' then
                               next_string_control_state<=string_4;
                            else
                               next_string_control_state<=string_3;
                            end if;                                                                                 
                     
                     
      when string_4=>
                            tvalid        <=  '1';
                            tlast         <=  '0';
                            
                            
                            hdr_tvalid    <=  '0';  
                            
                            
                            
                            
                            
                            tuser         <=  '0';
                            
                            
                            
                            
                            data_out      <=   8x"43";
                            
                            if tready='1' then
                               next_string_control_state<=string_complete ;
                            else
                               next_string_control_state<=string_4;
                            end if;                              
                     
      
     when string_complete   =>
                            tvalid         <=  '1';
                            tlast          <=  '1';
                            
                            
                            
                            
                            hdr_tvalid     <= '0';  
                            
                            
                            tuser          <='0';
                            
                            
                            data_out      <=   tdata;
                            
                            
                            
                            if tready='1' then
                              next_string_control_state<=wait_next;
                            else
                              next_string_control_state<=string_complete;
                            end if;   
                             
     when wait_next       =>
                          tvalid         <=  '0';
                          tlast          <=  '0';
                                
                          
                          
                          
                          hdr_tvalid     <= '0';  
                          
                          
                          tuser          <='0';
                          
                          
                          data_out      <=   tdata;
                          
                          
                          
                          if tready='1' then
                            next_string_control_state<=wait_ready;
                          else
                            next_string_control_state<=wait_next;
                          end if;                     
                             
     when others            =>
                          tvalid <=  '0';
                          tlast         <=  '0';
                          
                          
                          hdr_tvalid    <= '0';  
                          
                          
                          
                          tuser<='0';
                          
                          
                          data_out      <=   tdata;
                          next_string_control_state<=init;
end case;
end process iocontrol;


end Behavioral;
