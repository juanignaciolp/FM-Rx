function [output,corrected]=error_correction(Data_Bits,offset_word)
% Radio Data System (RDS) error correction function. 
%
% Usage [output,corrected]=error_correction(Data_Bits,offset_word)
%
% Data_Bits: size=[26,1]. 26 bit long received block. 
% offset_word: size=[1,10]. Offset word corresponding to the detected block
%              (A, B, C, Cp or D)
% corrected: size=[1,1]. Flag indicating that the word has been corrected.
% output: size=[26,1]. Corrected block. It's a corrected block if corrected
%         flag is true. Otherwise, it contains no valid code words and
%         should be discarded.
%
%This function implements the error correction function using the Meggitt
%error-trapped technique. It can correct up to 5 bits long burst errors. 
%reference: "EN 50067. Specification of the radio data system (RDS) for
%             VHF/FM sound broadcasting in the frequency range 
%             from 87,5 to 108,0 MHz",EUROPEAN STANDARD, Abril 1998.
%             Section B.2.2
%
%---------------- Coded by Juan Ignacio Fernández M. -2022- --------------- 
 
Data_Bits=reshape(Data_Bits,[1,length(Data_Bits)]); %Re-arrange input data
N=26; %Block lenght
K=16; %code-word length
m=5; % Number of bits of the window for the Meggitt error-trapped decoder
GATE_A_CLOSED=false;
corrected = false; 
divisor=441; %[1 1 0 1 1 1 0 0 1]. Generator polinomial with MSB equal to zero
multiplier=794;%[1 1 0 0 0 1 1 0 1 0] Pre-Multiplier with LSB equal to zero 
buffer_reg=Data_Bits(1:K);
check_bits=Data_Bits(K+1:end);
corrected_word=zeros(1,K);
syndrome_reg=zeros(1,N-K);

%substruct the offset word
Data_Bits=[Data_Bits(1:K) bitxor(check_bits,offset_word)];

%Obtain the syndrome: 
%perfom a pre multiplication by [1 1 0 0 0 1 1 0 1 1] and the remainder of
%the division by g(x)=[1 0 1 1 0 1 1 1 0 0 1].
for k=1:N
    divide=syndrome_reg(1);
    syndrome_reg=[syndrome_reg(2:end) Data_Bits(k)];% left-circshift with input bit in LSB position 
    if divide %perform division if MSB of syndrome_reg is 1
        syndrome_reg= dec2bin(bitxor(binaryVectorToDecimal(syndrome_reg),divisor),N-K)-'0';
    end
    if Data_Bits(k)% perform multiplication if input bit is 1
        syndrome_reg=dec2bin(bitxor(binaryVectorToDecimal(syndrome_reg),multiplier),N-K)-'0';
    end
end
% Continue for K more cycles to trap and correct the error.
for k=1:K
    if  ~bitand(binaryVectorToDecimal(syndrome_reg),2^m-1) % Are the 5 LSB of syndrome_reg equal to 0?
        GATE_A_CLOSED=true; %if true, error pattern is trapped in the 5 MSB of syndrome_reg. Stop feedback of syndrome_reg and correct the error
%         corrected=true;     
    end
    divide=syndrome_reg(1);
    syndrome_reg=[syndrome_reg(2:end) 0];% left-circshift with zero input in LSB position 
    corrected_word(k)=buffer_reg(k);
    if divide %if MSB of syndrome_reg is 1..
        if GATE_A_CLOSED %if error was trapped 
            corrected_word(k)=bitxor(corrected_word(k),1); %correct current bit
            corrected=true;
        else
            syndrome_reg= dec2bin(bitxor(binaryVectorToDecimal(syndrome_reg),divisor),N-K)-'0'; %perform division
        end
    end
end
output=[corrected_word check_bits].'; 
end
