library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity timestamp_patch_3 is
      port ( clock               : in std_logic;
             reset               : in std_logic;
             -- input interface0
             in_ready0          : out std_logic;
             in_valid0          : in std_logic;
             in_data0           : in std_logic_vector(15 downto 0);
             -- input interface1
             in_ready1          : out std_logic;
             in_valid1          : in std_logic;
             in_data1           : in std_logic_vector(15 downto 0);
             -- input interface2
             in_ready2          : out std_logic;
             in_valid2          : in std_logic;
             in_data2           : in std_logic_vector(15 downto 0);                      
                        
             
             -- output interface
             out_ready         : in std_logic;
             out_valid         : out std_logic;
             out_data          : out std_logic_vector(63 downto 0));
end timestamp_patch_3;

architecture Behavioral of timestamp_patch_3 is
signal timestamp                              :   unsigned(31 downto 0);
signal timestamp_snap0, input_timestamp_snap0 :   unsigned(31 downto 0);
signal timestamp_snap1, input_timestamp_snap1 :   unsigned(31 downto 0);
signal timestamp_snap2, input_timestamp_snap2 :   unsigned(31 downto 0);
signal timestamp_snap3, input_timestamp_snap3 :   unsigned(31 downto 0);

signal reg_input_data0, reg_input_data1, reg_input_data2, reg_input_data3              :   std_logic_vector(15 downto 0);
signal input_data0, input_data1, input_data2, input_data3                              :   std_logic_vector(15 downto 0);
signal packed_sample0, packed_sample1, packed_sample2, packed_sample3                  :   std_logic_vector(63 downto 0);
signal reg_packed_sample0, reg_packed_sample1, reg_packed_sample2, reg_packed_sample3  :   std_logic_vector(63 downto 0);
signal sample_register_ena, ready_snap_ena                                             :   std_logic;

signal  reg_packed_sample_ready0, packed_sample_ready0                                 :   std_logic;
signal  reg_packed_sample_ready1, packed_sample_ready1                                 :   std_logic;
signal  reg_packed_sample_ready2, packed_sample_ready2                                 :   std_logic;

signal reg_sequence_cnt0, sequence_cnt0         :   unsigned(15 downto 0);
signal reg_sequence_cnt1, sequence_cnt1         :   unsigned(15 downto 0);
signal reg_sequence_cnt2, sequence_cnt2         :   unsigned(15 downto 0);
signal reg_sequence_cnt3, sequence_cnt3         :   unsigned(15 downto 0);

signal burst_ready                              :  std_logic;

type state_icontrol_process is (init, wait_1st, wait_others, input_valid, concat, store_packed_sample);
type state_ocontrol_process is (init, 
                                wait_1st,
                                wait_others, 
                                output_valid, 
                                out_chan0, 
                                signal_chan0, 
                                out_chan1,
                                signal_chan1, 
                                out_chan2, 
                                signal_chan2,
                                out_term); 
signal icontrol_state0, next_icontrol_state0    :     state_icontrol_process;
signal icontrol_state1, next_icontrol_state1    :     state_icontrol_process;
signal icontrol_state2, next_icontrol_state2    :     state_icontrol_process;
signal icontrol_state3, next_icontrol_state3    :     state_icontrol_process;
signal ocontrol_state, next_ocontrol_state      :     state_ocontrol_process;


signal out_data_input                           :     std_logic_vector(63 downto 0);

attribute mark_debug : string;
attribute keep       : string;
--attribute mark_debug of timestamp_snap : signal is "true";
--attribute mark_debug of in_data : signal is "true";
--attribute mark_debug of in_valid : signal is "true";
--attribute mark_debug of reg_input_data : signal is "true";
--attribute mark_debug of out_valid : signal is "true";
--attribute mark_debug of out_data: signal is "true";
--attribute mark_debug of out_ready: signal is "true";
--attribute mark_debug of reg_sequence_cnt: signal is "true";
--attribute mark_debug of iocontrol_state: signal is "true";
--attribute mark_debug of next_iocontrol_state: signal is "true";
begin

input_data_register0: process(clock, reset)
begin
    if reset='1' then
        reg_input_data0 <= 16B"0";
    elsif rising_edge(clock) then
        reg_input_data0<=input_data0;
    end if;
