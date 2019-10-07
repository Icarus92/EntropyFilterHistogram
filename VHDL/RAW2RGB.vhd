--25.5.14
--Boris Braginsky
--==========Library===========
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_signed.all; 
use ieee.std_logic_arith.all;


entity RAW2RGB is
port(
	oRed, oGreen, oBlue: out std_logic_vector(11 downto 0); 
	oGrey: out std_logic_vector(11 downto 0);
	oDVAL: out std_logic; 
	iX_Cont,	iY_Cont: in std_logic_vector(10 downto 0); 
	iDATA: in std_logic_vector(11 downto 0); 
	iDVAL, iCLK, iRST: in std_logic);
end RAW2RGB; 


architecture behv of RAW2RGB is

component Line_Buffer 
port (clken, clock: in std_logic;
		shiftin: in std_logic_vector(11 downto 0); 
		taps0x, taps1x:	out std_logic_vector(11 downto 0));
end component;

signal 	mDATA_0: std_logic_vector(11 downto 0);
signal	mDATA_1: std_logic_vector(11 downto 0);
signal	mDATAd_0: std_logic_vector(11 downto 0);
signal	mDATAd_1: std_logic_vector(11 downto 0);
signal	mCCD_R: std_logic_vector(11 downto 0);
signal	mCCD_G: std_logic_vector(12 downto 0);
signal	mCCD_B: std_logic_vector(11 downto 0);
signal	mDVAL:  std_logic;
signal   temp:   std_logic_vector(1 downto 0);
signal   grey: std_logic_vector(11 downto 0);
signal  	Red1,Red2,Blue1, Blue2 :		std_logic_vector(11 downto 0);
signal 	Green1,Green2			:	std_logic_vector(12 downto 0);
begin

u0:Line_Buffer
port map (clken=>iDVAL, clock=>iCLK, shiftin=>iDATA, taps0x=>mDATA_1, taps1x=>mDATA_0);

-- The computation that converts the colored image into greyscale 
-- grey = .2126 * R^gamma + .7152 * G^gamma + .0722 * B^gamma
   Red1<= std_logic_vector((SHIFT_RIGHT(ieee.numeric_std.unsigned(mCCD_R), 2)));     --divide by 4
	Red2<= std_logic_vector((SHIFT_RIGHT(ieee.numeric_std.unsigned(mCCD_R), 5)));		 --divide by 32 

	Green1<= std_logic_vector((SHIFT_RIGHT(ieee.numeric_std.unsigned(mCCD_G), 1)));	 --divide by 2
	Green2<= std_logic_vector((SHIFT_RIGHT(ieee.numeric_std.unsigned(mCCD_G), 4)));   --divide by 16

	Blue1<= std_logic_vector((SHIFT_RIGHT(ieee.numeric_std.unsigned(mCCD_B), 4)));    --divide by 16
	Blue2<= std_logic_vector((SHIFT_RIGHT(ieee.numeric_std.unsigned(mCCD_B), 5)));	 --divide by 32

	grey <= Red1+Red2 + Green1(12 downto 1)+Green2(12 downto 1) + Blue1+Blue2;			 

	
oGrey <= grey;
oRed	<=	mCCD_R;
oGreen <= mCCD_G(12 downto 1);
oBlue	<=	mCCD_B;
oDVAL	<=	mDVAL;
temp <=iY_Cont(0) & iX_Cont(0);

process(iCLK, iRST)
begin
	if(iRST = '0') then 
		mCCD_R	<=	"000000000000";
		mCCD_G	<=	"0000000000000";
		mCCD_B	<=	"000000000000";
		mDATAd_0<=	"000000000000";
		mDATAd_1<=	"000000000000";
		mDVAL	<=	'0';
	else
		mDATAd_0	<=	mDATA_0;
		mDATAd_1	<=	mDATA_1;
		if (iY_Cont(0) = '1' or iX_Cont(0) = '1') then 
			mDVAL		<=	'0';
		else
			mDVAL    <=	iDVAL;
		end if; 
		if(temp = "10") then
			mCCD_R	<=	mDATA_0;
			mCCD_G	<=	('0' & mDATAd_0) + ('0'&mDATA_1);
			mCCD_B	<=	mDATAd_1; 
		elsif(temp ="11") then
			mCCD_R	<=	mDATAd_0;
			mCCD_G	<=	('0'&mDATA_0)+('0'&mDATAd_1);
			mCCD_B	<=	mDATA_1;
		elsif(temp = "00") then
			mCCD_R	<=	mDATA_1;
			mCCD_G	<=	('0'&mDATA_0)+('0'&mDATAd_1);
			mCCD_B	<=	mDATAd_0;
		elsif(temp = "01") then
			mCCD_R	<=	mDATAd_1;
			mCCD_G	<=	('0'&mDATAd_0)+('0'&mDATA_1);
			mCCD_B	<=	mDATA_0;
		end if;
	end if;
end process;

end behv;