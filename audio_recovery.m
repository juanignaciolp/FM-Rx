function [y,IC_out]=audio_recovery(Num,Den,x,M,IC)
%            M: Factor de diezmado. tener en cuenta que M debe ser tal que 
%               fs/M>=2*fc, donde fs  es la frecuencia de muestreo de la señal x
%               y fc es la frecuencia de corte del filtro pasabajos de
%               coeficientes [num,den]
          [y,IC_out]= filter(Num,Den,x,IC);
          y=downsample(y,M);
          y=y/max(abs(y));
end
