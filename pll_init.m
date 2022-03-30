function pll_state=pll_init(f0,fs,Bn,M)
%   Esta función implementa un PLL digital sencillo de segundo orden-tipo2
%   orientado a recuperar subportadora de 19 kHz de la señal MPX
%   de FM Broadcast.

%--------------------------------------------------------------------------
pll_state.f0=f0; % f0 Frecuencia central del VCO;
pll_state.M=M;   %multiplicador para el VCO
pll_state.fs=fs; % fs frecuencia de muestreo;
pll_state.Bn=Bn; %Ancho de banda de ruido
% wL lock-in Range (Rango de enganche [rad/seg])
%           (rango de frecuencia en la que el PLL se enganchará en menos de
%             un cycle-slip) 


%--------------------------Constantes--------------------------------------
K0=1;Kd=1; %K0: Ganancia del VCO, Kd: ganancia del detector de fase,
% C=2*fs; % Prewarping

%------------------Parámetros del filtro de lazo---------------------------
zeta=0.7;           %constante de amortiguamiento
wn=Bn*2*(zeta+1/(4*zeta)); %frecuencia de oscilación natural
% tau1=1*K0*Kd/wn^2;  %Constante de tiempo del filtro
% tau2=2*zeta/wn;     %Constante de tiempo del filtro

%----------------------Parámetros del PLL----------------------------------

wpo=1.8*wn*(1+zeta);       %Frecuencia máxima de Pull-out
TL=2*pi/wn;                %Tiempo de enganche (Lock-in) en 1 cycle-slip
%---------------------Filtro de Lazo digital-------------------------------

Kp=1/(K0*Kd*1/M)*4*zeta/(zeta+1/(4*zeta))*Bn/fs; %Constante proporcional
Ki=1/(K0*Kd*1/M)*4/(zeta+1/(4*zeta))^2*(Bn/fs)^2; %Constante de integración
%---------------------------Estructura----------------------------------

pll_state.wpo=wpo;
pll_state.TL=TL;
pll_state.accumulator=0; % acumulador
pll_state.e=0;           % Salida del filtro de lazo
pll_state.HilbState=[];   % Estado inicial del filtro de Hilbert
pll_state.filtro_de_lazo.zeta=zeta; 
pll_state.filtro_de_lazo.wn=wn;
pll_state.filtro_de_lazo.Kp=Kp;
pll_state.filtro_de_lazo.Ki=Ki;
pll_state.filtro_de_lazo.prev_int_out=0; %Salida anterior del integrador del filtro de lazo
% pll_state.amplitud=1; %Amplitud del bloque anterior
pll_state.x_prev=[];%Parte inicial de los datos anteriores
pll_state.empty=true; % indica si el pll fue inicializado.
end
