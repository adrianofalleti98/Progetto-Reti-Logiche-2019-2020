library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    Port ( i_clk : in std_logic;
           i_start : in std_logic;
           i_rst : in std_logic;
           i_data : in std_logic_vector (7 downto 0);
           o_address : out std_logic_vector (15 downto 0);
           o_done : out std_logic;
           o_en : out std_logic;
           o_we : out std_logic;
           o_data : out std_logic_vector (7 downto 0)
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state_type is (idle,get_address,wait_ram_1,cicle,wait_ram_2,do_not_encode,encode,done);
    signal current_state : state_type;
   
    
    begin
         state_reg:process(i_rst,i_clk)
         variable address_to_be_encoded: std_logic_vector(7 downto 0) := (others =>'0');
         variable counter :unsigned(15 downto 0) := (others => '0');
         variable wd_base_address : std_logic_vector(7 downto 0):= (others =>'0');
         variable one_hot : std_logic_vector(3 downto 0);
       
            begin
                if (i_rst = '1')  then
                     current_state <= idle;
                     o_done <= '0';
                elsif rising_edge(i_clk) then
                case current_state is
                    when idle => 
                        if (i_start = '1') then
                            o_en <= '1'; 
                            o_address <= x"0008";
                            counter := (others => '0'); 
                            current_state <= get_address;
                          
                        else 
                            o_done <= '0'; 
                            current_state <= idle;
                        end if;
                    when get_address =>                      
                        current_state <= wait_ram_1;
                    when wait_ram_1 => 
                        address_to_be_encoded := i_data; 
                        o_address <= std_logic_vector(counter);
                        current_state <= cicle;
                    when cicle =>  
                        current_state <= wait_ram_2;
                    when wait_ram_2 =>
                       wd_base_address := i_data; 
                       if ((unsigned(wd_base_address) > unsigned(address_to_be_encoded)) or ((unsigned(wd_base_address)+4) < unsigned(address_to_be_encoded)) or  (unsigned(wd_base_address)+4) = unsigned(address_to_be_encoded)) then
                            current_state <= cicle;
                            counter := counter + 1;
                            o_address <= std_logic_vector(counter);
                       elsif (counter = 8) then 
                            current_state <= do_not_encode;
                       else 
                            current_state <= encode;
                       end if;
                    when do_not_encode =>
                            o_we <= '1'; 
                            o_address <= "0000000000001001";
                            o_data <= '0' & address_to_be_encoded(6 downto 0); 
                            current_state <= done;
                    when encode => 
                            o_we <= '1';
                            o_address <= x"0009";
                            one_hot := (others => '0');
                            one_hot( to_integer(unsigned(address_to_be_encoded))- to_integer(unsigned(wd_base_address))) := '1';
                            o_data <= '1' & std_logic_vector(counter(2 downto 0)) & one_hot;
                            current_state <= done; 
                    when done => 
                            counter := (others =>'0');
                            o_we <= '0';
                           if (current_state /= idle) then
                                o_done <= '1';
                           end if;
                            if i_start = '0' or i_rst = '1' then
                                current_state <= idle;
                                o_done <= '0';
                            end if;    
                    end case;  
                    end if;    
              end process;
end Behavioral;