end process input_data_register0;

input_data_register1: process(clock, reset)
begin
    if reset='1' then
        reg_input_data1 <= 16B"0";
    elsif rising_edge(clock) then
        reg_input_data1<=input_data1;
    end if;
end process input_data_register1;

input_data_register2: process(clock, reset)
begin
    if reset='1' then
        reg_input_data2 <= 16B"0";
    elsif rising_edge(clock) then
        reg_input_data2<=input_data2;
    end if;
end process input_data_register2;

timestamp_snap_reg0: process(clock, reset)
begin
    if reset='1' then
        timestamp_snap0 <= to_unsigned(0, timestamp'length);
    elsif rising_edge(clock) then
        timestamp_snap0<=input_timestamp_snap0;
    end if;
end process timestamp_snap_reg0;
timestamp_snap_reg1: process(clock, reset)
begin
    if reset='1' then
        timestamp_snap1 <= to_unsigned(0, timestamp'length);
    elsif rising_edge(clock) then
        timestamp_snap1<=input_timestamp_snap1;
    end if;
end process timestamp_snap_reg1;
timestamp_snap_reg2: process(clock, reset)
begin
    if reset='1' then
        timestamp_snap2 <= to_unsigned(0, timestamp'length);
    elsif rising_edge(clock) then
        timestamp_snap2<=input_timestamp_snap2;
    end if;
end process timestamp_snap_reg2;

packed_sample_register0: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample0 <= 64B"0";
    elsif rising_edge(clock) then
        reg_packed_sample0<=packed_sample0;
    end if;
end process packed_sample_register0;

packed_sample_register1: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample1 <= 64B"0";
    elsif rising_edge(clock) then
        reg_packed_sample1<=packed_sample1;
    end if;
end process packed_sample_register1;

packed_sample_register2: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample2 <= 64B"0";
    elsif rising_edge(clock) then
        reg_packed_sample2<=packed_sample2;
    end if;
end process packed_sample_register2;

packed_sample_ready_register0: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample_ready0 <= '0';
    elsif rising_edge(clock) then
        reg_packed_sample_ready0<=packed_sample_ready0;
    end if;
end process packed_sample_ready_register0;

packed_sample_ready_register1: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample_ready1 <= '0';
    elsif rising_edge(clock) then
        reg_packed_sample_ready1<=packed_sample_ready1;
    end if;
end process packed_sample_ready_register1;
packed_sample_ready_register2: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample_ready2 <= '0';
    elsif rising_edge(clock) then
        reg_packed_sample_ready2<=packed_sample_ready2;
    end if;
end process packed_sample_ready_register2;

output_data_register: process (clock, reset)
begin
    if reset='1' then
        out_data <= 64B"0";
    elsif rising_edge(clock) then
        out_data<=out_data_input;
    end if;
end process;

timestamp_counter: process(clock, reset)
begin
    if reset='1' then
        timestamp <= to_unsigned(0, timestamp'length);
    elsif rising_edge(clock) then
        timestamp<=timestamp + 1;
    end if;
end process timestamp_counter;

sequence_counter0: process(clock, reset)
begin
    if reset='1' then
        reg_sequence_cnt0 <= to_unsigned(0, reg_sequence_cnt0'length);
    elsif rising_edge(clock) then
        reg_sequence_cnt0<=sequence_cnt0;
    end if;
end process sequence_counter0;

sequence_counter1: process(clock, reset)
begin
    if reset='1' then
        reg_sequence_cnt1 <= to_unsigned(0, reg_sequence_cnt1'length);
    elsif rising_edge(clock) then
        reg_sequence_cnt1<=sequence_cnt1;
    end if;
end process sequence_counter1;

sequence_counter2: process(clock, reset)
begin
    if reset='1' then
        reg_sequence_cnt2 <= to_unsigned(0, reg_sequence_cnt2'length);
    elsif rising_edge(clock) then
        reg_sequence_cnt2<=sequence_cnt2;
    end if;
end process sequence_counter2;

sequence_counter3: process(clock, reset)
begin
    if reset='1' then
        reg_sequence_cnt3 <= to_unsigned(0, reg_sequence_cnt3'length);
    elsif rising_edge(clock) then
        reg_sequence_cnt3<=sequence_cnt3;
    end if;
end process sequence_counter3;

i_state0: process (clock, reset)
begin
    if reset='1' then
        icontrol_state0<=init;
    elsif rising_edge(clock) then
        icontrol_state0<=next_icontrol_state0;
    end if;
end process i_state0;

i_state1: process (clock, reset)
begin
    if reset='1' then
        icontrol_state1<=init;
    elsif rising_edge(clock) then
        icontrol_state1<=next_icontrol_state1;
    end if;
end process i_state1;

i_state2: process (clock, reset)
begin
    if reset='1' then
        icontrol_state2<=init;
    elsif rising_edge(clock) then
        icontrol_state2<=next_icontrol_state2;
    end if;
end process i_state2;
i_state3: process (clock, reset)
begin
    if reset='1' then
        icontrol_state3<=init;
    elsif rising_edge(clock) then
        icontrol_state3<=next_icontrol_state3;
    end if;
end process i_state3;

o_state: process (clock, reset)
begin
    if reset='1' then
        ocontrol_state<=init;
    elsif rising_edge(clock) then
        ocontrol_state<=next_ocontrol_state;
    end if;
end process o_state;  

icontrol0: process(all)
begin
    case icontrol_state0 is
        when init           =>
            in_ready0   <= '0';
            input_data0          <= reg_input_data0;
            input_timestamp_snap0<= timestamp_snap0;
            packed_sample0       <= reg_packed_sample0;
            
            sequence_cnt0<=reg_sequence_cnt0;
            
            packed_sample_ready0  <= '0'; 
            
            next_icontrol_state0<=wait_1st;
          
        when wait_1st       =>
            in_ready0   <= '1';
            input_data0          <= in_data0;
            input_timestamp_snap0<= timestamp_snap0;
            packed_sample0      <= reg_packed_sample0;
            
            sequence_cnt0<=reg_sequence_cnt0;
            
            packed_sample_ready0  <= '0'; 
                                 
            if in_valid0='1' then
                next_icontrol_state0<=input_valid;
            else
                next_icontrol_state0<=wait_1st;
            end if;
        when wait_others    =>
            in_ready0   <= '0';
            input_data0          <= reg_input_data0;
            input_timestamp_snap0<= timestamp_snap0;
            packed_sample0       <= reg_packed_sample0;
            
            sequence_cnt0<=reg_sequence_cnt0;
            
            packed_sample_ready0  <= '1';
            
            if burst_ready='1' then
                next_icontrol_state0<=wait_1st;
            else 
                next_icontrol_state0<=wait_others;
            end if;
                              
        when input_valid     =>
            in_ready0   <= '0';
            
            input_data0          <= in_data0;
            input_timestamp_snap0<= timestamp;
            packed_sample0       <= reg_packed_sample0;
            
            sequence_cnt0<=reg_sequence_cnt0+1;
            
            packed_sample_ready0  <= '0';     

            next_icontrol_state0<=concat;
      
          
        when concat         =>
            in_ready0            <= '0';
        
            input_data0          <= reg_input_data0;
            input_timestamp_snap0<= timestamp_snap0;
            packed_sample0       <= std_logic_vector(reg_sequence_cnt0) & reg_input_data0 & std_logic_vector(timestamp_snap0) ;
            
            sequence_cnt0        <= reg_sequence_cnt0; 
              
            packed_sample_ready0  <= '0';
            
            next_icontrol_state0 <= store_packed_sample;
                                                           
        when store_packed_sample   =>
            in_ready0   <= '0';
        
            input_data0          <= reg_input_data0;
            input_timestamp_snap0<= timestamp_snap0;
            packed_sample0       <= reg_packed_sample0;            

            sequence_cnt0<=reg_sequence_cnt0; 
            
            packed_sample_ready0  <= '1';

            next_icontrol_state0<=wait_others;      
    end case;                      
end process icontrol0;


icontrol1: process(all)
begin
    case icontrol_state1 is
        when init           =>
            in_ready1   <= '0';
            input_data1          <= reg_input_data1;
            input_timestamp_snap1<= timestamp_snap1;
            packed_sample1       <= reg_packed_sample1;
            
            sequence_cnt1<=reg_sequence_cnt1;
            
            packed_sample_ready1  <= '0';  
            
            next_icontrol_state1<=wait_1st;
          
        when wait_1st       =>
            in_ready1   <= '1';
            input_data1          <= in_data1;
            input_timestamp_snap1<= timestamp_snap1;
            packed_sample1      <= reg_packed_sample1;
            
            sequence_cnt1<=reg_sequence_cnt1;
            
            packed_sample_ready1  <= '0';  
                                 
            if in_valid1='1' then
                next_icontrol_state1<=input_valid;
            else
                next_icontrol_state1<=wait_1st;
            end if;
        when wait_others    =>
            in_ready1   <= '0';
            input_data1          <= reg_input_data1;
            input_timestamp_snap1<= timestamp_snap1;
            packed_sample1       <= reg_packed_sample1;
            
            sequence_cnt1<=reg_sequence_cnt1;
            
            packed_sample_ready1  <= '1'; 
            
            if burst_ready='1' then
                next_icontrol_state1<=wait_1st;
            else 
                next_icontrol_state1<=wait_others;
            end if;
                              
        when input_valid     =>
            in_ready1   <= '0';
            
            input_data1          <= in_data1;
            input_timestamp_snap1<= timestamp;
            packed_sample1       <= reg_packed_sample1;
            
            sequence_cnt1<=reg_sequence_cnt1+1;     
            
            packed_sample_ready1  <= '0'; 
            
            next_icontrol_state1<=concat;
      
          
        when concat         =>
            in_ready1            <= '0';
        
            input_data1          <= reg_input_data1;
            input_timestamp_snap1<= timestamp_snap1;
            packed_sample1       <= std_logic_vector(reg_sequence_cnt1) & reg_input_data1 & std_logic_vector(timestamp_snap1) ;
            
            sequence_cnt1        <= reg_sequence_cnt1; 
            
            packed_sample_ready1  <= '0';  
          
            next_icontrol_state1 <= store_packed_sample;
                                                           
        when store_packed_sample   =>
            in_ready1   <= '0';
        
            input_data1          <= reg_input_data1;
            input_timestamp_snap1<= timestamp_snap1;
            packed_sample1       <= reg_packed_sample1;            

            sequence_cnt1<=reg_sequence_cnt1; 
            
            packed_sample_ready1  <= '1';

            next_icontrol_state1<=wait_others;      
    end case;                      
end process icontrol1;


icontrol2: process(all)
begin
    case icontrol_state2 is
        when init           =>
            in_ready2   <= '0';
            input_data2          <= reg_input_data2;
            input_timestamp_snap2<= timestamp_snap2;
            packed_sample2       <= reg_packed_sample2;
            
            sequence_cnt2<=reg_sequence_cnt2;
            
            packed_sample_ready2  <= '0';
            
            next_icontrol_state2<=wait_1st;
          
        when wait_1st       =>
            in_ready2   <= '1';
            input_data2          <= in_data2;
            input_timestamp_snap2<= timestamp_snap2;
            packed_sample2      <= reg_packed_sample2;
            
            sequence_cnt2<=reg_sequence_cnt2;
            
            packed_sample_ready2  <= '0';
                                 
            if in_valid2='1' then
                next_icontrol_state2<=input_valid;
            else
                next_icontrol_state2<=wait_1st;
            end if;
        when wait_others    =>
            in_ready2   <= '0';
            input_data2          <= reg_input_data2;
            input_timestamp_snap2<= timestamp_snap2;
            packed_sample2       <= reg_packed_sample2;
            
            sequence_cnt2<=reg_sequence_cnt2;
            
            packed_sample_ready2  <= '1';
            
            
            if burst_ready='1' then
                next_icontrol_state2<=wait_1st;
            else 
                next_icontrol_state2<=wait_others;
            end if;
                              
        when input_valid     =>
            in_ready2   <= '0';
            
            input_data2          <= in_data2;
            input_timestamp_snap2<= timestamp;
            packed_sample2       <= reg_packed_sample2;
            
            sequence_cnt2<=reg_sequence_cnt2+1;
            
            packed_sample_ready2  <= '0';     

            next_icontrol_state2<=concat;
      
          
        when concat         =>
            in_ready2            <= '0';
        
            input_data2          <= reg_input_data2;
            input_timestamp_snap2<= timestamp_snap2;
            packed_sample2       <= std_logic_vector(reg_sequence_cnt2) & reg_input_data2 & std_logic_vector(timestamp_snap2);
            
            sequence_cnt2        <= reg_sequence_cnt2;
            
            packed_sample_ready2  <= '0';              
          
            next_icontrol_state2 <= store_packed_sample;
                                                           
        when store_packed_sample   =>
            in_ready2   <= '0';
        
            input_data2          <= reg_input_data2;
            input_timestamp_snap2<= timestamp_snap2;
            packed_sample2       <= reg_packed_sample2;            

            sequence_cnt2<=reg_sequence_cnt2;
            
            packed_sample_ready2  <= '1'; 
            

            next_icontrol_state2<=wait_others;      
    end case;                      
end process icontrol2;

ocontrol: process(all)
begin
    case ocontrol_state is
    
        when init               =>
            out_valid        <= '0';
            out_data_input   <= 64B"0";
            
            burst_ready      <=  '0';
        
            next_ocontrol_state<=wait_1st;
        when wait_1st           =>
            out_valid           <=  '0';
            out_data_input      <=  64b"0";
            
            burst_ready         <=  '0';
            if (packed_sample_ready2 and packed_sample_ready1 and packed_sample_ready0)='1' then
                next_ocontrol_state <= wait_others;
            else
                next_ocontrol_state <=wait_1st;
            end if;  
        when wait_others        =>

            out_valid           <=  '0';
            out_data_input            <=  64B"0";
            
            burst_ready         <=  '0'; 
            if out_ready='1' then
                next_ocontrol_state <= output_valid;
            else
                next_ocontrol_state <= wait_others;
            end if;
        when output_valid       =>
            out_valid           <=  '0';
            out_data_input            <=  64B"0";
            
            burst_ready         <=  '0';
        
            next_ocontrol_state<=   out_chan0;
        when out_chan0          =>
            out_valid           <=  '0';
            out_data_input      <=  reg_packed_sample0;
            
            burst_ready <=  '0';
            if out_ready='1' then
                next_ocontrol_state<=signal_chan0;
            else
                next_ocontrol_state<=out_chan0;
            end if;
        when signal_chan0       =>
            out_valid           <= '1';
            out_data_input      <= reg_packed_sample0;
        
            burst_ready         <= '0';
            if out_ready='0' then
                next_ocontrol_state<=out_chan1;        
            else
                next_ocontrol_state<=signal_chan0;
            end if;
            
        when out_chan1          =>
            out_valid           <='0';
            out_data_input      <= reg_packed_sample1;
            
            burst_ready         <= '0';
            if out_ready='1' then  
                next_ocontrol_state<=signal_chan1;
            else
                next_ocontrol_state<=out_chan1;
            end if;
        when signal_chan1          =>
            out_valid              <=      '1';
            out_data_input         <=      reg_packed_sample1;
           
            burst_ready            <=      '0';
            if out_ready='0' then
               next_ocontrol_state <=   out_chan2;
            else
               next_ocontrol_state <=   signal_chan1;                     
            end if;
        
        when out_chan2          =>
            out_valid              <=      '0';
            out_data_input         <=      reg_packed_sample2;
            
            burst_ready            <=      '0';
            if out_ready='1' then
                next_ocontrol_state<= signal_chan2;
            else
                next_ocontrol_state<= out_chan2;
            end if;
        when signal_chan2       =>
            out_valid              <=      '1';
            out_data_input         <=      reg_packed_sample2;
            
            burst_ready            <=      '0';
            if out_ready='0' then
                next_ocontrol_state<= out_term;
            else
                next_ocontrol_state<= signal_chan2;            
            end if;
            
        when out_term           =>
            out_valid           <=          '0';     
            out_data_input            <=          64B"0";
                    
            
            burst_ready         <=          '1';
            
            next_ocontrol_state <=          wait_1st;
    end case;    
end process ocontrol;


end Behavioral;
