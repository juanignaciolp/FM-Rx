%% Manchester decode

function [DecodedBits,state_out]=Manch_decode(bits,state_in)
N=length(bits);
DecodedBits=zeros(N,1);
error3de8=state_in.error;
DecodedBits(1)=state_in.prev_bit;
err_idx=state_in.err_idx;
idx=2;
k=1;
while(k<N)
    if(bits(k)==bits(k+1))
        error3de8(err_idx)=1;
        if sum(error3de8)>2
            error3de8=error3de8*0;
            k=k+1;
        end
    else
        error3de8(err_idx)=0;
    end
    DecodedBits(idx)=bits(k);
    idx=idx+1;
    k=k+2;
    err_idx=mod(err_idx,8)+1;
    
end
DecodedBits=DecodedBits(1:idx);
state_out.prev_bit=DecodedBits(end);
DecodedBits=xor(DecodedBits(1:end-1),DecodedBits(2:end));
state_out.error=error3de8;
state_out.err_idx=err_idx;

end