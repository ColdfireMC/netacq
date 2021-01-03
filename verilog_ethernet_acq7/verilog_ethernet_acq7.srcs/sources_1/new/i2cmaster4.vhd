------------------------------------------------------------------------
-- Author: Luke Renaud 
--	Copyright 2011 Digilent, Inc.
------------------------------------------------------------------------
-- Module description
--		This module manages the full I/O of the system. The 100MHz clock
--		is fed through two clock dividers to produce a 100KHz signal and
--		a 100Hz signal. The 100KHz signal is used to interface with two
--		Pmod's to send out an arbitrary number, convert it to an analog
--		value, then to convert it back into a digital number.
--		
--		The 100Hz clock is used to drive the counter that controls what number
--		should currently be stored in the DA1, and the target value that
--		the AD2 is trying to read.
--
--		Chipscope may then be used to read the state of the board. The lower
--		12 bits of the wRetSignal0 will contain the ADC value, this will be
--		shown in comparision to the 8-bits sent to the DAC.
--	
--		To compare the values graphically, select signals 0 through 11 in the
--		Signals pane, right click, and select copy to new bus. Then select
--		signals 4 through 11 and select move to new bus. Finally select signals
--		12 through 19 and select move to new bus. This should result in three
--		busses which can be ploted in the Bus Plot section of ChipScope for
--		comparision.
--
--  Inputs:
--		RESET			Main Reset Controller
--		sys_clock		100MHz onboard system clock
--		AD2_SDA		PmodAD2 I2C interface In/Out data line
--		AD2_SCL		PmodAD2 I2C interface In/Out clock line
--
--  Outputs:
--		DA1_SYNC		PmodDA1 select line (labeled SYNC on the PCB)
--		DA1_SCLK		PmodDA1 select data clock line. 
--		DA1_SD0		PmodDA1 serial data channel 0
--		DA1_SD1		PmodDA1 serial data channel 1
--		DCH0			The output of the PmodAD2, tied to an output so that the optomizer
--							doesn't remove it.
--		CHIP_EXT		Trigger signal for Chipscope to sample.
--
------------------------------------------------------------------------
-- Revision History:
--
--	05/20/2011(Luke Renaud): created
--	06/01/2011(Luke Renaud): Modified for PmodAD2
--  10/9/2020 (Alejandro Estay: Modificado para no usar reset
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;
use UNISIM.VComponents.all;
entity i2cmaster4 is
    Port ( AD2_SCLA, AD2_SCLB, AD2_SCLC	    : inout	    STD_LOGIC;
  		   AD2_SDAA, AD2_SDAB, AD2_SDAC	    : inout	    STD_LOGIC;
--------------------------------Salida de datos AXI-Stream--------------------------------------		   
           aclk                             : in  std_logic;
           clki2c                           : in  std_logic;                    
           areset                           : in  std_logic;                     
           tvalid                           : out std_logic;                     
           tdata                            : out std_logic_vector(7 downto 0);  
           tready                           : in  std_logic;                     
           tlast                            : out std_logic;                     
           tuser                            : out std_logic;
-------------------------------------------------------------------------------------------------
--           local_ip_addr                    : in  std_logic_vector(31 downto 0);
--           dest_ip_addr                     : in  std_logic_vector(31 downto 0);
--           local_macaddr                    : in  std_logic_vector(47 downto 0);
--           dscp                             : in  std_logic_vector(5 downto 0);
--           ttl                              : in  std_logic_vector(7 downto 0);
--           ecn                              : in  std_logic_vector(1 downto 0);
--           src_port                         : in  std_logic_vector(15 downto 0);
--           dest_port                        : in  std_logic_vector(15 downto 0);
-------------------------------------------------------------------------------------------------
           hdr_tvalid                       : out std_logic;                     
           hdr_tready                       : in  std_logic                     
--           hdr_ip_dscp                      : out std_logic_vector(5 downto 0);  
--           hdr_ip_ecn                       : out std_logic_vector(1 downto 0);  
--           hdr_ip_ttl                       : out std_logic_vector(7 downto 0);  
--           hdr_ip_source_ip                 : out std_logic_vector(31 downto 0); 
--           hdr_ip_dest_ip                   : out std_logic_vector(31 downto 0); 
--           hdr_source_port                  : out std_logic_vector(15 downto 0); 
--           hdr_dest_port                    : out std_logic_vector(15 downto 0); 
--           hdr_length                       : out std_logic_vector(15 downto 0); 
--           hdr_checksum                     : out std_logic_vector(15 downto 0)
);                
end i2cmaster4;


architecture Behavioral of i2cmaster4 is

	------------------------------------------------------------------------
	-- Component Declarations
	------------------------------------------------------------------------

	--  Project Components
component timestamp_patch_3 is
     Port (clock             : in std_logic;
           reset             : in std_logic;
           -- input interface0
           in_ready0         : out std_logic;
           in_valid0         : in std_logic;
           in_data0          : in std_logic_vector(15 downto 0);
           -- input interface1
           in_ready1         : out std_logic;
           in_valid1         : in std_logic;
           in_data1          : in std_logic_vector(15 downto 0);
           -- input interface2
           in_ready2         : out std_logic;
           in_valid2         : in std_logic;
           in_data2          : in std_logic_vector(15 downto 0);                      
                      
           -- output interface
           out_ready         : in std_logic;
           out_valid         : out std_logic;
           out_data          : out std_logic_vector(63 downto 0));
end component;

component pmodAD2_ctrl is
     generic(pmod_config    : in        std_logic_vector(7 downto 0));
	 Port (mainClk	    	: in		STD_LOGIC;
	       SDA_mst	    	: inout	STD_LOGIC;
	       SCL_mst		    : inout	STD_LOGIC;    	
	       wData0	    	: out		STD_LOGIC_VECTOR(15 downto 0);
	       rst			    : in		STD_LOGIC;
	       output_ready_p   : out       STD_LOGIC);
	end component;
--component samplefifo is                                                              
--    generic (ram_width : natural);                                                     
--    port (clock               : in std_logic;                                       
--          reset               : in std_logic;                                       
--          ---fuentes de interrupciÃ³n------                                        
--          almost_full_irq   : out std_logic;                                      
--          almost_empty_irq  : out std_logic;                                      
--          full_irq          : out std_logic;                                      
--          empty_irq         : out std_logic;                                      
--          -- input interface                                                      
--          in_ready          : out std_logic;                                      
--          in_valid          : in std_logic;                                       
--          in_data           : in std_logic_vector(ram_width - 1 downto 0);        
--          -- output interface                                                     
--          out_ready         : in std_logic;                                       
--          out_valid         : out std_logic;                                      
--          out_data          : out std_logic_vector(ram_width - 1 downto 0));      
--end component;  

component fifo_comp_axi_s is                                                              
    generic (ram_width : natural);                                                     
    port (i2clk               : in std_logic;                                                                        
          ---fuentes de interrupciÃ³n------                                        
          almost_full_irq   : out std_logic;                                      
          almost_empty_irq  : out std_logic;                                      
          full_irq          : out std_logic;                                      
          empty_irq         : out std_logic;                                      
          -- input interface                                                      
          in_ready          : out std_logic;                                      
          in_valid          : in std_logic;                                       
          in_data           : in std_logic_vector(ram_width - 1 downto 0);        
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
end component;  



--component string_gen_3 is
--    port (--------input interface
--          in_ready                      : out std_logic;
--          in_valid                      : in std_logic;
--          in_data                       : in std_logic_vector(63 downto 0);
--          ------------------------config input--------------------
--          local_ip_addr                 : in  std_logic_vector(31 downto 0);
--          dest_ip_addr                  : in  std_logic_vector(31 downto 0);
--          local_macaddr                 : in  std_logic_vector(47 downto 0);
--          dscp                          : in  std_logic_vector(5 downto 0);
--          ttl                           : in  std_logic_vector(7 downto 0);
--          ecn                           : in  std_logic_vector(1 downto 0);
--          src_port                      : in  std_logic_vector(15 downto 0);
--          dest_port                     : in  std_logic_vector(15 downto 0);                
--          -------------------------------- AXI-Stream-out-------------
--          aclk                          : in  std_logic;
--          areset                        : in  std_logic;
--          tvalid                        : out std_logic;
--          tdata                         : out std_logic_vector(7 downto 0);
--          tready                        : in  std_logic;
--          tlast                         : out std_logic;
--          tuser                         : out std_logic;       
--          ---------------------- AXI-Stream-hdr-out-------------
--          hdr_tvalid                    : out std_logic;                     
--          hdr_tready                    : in  std_logic;                     
--          hdr_ip_dscp                   : out std_logic_vector(5 downto 0);  
--          hdr_ip_ecn                    : out std_logic_vector(1 downto 0);  
--          hdr_ip_ttl                    : out std_logic_vector(7 downto 0);  
--          hdr_ip_source_ip              : out std_logic_vector(31 downto 0); 
--          hdr_ip_dest_ip                : out std_logic_vector(31 downto 0); 
--          hdr_source_port               : out std_logic_vector(15 downto 0); 
--          hdr_dest_port                 : out std_logic_vector(15 downto 0); 
--          hdr_length                    : out std_logic_vector(15 downto 0); 
--          hdr_checksum                  : out std_logic_vector(15 downto 0));          
--end component;

--component string_gen_4 is
--    port (------------------------input interface-----------------------
--          in_ready                      : out std_logic;
--          in_valid                      : in std_logic;
--          in_data                       : in std_logic_vector(63 downto 0);          
--          -------------------------------- AXI-Stream-out-------------
--          aclk                          : in  std_logic;
--          areset                        : in  std_logic;
--          tvalid                        : out std_logic;
--          tdata                         : out std_logic_vector(7 downto 0);
--          tready                        : in  std_logic;
--          tlast                         : out std_logic;
--          tuser                         : out std_logic;       
--          ---------------------- AXI-Stream-hdr-out------------------------
--          hdr_tvalid                    : out std_logic;                     
--          hdr_tready                    : in  std_logic);          
--end component;
------------------------------------------------------------------------
-- General control and timing signals
------------------------------------------------------------------------
signal sys_clock : STD_LOGIC;
signal clockInternal : STD_LOGIC;
signal clockTrigger : STD_LOGIC;
signal chipscopeSample : STD_LOGIC;
signal fTxDone : STD_LOGIC;
signal fRxDone : STD_LOGIC;
signal fRstTXCtrl : STD_LOGIC;
signal fRstRXCtrl : STD_LOGIC;

------------------------------------------------------------------------
-- Data path signals
------------------------------------------------------------------------
signal wValue : STD_LOGIC_VECTOR(7 downto 0);
signal wValueReverse : STD_LOGIC_VECTOR(7 downto 0);
signal wOutSignal0 : STD_LOGIC_VECTOR(15 downto 0);
signal wOutSignal1 : STD_LOGIC_VECTOR(15 downto 0);
signal wRetSignal0 : STD_LOGIC_VECTOR(15 downto 0);
signal wRetSignal1 : STD_LOGIC_VECTOR(15 downto 0);
signal wRetSignal2 : STD_LOGIC_VECTOR(15 downto 0);
signal packed      : STD_LOGIC_VECTOR(63 downto 0);
signal SDA_ctrl : STD_LOGIC;
signal SCL_ctrl : STD_LOGIC;
signal ready_timestamp0, ready_timestamp1, ready_timestamp2  :    std_logic;
signal output_valid           : STD_LOGIC;
 


 
 ------------------------------------------------------------------------
 -- fifo                                                    
 ------------------------------------------------------------------------
signal almost_full_irq        : std_logic;
signal almost_empty_irq       : std_logic;
signal full_irq               : std_logic;
signal empty_irq              : std_logic;
-- input interface    
signal in_ready_fifo          : std_logic;
signal in_valid_fifo          : std_logic;
signal in_data_fifo           : std_logic_vector(63 downto 0);
-- output interface    
signal out_ready_fifo         : std_logic;
signal out_valid_fifo         : std_logic;
signal out_data_fifo          : std_logic_vector(63 downto 0);          
 
------------------------------------------------------------------------  
-- string generator                                                  
------------------------------------------------------------------------ 
signal in_ready_string        : std_logic;                         
signal in_valid_string        : std_logic;                          
signal in_data_string         : std_logic_vector(63 downto 0);     
  -- output interface                                                 
--signal out_ready_string       : std_logic;                         
--signal out_valid_string       : std_logic;                         
--signal out_data_string        : std_logic_vector(7 downto 0);         
--signal out_ready_string_n     : std_logic;
--signal out_last_string        : std_logic;      
------------------------------------------------------------------------
-- Implementation
------------------------------------------------------------------------
begin
----------------------------------------------------------------------Componentes----------------------------------------------
analogReciever1: pmodAD2_ctrl
           generic map(
           pmod_config         => "00010100")  
           PORT MAP(
		   mainClk             =>  clki2c,
		   SDA_mst             =>  AD2_SDAA,
		   SCL_mst             =>  AD2_SCLA,
		   wData0              =>  wRetSignal0,
		   rst                 =>  fRstRXCtrl,
		   output_ready_p=>ready_timestamp0);
analogReciever2: pmodAD2_ctrl
           generic map(
           pmod_config         => "00100100")  
           PORT MAP(
           mainClk             =>  clki2c,
           SDA_mst             =>  AD2_SDAB,
           SCL_mst             =>  AD2_SCLB,
           wData0              =>  wRetSignal1,
           rst                 =>  fRstRXCtrl,
           output_ready_p=>ready_timestamp1);
analogReciever3: pmodAD2_ctrl
           generic map(
           pmod_config         => "01000100") 
           PORT MAP(
           mainClk             =>  clki2c,
           SDA_mst             =>  AD2_SDAC,
           SCL_mst             =>  AD2_SCLC,
           wData0              =>  wRetSignal2,
           rst                 =>  fRstRXCtrl,
           output_ready_p=>ready_timestamp2);
		   
timestamp_cnt: timestamp_patch_3 Port map(         
           clock               => clki2c,
           reset               => fRstRXCtrl,
           -- input interface
           in_ready0            =>open,
           in_valid0            => ready_timestamp0,
           in_data0             => wRetSignal0,
           -- input interface
           in_ready1            =>open,
           in_valid1            => ready_timestamp1,
           in_data1             => wRetSignal1,
           -- input interface
           in_ready2            =>open,
           in_valid2            => ready_timestamp2,
           in_data2             => wRetSignal2,                                 
           -- output interface
           out_ready           => in_ready_fifo,
           out_valid           => output_valid,
           out_data            => packed); 

--fifo_comp: samplefifo generic map (ram_width => 64)                                                     
--           port map(clock      => sys_clock,
--           reset               => fRstRXCtrl,
--           ---fuentes de interrupción------
--           almost_full_irq     => almost_full_irq,
--           almost_empty_irq    => almost_empty_irq,
--           full_irq            => full_irq,
--           empty_irq           => empty_irq,
--           -- input interface          
--           in_ready            => in_ready_fifo,
--           in_valid            => output_valid,
--           in_data             => packed,
--           -- output interface      
--           out_ready           => out_ready_fifo,
--           out_valid           => out_valid_fifo,
--           out_data            => out_data_fifo);   

fifo_comp: fifo_comp_axi_s generic map (ram_width => 64)      
           port map(i2clk      => clki2c,                         
                    ---fuentes de interrupción------              
                    almost_full_irq     => almost_full_irq,       
                    almost_empty_irq    => almost_empty_irq,      
                    full_irq            => full_irq,              
                    empty_irq           => empty_irq,             
                    -- input interface                            
                    in_ready            => in_ready_fifo,         
                    in_valid            => output_valid,          
                    in_data             => packed,                
---------------------Axi-Stream out interface-----------------------------------------
                    aclk                          => sys_clock,
                    areset                        => fRstRXCtrl,
                    tvalid                        =>  tvalid,
                    tdata                         =>  tdata,
                    tready                        =>  tready,
                    tlast                         =>  tlast,
                    tuser                         =>  tuser,
--------------------------------------------------------------------------------------
                    hdr_tvalid                    =>  hdr_tvalid,
                    hdr_tready                    =>  hdr_tready);

--out_ready_string_n <= not out_ready_string;




--string_generator: string_gen_4 port map(
--           aclk                          =>  sys_clock,
--           areset                        =>  fRstRXCtrl,
-----------------------in interface-----------------------------------------------------
--           in_ready                      =>  out_ready_fifo,
--           in_valid                      =>  out_valid_fifo,
--           in_data                       =>  out_data_fifo,
-----------------------Axi-Stream out interface-----------------------------------------
--           tvalid                        =>  tvalid,
--           tdata                         =>  tdata,
--           tready                        =>  tready,
--           tlast                         =>  tlast,
--           tuser                         =>  tuser,
----------------------------------------------------------------------------------------
--           hdr_tvalid                    =>  hdr_tvalid,
--           hdr_tready                    =>  hdr_tready);
fRstRXCtrl  <= areset;
sys_clock   <= aclk; 
end Behavioral;