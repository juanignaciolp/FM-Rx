function CostasLoop_state=CostasLoop_init(f0,fs,Bn,M)
%   Esta función implementa un lazo de Costas digital sencillo de segundo orden-tipo2
%   orientado a recuperar subportadora de 57 kHz de la señal MPX
%   de FM Broadcast.

%--------------------------------------------------------------------------
CostasLoop_state.f0=f0; % f0 Frecuencia central del VCO;
CostasLoop_state.M=M;   %multiplicador para el VCO
CostasLoop_state.fs=fs; % fs frecuencia de muestreo;
% CostasLoop_state.wL=wL; % wL lock-in Range (Rango de enganche [rad/seg])
%           (rango de frecuencia en la que el lazo se enganchará en menos de
%             un cycle-slip) 
CostasLoop_state.Bn=Bn;

%--------------------------Constantes--------------------------------------
K0=1;Kd=1; %K0: Ganancia del VCO, Kd: ganancia del detector de fase,
% C=2*fs; % Prewarping

%------------------Parámetros del filtro de lazo---------------------------
zeta=0.7;           %constante de amortiguamiento
% wn=wL/2/zeta;       %frecuencia natural de oscilación
% tau1=1*K0*Kd/wn^2;  %Constante de tiempo del filtro
% tau2=2*zeta/wn;     %Constante de tiempo del filtro

wn=Bn*2*(zeta+1/(4*zeta));
%---------------------Filtro de Lazo digital-------------------------------

% Num=[(1+tau2*C)/(tau1*C),(1-tau2*C)/(tau1*C)];
% Den=[1,-1];

Kp=1/(K0*Kd*1/M)*4*zeta/(zeta+1/(4*zeta))*Bn/fs; %Constante proporcional
Ki=1/(K0*Kd*1/M)*4/(zeta+1/(4*zeta))^2*(Bn/fs)^2; %Constante de integración

%----------------------Parámetros del Lazo----------------------------------

% Bn=wn/2/(zeta+1/(4*zeta)); %Ancho de banda de ruido equivalente
wpo=1.8*wn*(1+zeta);       %Frecuencia máxima de Pull-out
TL=2*pi/wn;                %Tiempo de enganche (Lock-in) en 1 cycle-slip

%---------------------------Estructura----------------------------------

CostasLoop_state.Bn=Bn;
CostasLoop_state.wpo=wpo;
CostasLoop_state.TL=TL;
CostasLoop_state.accumulator=0; % acumulador
CostasLoop_state.theta_e=0;     % error de fase
CostasLoop_state.e=0;           % Salida del filtro de lazo
CostasLoop_state.filtro_de_lazo.zeta=zeta; 
CostasLoop_state.filtro_de_lazo.wn=wn;
% CostasLoop_state.filtro_de_lazo.tau1=tau1;
% CostasLoop_state.filtro_de_lazo.tau2=tau2;
% CostasLoop_state.filtro_de_lazo.Num=Num;
% CostasLoop_state.filtro_de_lazo.Den=Den;
CostasLoop_state.filtro_de_lazo.Kp=Kp;
CostasLoop_state.filtro_de_lazo.Ki=Ki;
CostasLoop_state.filtro_de_lazo.prev_int_out=0;
CostasLoop_state.NumHilb=[0 -0.0960625074558434 0 -0.0738735967074135 0, ...
        -0.114550630898285 0 -0.204297562619967 0,... 
        -0.633937925126545 0 0.633937925126545 0,... 
        0.204297562619967 0 0.114550630898285 0,... 
        0.0738735967074135 0 0.0960625074558434 0]; %filtro FIR de Hilbert
CostasLoop_state.Hilb_ic=zeros(1,floor(length(CostasLoop_state.NumHilb))-1); %Condiciones Iniciales del filtro de Hilb.
CostasLoop_state.empty=true; % indica si el lazo no fue inicializado
end