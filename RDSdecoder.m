function [rds_State]=RDSdecoder(DecodedBits,rds_State)

% Decodificador RDS

%referencia: "EN 50067. Specification of the radio data system (RDS) for
%             VHF/FM sound broadcasting in the frequency range 
%             from 87,5 to 108,0 MHz",EUROPEAN STANDARD, Abril 1998.
 
DecodedBits=[rds_State.lastData;DecodedBits];
while (rds_State.SyncIdx<=length(DecodedBits)-25)   
       if (~rds_State.SyncBlockFlag)
%            [BlockIdx,SyncBlockFlag,SyncIdx]=SyncToBlock(double(DecodedBits),ParityCheckMatrix,Syndromes,SyncBlockFlag,SyncIdx);
           [rds_State.BlockIdx,rds_State.SyncBlockFlag,rds_State.SyncIdx]=SyncToBlock(double(DecodedBits),rds_State.ParityCheckMatrix,rds_State.Syndromes,rds_State.SyncBlockFlag,rds_State.SyncIdx);
           continue;
       end
%        [dummy,BlockIdx,SyncIdx,SyncBlockFlag,RadioTextLoc,radioText]=...
%            DecodeBlock(DecodedBits,BlockIdx,ParityCheckMatrix,Syndromes,SyncIdx,dummy,SyncBlockFlag,RadioTextLoc,radioText); 
       clc;
       [rds_State,DecodedBits]=DecodeBlock(DecodedBits,rds_State); 
       fprintf(1,'Programme Identification (PI):%s\n',rds_State.PI)
       fprintf(1,'Programme Type (PTY)= %d \n',rds_State.PTY)
       fprintf(1,'Programme Service (PS): %s\n',rds_State.PS)
       fprintf(1,'Music/Speech (MS): %d\n',rds_State.MS)
%        fprintf(1,'Traffic Announcement: %d\n',rds_State.TA)
        fprintf(1,'RadioText (RT): %s \n',rds_State.radioText)
end 
rds_State.lastData=DecodedBits(rds_State.SyncIdx:end);
rds_State.SyncIdx=1;
end
function [rds_State,decodedBits]=DecodeBlock(decodedBits,rds_State)

syndrome=CalcSyndrome(decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+25),rds_State.ParityCheckMatrix);

if isequal(syndrome,rds_State.Syndromes(rds_State.BlockIdx,:)) %No hubo error
    rds_State.BlockMOfN(rds_State.BlockMissIdx)= 0;
    
    if (rds_State.BlockIdx==1)
        rds_State.PI=decodeBlock1(rds_State.SyncIdx,decodedBits);
    elseif rds_State.BlockIdx==2
        [rds_State]=decodeBlock2(decodedBits,rds_State);
    elseif (rds_State.BlockIdx==3||rds_State.BlockIdx==4)
        [rds_State]=decodeBlocks34(decodedBits,rds_State);
        
    end
    rds_State.SyncIdx=rds_State.SyncIdx+26;
else %Hubo error de bit o sincronización
%           a=decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+25);
         offset_word=rds_State.offset_words(rds_State.BlockIdx,:);
         [decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+25),corrected]=error_correction(decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+25),offset_word);
%          b=decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+25);
%     
     if (corrected)
        return;
    else
%         %Si no pudo corregirse, registrar error
        rds_State.BlockMOfN(rds_State.BlockMissIdx)=1;
        if sum(rds_State.BlockMOfN)>2
            rds_State.SyncBlockFlag=false;
            rds_State.BlockMOfN = rds_State.BlockMOfN * 0;
            rds_State.GroupType=0;
            rds_State.Version=0;
            rds_State.BlockIdx=rds_State.BlockIdx-1; %Resto 1 para mantener cosistencia al modificar BlockIdx al salir del else
            rds_State.BlockMissIdx=rds_State.BlockMissIdx-11;
        else
            rds_State.SyncIdx=rds_State.SyncIdx+26;
        end
     end
