function [y,IC_out]= FI_tune(raw,fFI,fs,FIR_num,IC_FIR)
N=length(raw);
if isreal(raw)
    raw_cplx=raw(:,1)+1j*raw(:,2);
else
    raw_cplx=raw;
end
x=raw_cplx.*exp(-1j*2*pi*fFI*(0:N-1).'/fs);
[y,IC_out]=filter(FIR_num,1,x,IC_FIR);
end