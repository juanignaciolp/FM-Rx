  
function [bits,state_out]=CarrierSync(state_in,x)

x=x(:);
N=length(x);
rawbits=zeros(size(x));
rdsReal=real(x(2));
rdsImag=imag(x(2));

err=zeros(size(x)); %phase error
fase=zeros(size(x));% instantaneous phase
a=zeros(size(x)); %integrator output
v=zeros(size(x)); %Loop filter output
% Pll constants
ji=1;% damping factor
BnT=0.05;% normalized Equivalent noise bandwidth
K1=4*ji/(ji+1/(4*ji))*BnT; % Proportional Constant
K2=4/(ji+1/(4*ji))^2*(BnT)^2;% Integration constant

% Initial values;

err(1:2)=state_in.err(end-1:end);
a(1:2)=state_in.a(end-1:end);
rawbits(1:2)=state_in.prev_bits;
fase(1:2)=state_in.fase(end-1:end);
v(1:2)=state_in.v(end-1:end);

for k=3:N

%     err(k)=sign(rdsReal)*rdsImag;
%     a(k)=K2*err(k)+a(k-1);
%     v(k)=K1*err(k)+a(k);
%     fase(k+1)=fase(k)+v(k);
%     rawbits(k+1)=x(k+1)*exp(-1j*fase(k+1));
%     rdsReal = real(rawbits(k+1));
%     rdsImag = imag(rawbits(k+1));

    err(k-1)=sign(rdsReal)*rdsImag;
    a(k-1)=K2*err(k-1)+a(k-2);
    v(k-1)=K1*err(k-1)+a(k-1);
    fase(k)=fase(k-1)+v(k-1);
    rawbits(k)=x(k)*exp(-1j*fase(k));
    rdsReal = real(rawbits(k));
    rdsImag = imag(rawbits(k));
end
state_out.a=a(1:end-1);
state_out.v=v(1:end-1);
state_out.err=err(1:end-1);
state_out.fase=fase;
state_out.prev_bits=rawbits(end-1:end);
bits=rawbits;
% bits=real(rawbits)>0;
end
    
    
        