end
rds_State.BlockIdx= mod(rds_State.BlockIdx,4)+1;
rds_State.BlockMissIdx=mod(rds_State.BlockMissIdx,8)+1;
end

function PI=decodeBlock1(SyncIdx,decodedBits)
PI=binaryVectorToHex(decodedBits(SyncIdx:SyncIdx+15).');
end

function [rds_State]=decodeBlock2(decodedBits,rds_State)
rds_State.GroupType=bintonum(decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+3));
rds_State.Version=bintonum(decodedBits(rds_State.SyncIdx+4));
rds_State.PTY=bintonum(decodedBits(rds_State.SyncIdx+6:rds_State.SyncIdx+10));
if (rds_State.GroupType==2 && rds_State.Version==0)
    rds_State.RadioTextLoc=bintonum(decodedBits(rds_State.SyncIdx+12:rds_State.SyncIdx+15));
    
elseif (rds_State.GroupType==0 && rds_State.Version==0)
    rds_State.TA=decodedBits(rds_State.SyncIdx+11);
    rds_State.MS=decodedBits(rds_State.SyncIdx+12);
    rds_State.DI=decodedBits(rds_State.SyncIdx+13);
    rds_State.C1=decodedBits(rds_State.SyncIdx+14);
    rds_State.C0=decodedBits(rds_State.SyncIdx+15);
end

end

function [rds_State]=decodeBlocks34(decodedBits,rds_State)
if (rds_State.GroupType==2 && rds_State.Version==0)
    charact1=char(bintonum(decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+7)));
    charact2=char(bintonum(decodedBits(rds_State.SyncIdx+8:rds_State.SyncIdx+15)));   
%     messageIdx=rds_State.RadioTextLoc*4+(rds_State.BlockIdx-3)*2;
%     rds_State.radioText=[rds_State.radioText(1:messageIdx),charact1,charact2,rds_State.radioText(messageIdx+3:end)];
    
     messageIdx=(rds_State.BlockIdx==4)*2+4*rds_State.RadioTextLoc+1:4*rds_State.RadioTextLoc+2+(rds_State.BlockIdx==4)*2;
     rds_State.radioText(messageIdx)=[charact1,charact2];
    
end
if (rds_State.BlockIdx==3 && rds_State.GroupType==0 && rds_State.Version==0)
   rds_State.AF1= bintonum(decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+7));
   rds_State.AF2= bintonum(decodedBits(rds_State.SyncIdx+8:rds_State.SyncIdx+15));
end
if (rds_State.BlockIdx==4 && rds_State.GroupType==0 && rds_State.Version==0)
    charact1=char(bintonum(decodedBits(rds_State.SyncIdx:rds_State.SyncIdx+7)));
    charact2=char(bintonum(decodedBits(rds_State.SyncIdx+8:rds_State.SyncIdx+15)));
    pos=2*bintonum([rds_State.C1,rds_State.C0])+1;
    rds_State.PS(pos:pos+1)=[charact1,charact2];
    
end
end

function num=bintonum(binword)
binword=flipud(binword(:));
N=length(binword);
num=0;
for k=1:N
     num=num+2^(k-1)*binword(k);
end
end

function syndrome=CalcSyndrome(bits,ParityCheckMatrix)
syndrome=mod(sum(bits.'*ParityCheckMatrix,1),2);  
end

function [BlockIdx_out,SyncBlockFlag,idx]=SyncToBlock(bits,ParityCheckMatrix,Syndromes,SyncBlockFlag,idx)
% bits tiene 26 bits de largo
N=length(bits);
while (idx<=N-25)
    syndrome=CalcSyndrome(bits(idx:idx+25),ParityCheckMatrix);
    [~,BlockIdx_out]=ismember(syndrome,Syndromes,'row');
    if BlockIdx_out
        SyncBlockFlag=true;
        break;
    end
    idx=idx+1;
end
end