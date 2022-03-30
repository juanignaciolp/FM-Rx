function [y,pll_state_out,theta_e,acc]=function_pll(pll_state,x)

pll_state_out=pll_state;
pll_state_out.empty=false;
N=length(x);

acc=zeros(N,1);
x_vco=zeros(N,1);
x_vco_q=zeros(N,1);
theta_e=zeros(N,1);
e=zeros(N,1);

M=pll_state.M;
acc(1)=pll_state.accumulator; 

% fprintf(1,'acc(1)=%f\n',acc(1));
% theta_e(1)=pll_state.theta_e;
e(1)=pll_state.e;
% fprintf(1,'e(1)=%f\n',e(1));

f0=pll_state.f0;
fs=pll_state.fs;
Kp=pll_state.filtro_de_lazo.Kp;
Ki=pll_state.filtro_de_lazo.Ki;
% NumHilb=[0 -0.0960625074558434 0 -0.0738735967074135 0, ...
%         -0.114550630898285 0 -0.204297562619967 0,... 
%         -0.633937925126545 0 0.633937925126545 0,... 
%         0.204297562619967 0 0.114550630898285 0,... 
%         0.0738735967074135 0 0.0960625074558434 0];
NumHilb=[ 0.000022, -0.007258, -0.000007, -0.005626, 0.000002,...
     -0.007766, 0.000003, -0.010415, 0.000005, -0.013676,...
     0.000006, -0.017690, 0.000004, -0.022653, 0.000005,...
     -0.028857, 0.000005, -0.036778, -0.000005, -0.047247,...
     0.000001, -0.061816, -0.000005, -0.083869, -0.000000,...
     -0.122190, -0.000000, -0.209096, 0.000001, -0.635578,...
     0.000000, 0.635578, -0.000001, 0.209096, 0.000000,...
     0.122190, 0.000000, 0.083869, 0.000005, 0.061816,...
     -0.000001, 0.047247, 0.000005, 0.036778, -0.000005,...
     0.028857, -0.000005, 0.022653, -0.000004, 0.017690,...
     -0.000006, 0.013676, -0.000005, 0.010415, -0.000003,...
     0.007766, -0.000002, 0.005626, 0.000007, 0.007258 ,-0.000022];    
    
    % Estado del filtro de Hilbert
    if pll_state.empty
        HilbState=zeros(length(NumHilb)-1,1);
        pll_state.x_prev=zeros(floor(length(NumHilb)/2),1);
    else
        HilbState=pll_state.HilbState;
    end

%%%%%%%%%%%%%%%%%% PLL LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[xq,HilbState]=filter(NumHilb,1,x,HilbState);
%xq=[xq(floor(length(NumHilb)/2)+1:end)];
%xi=x(1:end-floor(length(NumHilb)/2));
xi=[pll_state.x_prev; x(1:end-floor(length(NumHilb)/2))];
dummy=pll_state.filtro_de_lazo.prev_int_out;

for n=2:N%-floor(length(NumHilb)/2)
    %----- VCO-----------------------------------------------------
    acc(n)=acc(n-1)+2*pi*f0/fs+e(n-1); %fase instantánea de salida del VCO
    if(acc(n)>pi)
        acc(n)=acc(n)-2*pi;
    end  
%   x_vco(n)=cos(acc(n)/M)+1j*sin(acc(n)/M); % señal de salida del VCO;
    x_vco(n)=cos(acc(n)/M);
    x_vco_q(n)=sin(acc(n)/M);
    %----------Detector de Fase-----------------------------------------------
      theta_e(n)= atan((xq(n)*x_vco(n)-xi(n)*x_vco_q(n))...
          /(xi(n)*x_vco(n)+xq(n)*x_vco_q(n))); %Error de fase (salida del detector de fase)
    if isnan(theta_e(n))
         theta_e(n)=theta_e(n-1);
    end
   % ------------------------Filtro de Lazo------------------------------------
    dummy=dummy+Ki*theta_e(n);
    e(n)=Kp*theta_e(n)+dummy;
end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pll_state_out.accumulator=acc(n)+2*pi*f0/fs+e(n);
pll_state_out.e=e(n);
pll_state_out.HilbState=HilbState;
pll_state_out.x_prev=x(end-floor(length(NumHilb)/2)+1:end);
pll_state_out.filtro_de_lazo.prev_int_out=dummy;
y=sin(acc(1:n));
end