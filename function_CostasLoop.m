function [carrier,Ibranch,Qbranch,CostasLoop_state_out]=function_CostasLoop(CostasLoop_state,x)
x=x(:);
CostasLoop_state_out=CostasLoop_state;
CostasLoop_state_out.empty=false;
N=length(x);

acc=zeros(N,1);
x_vco=zeros(N,1);
x_vco_q=zeros(N,1);
theta_e=zeros(N,1);
e=zeros(N,1);

M=CostasLoop_state.M;
acc(1)=CostasLoop_state.accumulator;
theta_e(1)=CostasLoop_state.theta_e;
e(1)=CostasLoop_state.e;
f0=CostasLoop_state.f0;
fs=CostasLoop_state.fs;
% Den=CostasLoop_state.filtro_de_lazo.Den;
% Num=CostasLoop_state.filtro_de_lazo.Num;
Kp=CostasLoop_state.filtro_de_lazo.Kp;
Ki=CostasLoop_state.filtro_de_lazo.Ki;
NumHilb=CostasLoop_state.NumHilb;
%%%%%%%%%%%%%%%%%%  LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% [xq,CostasLoop_state.Hilb_ic]=filter(NumHilb,1,x,CostasLoop_state.Hilb_ic);
%ecualización de retardo
% xq=xq(1+floor(length(NumHilb)/2):end); 
% xi=x(1:end-floor(length(NumHilb)/2));
 
xq=imag(hilbert(x));
xi=real(hilbert(x));
%  
% xi=x;
Ibranch=zeros(size(xi));
Qbranch=zeros(size(xq));
dummy=CostasLoop_state.filtro_de_lazo.prev_int_out;
for n=2:length(xi)
    
    %----- VCO-----------------------------------------------------
    acc(n)=acc(n-1)+2*pi*f0/fs+e(n-1); %fase instantánea de salida del VCO
    if(acc(n)>pi)
        acc(n)=acc(n)-2*pi;
    end
    x_vco(n)=cos(acc(n)/M);
    x_vco_q(n)=sin(acc(n)/M);
    Ibranch(n)=xi(n)*x_vco(n)+xq(n)*x_vco_q(n);
    Qbranch(n)=xq(n)*x_vco(n)-xi(n)*x_vco_q(n);
    
    %----------Detector de Fase-----------------------------------------------
     theta_e(n)= atan((xq(n)*real(x_vco(n))-xi(n)*x_vco_q(n))...
         /(xi(n)*x_vco(n)+xq(n)*x_vco_q(n))); %Error de fase (salida del detector de fase)
%     theta_e(n)=angle(x(n)*conj(x_vco(n)+1j*x_vco_q(n)));
     if isnan(theta_e(n))
         theta_e(n)=0;
     end
   % ------------------------Filtro de Lazo------------------------------------
%     e(n)=-Den(2)/Den(1)*e(n-1)+Num(1)/Den(1)*theta_e(n)+Num(2)/Den(1)*theta_e(n-1);
     dummy=dummy+Ki*theta_e(n);
    e(n)=Kp*theta_e(n)+dummy;
end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CostasLoop_state_out.accumulator=acc(n);
CostasLoop_state_out.theta_e=theta_e(n);
CostasLoop_state_out.e=e(n);
CostasLoop_state_out.filtro_de_lazo.prev_int_out=dummy;
carrier=cos(acc(2:n));

end