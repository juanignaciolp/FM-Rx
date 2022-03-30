%% Lazo de Costas



%-------------------------Inicilaización-----------------------------------
t=0:1/fm:40000/f0;
N=length(t);

acc=zeros(N,1);
x_vco=zeros(N,1);
theta_e=zeros(N,1);
e=zeros(N,1);
% acc_=acc;
%-------------------------Señal de entrada---------------------------------
 theta_in=[2*pi*(fin)*t(1:floor(length(t)/4)), 2*pi*(fin+deltaf)*...
     t(floor(length(t)/4)+1:end)]; %fase instantánea;

% theta_in=[2*pi*(fin+deltaf)*t+pi/2];
    
   x=cos(theta_in)+1j*sin(theta_in)+0.01*randn(1,N); %Señal
%%%%%%%%%%%%%%%%%% PLL LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xi=real(x); xq=imag(x); %señal de entrada en fase y cuadratura



for n=2:N
    
    %----- VCO-----------------------------------------------------
    acc(n)=acc(n-1)+2*pi*f0/fm+2*pi*e(n-1)/fm; %fase instantánea de salida del VCO
%     acc(n)=1/M*acc_(n); 
    if(acc(n)>pi)
        acc(n)=acc(n)-2*pi;
    end
    x_vco(n)=cos(acc(n)/M)+1j*sin(acc(n)/M); % señal de salida del VCO;

    IQ(n)=x_vco(n)*x(n);
    
     



    %----------Detector de Fase-----------------------------------------------
    
     theta_e(n)= atan((xq(n)*real(x_vco(n))-xi(n)*imag(x_vco(n)))...
         /(xi(n)*real(x_vco(n))+xq(n)*imag(x_vco(n)))); %Error de fase (salida del detector de fase)
%      theta_e(n)=x(n)*x_vco(n);
%     in=(xq(n)*real(x_vco(n))-xi(n)*imag(x_vco(n)))...
%        /(xi(n)*real(x_vco(n))+xq(n)*imag(x_vco(n)));
    %------------------------Filtro de Lazo------------------------------------
    e(n)=-Den(2)/Den(1)*e(n-1)+Num(1)/Den(1)*theta_e(n)+Num(2)/Den(1)*theta_e(n-1);
end
%%%%%