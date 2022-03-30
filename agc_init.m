function agc_state=agc_init(P,mu,Nwin,a)
agc_state.P=P; % Potencia deseada de salida
agc_state.mu=mu; %Paso para el algotirmo de descenso del gradiente;
agc_state.a=a; %Valor inicial del parámetro
agc_state.Nwin=1024; %Largo de ventana del promedio móvil
end