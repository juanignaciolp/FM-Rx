function [rds_State]=RDSdecoder_init()

% Inicializacion del decodificador RDS.

%referencia: "EN 50067. Specification of the radio data system (RDS) for
%             VHF/FM sound broadcasting in the frequency range 
%             from 87,5 to 108,0 MHz",EUROPEAN STANDARD, Abril 1998.



rds_State.SyncIdx=1; %Índice de sincronización. Indica el índice del bit sincronizado actual dentro del bloque de entrada
rds_State.BlockIdx=0; %Índice de bloque: 1<=BlockIdx<=4
rds_State.SyncBlockFlag=false; %Bandera que indica sincronización.
rds_State.lastData=[]; %datos del bloque anterior no procesados.

rds_State.BlockMOfN=zeros(1,8); %Indicador de errores
rds_State.BlockMissIdx=1; %Indice de error

rds_State.GroupType=0; % Tipo de Grupo (0 a 15)
rds_State.Version=0; %Versión del grupo (0=A,1=B)
rds_State.PI=0; %Código de identificación de programa (emisora)
rds_State.PTY=0; %Código de tipo deprograma
rds_State.AF1=0; %Código de Frecuencia Alternativa 1
rds_State.AF2=0; %Código de Frecuencia Alternativa 2
rds_State.DI=0;  %codigo de identificación del decodificador 
rds_State.C1=0; %C1 y C0 codifican las 4 posiciones posibles de los caracteres que forman PS
rds_State.C0=0;
rds_State.TA=0; %Anuncio de Tránsito activo.
rds_State.MS=0; %Indicador de transmisión actual de música(MS=1) o discurso (MS=0)
rds_State.PS='--------'; % Programme Service. Texto a mostrarse en el receptor.
rds_State.radioText ='----------------------------------------------------------------';% Texto a mostrarse en el receptor con info dinámica.

%Matriz de verificacion de paridad
rds_State.ParityCheckMatrix=dec2bin(...
    [512,256,128,64,32,16,8,4,2,1,...
    732,366,183,647,927,787,853,886,...
    443,513,988,494,247,679,911,795].')-'0'; 
%offset_words
A=[0 0 1 1 1 1 1 1 0 0];
B=[0 1 1 0 0 1 1 0 0 0];
C=[0 1 0 1 1 0 1 0 0 0];
% Cp=[1 1 0 1 0 1 0 0 0 0];
D=[0 1 1 0 1 1 0 1 0 0];
rds_State.offset_words=[A;B;C;D];

% syndromes de cada bloque
SA= [1 1 1 1 0 1 1 0 0 0];
SB= [1 1 1 1 0 1 0 1 0 0];
SC= [1 0 0 1 0 1 1 1 0 0];
% SCp=[1 1 1 1 0 0 1 1 0 0];
SD= [1 0 0 1 0 1 1 0 0 0];
rds_State.Syndromes=[SA;SB;SC;SD];

end