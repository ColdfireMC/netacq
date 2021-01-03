library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity timestamp_patch is
      port (clock               : in std_logic;
             reset               : in std_logic;
             -- input interface
             in_ready          : out std_logic;
             in_valid          : in std_logic;
             in_data           : in std_logic_vector(15 downto 0);
             -- output interface
             out_ready         : in std_logic;
             out_valid         : out std_logic;
             out_data          : out std_logic_vector(63 downto 0));
end timestamp_patch;

architecture Behavioral of timestamp_patch is
signal  timestamp,timestamp_snap, input_timestamp_snap :   unsigned(31 downto 0);
signal  reg_input_data, input_data                     :   std_logic_vector(15 downto 0);
signal  packed_sample, reg_packed_sample               :   std_logic_vector(63 downto 0);
signal  sample_register_ena, ready_snap_ena            :   std_logic;
signal  reg_sequence_cnt, sequence_cnt                 :   unsigned(15 downto 0);

type state_iocontrol_process is (init, wait_1st, wait_others, input_valid, concat, output_valid); 
signal iocontrol_state, next_iocontrol_state    :     state_iocontrol_process;

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

input_data_register: process(clock, reset)
begin
    if reset='1' then
        reg_input_data <= 16B"0";
    elsif rising_edge(clock) then
        reg_input_data<=input_data;
    end if;
end process input_data_register;

timestamp_snap_reg: process(clock, reset)
begin
    if reset='1' then
        timestamp_snap <= to_unsigned(0, timestamp'length);
    elsif rising_edge(clock) then
        timestamp_snap<=input_timestamp_snap;
    end if;
end process timestamp_snap_reg;

packed_sample_register: process(clock, reset)
begin
    if reset='1' then
        reg_packed_sample <= 64B"0";
    elsif rising_edge(clock) then
        reg_packed_sample<=packed_sample;
    end if;
end process packed_sample_register;

timestamp_counter: process(clock, reset)
begin
    if reset='1' then
        timestamp <= to_unsigned(0, timestamp'length);
    elsif rising_edge(clock) then
        timestamp<=timestamp + 1;
    end if;
end process timestamp_counter;

sequence_counter: process(clock, reset)
begin
    if reset='1' then
        reg_sequence_cnt <= to_unsigned(0, reg_sequence_cnt'length);
    elsif rising_edge(clock) then
        reg_sequence_cnt<=sequence_cnt;
    end if;
end process sequence_counter;

io_state: process (clock, reset)
begin
    if reset='1' then
        iocontrol_state<=init;
    elsif rising_edge(clock) then
        iocontrol_state<=next_iocontrol_state;
    end if;
end process io_state;  

iocontrol: process(all)
begin
    case iocontrol_state is
        when init           =>
            in_ready   <= '0';
            out_valid  <= '0';
            input_data          <= reg_input_data;
            input_timestamp_snap<= timestamp_snap;
            packed_sample       <= reg_packed_sample;
            
            
            sequence_cnt<=reg_sequence_cnt; 
            
            next_iocontrol_state<=wait_1st;
          
        when wait_1st       =>
            in_ready   <= '1';
            out_valid  <= '0';
            input_data          <= in_data;
            input_timestamp_snap<= timestamp_snap;
            packed_sample       <= reg_packed_sample;
            
            sequence_cnt<=reg_sequence_cnt; 
                                 
            if in_valid='1' then
                next_iocontrol_state<=input_valid;
            else
                next_iocontrol_state<=wait_1st;
            end if;
        when wait_others    =>
            in_ready   <= '1';
            out_valid  <= '1';
            input_data          <= reg_input_data;
            input_timestamp_snap<= timestamp_snap;
            packed_sample       <= reg_packed_sample;
            
            sequence_cnt<=reg_sequence_cnt;
            
            
            if in_valid='1' and out_ready='1' then
                next_iocontrol_state<=input_valid;
            elsif out_ready='0' then
                next_iocontrol_state<=wait_1st;
            else 
                next_iocontrol_state<=wait_others;
            end if;
                              
        when input_valid    =>
            in_ready   <= '0';
            out_valid  <= '0';
            
            input_data          <= in_data;
            input_timestamp_snap<= timestamp;
            packed_sample       <= reg_packed_sample;
            
            sequence_cnt<=reg_sequence_cnt+1;     

            next_iocontrol_state<=concat;
      
        when concat         =>
            in_ready   <= '0';
            out_valid  <= '0';
        
            input_data          <= reg_input_data;
            input_timestamp_snap<= timestamp_snap;
            packed_sample       <= std_logic_vector(reg_sequence_cnt) & reg_input_data & std_logic_vector(timestamp_snap) ;
            
            sequence_cnt<=reg_sequence_cnt; 
              
          
                next_iocontrol_state<=output_valid;
                                                           
        when output_valid    =>
            in_ready   <= '0';
            out_valid  <= '0';
        
            input_data          <= reg_input_data;
            input_timestamp_snap<= timestamp_snap;
            packed_sample       <= reg_packed_sample;            

            sequence_cnt<=reg_sequence_cnt; 
            

            next_iocontrol_state<=wait_others;


                       
    end case;            
            


end process iocontrol;
out_data<=packed_sample;

end Behavioral;
