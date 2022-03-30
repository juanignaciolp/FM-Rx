% Demodulador FM
clearvars;
close all;
clc;
%File
file=['D:\Users\JuanIgnacio\Documents\test_dem\pyFmRadio\',...
    'SDRSharp_20211123_194122Z_103700000Hz_IQ.wav'];
fileinfo=audioinfo(file);
%SDR
Ncanales=100;
BWcanal=180e3;
NumCanal=201:300;
FrecuenciasCentrales=88.1e6+(0:Ncanales-1)*BWcanal;

FrecuenciaCentral=97.3e6;
fs=250e3;%fileinfo.SampleRate;
spf=8194*10*2;
Fsint=FrecuenciaCentral;
fFI=Fsint-FrecuenciaCentral;

%PLL
Bn=1000;
M=1;
fvco=M*19e3;


 %%
%  radio=dsp.AudioFileReader(...
%      'Filename',file,...
%  'PlayCount',1,...
%  'SamplesPerFrame',spf,...
%  'OutputDataType','double');
% setup(radio);

 radio = comm.SDRRTLReceiver('0','CenterFrequency',FrecuenciaCentral,'SampleRate',fs, ...
     'SamplesPerFrame',spf,'EnableTunerAGC',false,'OutputDataType','double','TunerGain',10);


%%
%Adquisición de señal

Nfft=min(1024,spf);
N_prom=2;
mod2_X=zeros(Nfft,1);
X200=zeros(Nfft,1);
mod2_X200=zeros(Nfft,1);
Xdem=zeros(Nfft,1);
mod2_Xdem=zeros(Nfft,1);
FD=floor(fs/BWcanal);

%% system Objects
M_audio=floor(fs/FD/30e3);
Audio=audioDeviceWriter('SampleRate',fs/FD/M_audio,...
     'BufferSize',8096,'SupportVariableSizeInput',true);
pll_state=pll_init(fvco,fs/FD,Bn,M);


%% filtros 
 [num15,den15]=fir1(150,[30 15e3]*2*FD/fs); 
 [num19,den19]=fir1(150,[18e3 20e3]*2*FD/fs);

fir38 = dsp.FIRFilter(fir1(150,[23e3 53e3]*2*FD/fs));
[num38,den38]=fir1(250,[23e3 53e3]*2*FD/fs);
band200=fir1(200,90e3*2/fs);

fir_decimator=dsp.FIRDecimator(FD,fir1(400,90e3*2/fs));
% RDSdecim=dsp.FIRDecimator(floor(fs/FD/6e3),fir1(100,2.4e3*2*FD/fs));
  RDS_filt=fir1(150,2.5e3*2*FD/fs); 
% RDS_filt=[-0.000595132554341352,-0.000742064608671778,-0.00115013457354376,-0.00164957369360677,-0.00222601333251697,-0.00285164595013564,-0.00348332573313317,-0.00406512187419635,-0.00452588003705075,-0.00478434305737503,-0.00475038089559053,-0.00433133606942404,-0.00343720332205046,-0.00198668816938035,8.54666416961390e-05,0.00282273368226101,0.00624023041591508,0.0103209856663588,0.0150128155310789,0.0202274377622374,0.0258419051023901,0.0317019442206187,0.0376284217223794,0.0434248440941824,0.0488869036949368,0.0538125666499761,0.0580126554373665,0.0613214000187263,0.0636053991924333,0.0647714233089498,0.0647714233089498,0.0636053991924333,0.0613214000187263,0.0580126554373665,0.0538125666499761,0.0488869036949368,0.0434248440941824,0.0376284217223794,0.0317019442206187,0.0258419051023901,0.0202274377622374,0.0150128155310789,0.0103209856663588,0.00624023041591508,0.00282273368226101,8.54666416961390e-05,-0.00198668816938035,-0.00343720332205046,-0.00433133606942404,-0.00475038089559053,-0.00478434305737503,-0.00452588003705075,-0.00406512187419635,-0.00348332573313317,-0.00285164595013564,-0.00222601333251697,-0.00164957369360677,-0.00115013457354376,-0.000742064608671778,-0.000595132554341352];

state=zeros(length(RDS_filt)-1,1);
% fir57=dsp.FIRFilter(fir1(550,[54.5e3 59.5e3]*2*FD/fs),'InitialConditions',zeros(550,1));
fir57=dsp.FIRFilter(fir1(500,[54.5e3 59.5e3]*2*FD/fs));

T=(fs/FD/M_audio)^-1;
tau=75e-6;
num_de_enf=1/(1+tau*2/T)*[1 1];
den_de_enf=[1 (1-tau*2/T)/(1+tau*2/T)];
%% condiciones iniciales
S_ic=zeros(length(num15)-1,1);
pilot_band_ic=zeros(length(num19)-1,1);
 band38_ic=zeros(length(num38)-1,1);
 band200_ic=zeros(length(band200)-1,1);
D_ic=S_ic;
R_ic=0;
L_ic=0;
%% RDS
 BR=2*1187.5; %Bit Rate [BPS]
 Tbit=1/BR;
 Nb=10; %número de muestras por símbolo.
 Fs=fs/FD;

 [P,Q]=rat(Fs/BR/Nb);

rcos=rcosdesign(1,6,Nb,'sqrt');
 ed = comm.EyeDiagram('SampleRate',Fs*Q/P,'SamplesPerSymbol',Nb,...
     'SymbolsPerTrace',4,'TracesToDisplay',25,'YLimits',[-0.7 0.7]);
 TS=dsp.TimeScope('NumInputPorts',1,'SampleRate',Fs*Q/P,'TimeSpan',100/1187.5,'YLimits',[-2 2]);
 SA = dsp.SpectrumAnalyzer('NumInputPorts',2,'SampleRate',fs/FD*Q/P,'PlotAsTwoSidedSpectrum',true,...
     'ShowLegend',true,'SpectralAverages',20,'FrequencyResolutionMethod','WindowLength');

ps=rcos;
MFout_state=zeros(length(ps)-1,1);
MFout_stateQ=zeros(length(ps)-1,1);
EL_s=Early_Late_init(Nb,0,0,0);
fine = comm.CarrierSynchronizer( ...
    'DampingFactor',0.4,'NormalizedLoopBandwidth',0.05, ...
    'SamplesPerSymbol',Nb,'Modulation','BPSK');

CS_state=CarrierSync_init();

data=[];
data2=[];


Manch_state.error=zeros(8,1);
Manch_state.err_idx=1;
Manch_state.prev_bit=0;

[rds_State]=RDSdecoder_init();
%%
figure;
v=scatter(nan(1,200),nan(1,200));
% figure;
% v2=plot(nan(19,1));
%  while (~isDone(radio))
  iter=0;
%  
 while (iter<500)
    iter=iter+1;
    [raw]=step(radio);
    
    [x200_,band200_ic]=FI_tune(raw,fFI,fs,band200,band200_ic);
    
    %       x200_=x200_./abs(x200_);
    x200=x200_(1:FD:end);
    %     xdem=FM_detector(real(x200),imag(x200),fs/FD);
    xdem=angle(x200(1:end-1).*conj(x200(2:end)));
    %      xdem=xdem./abs(xdem);
    
    %extracción de la señal suma
    [Sd,S_ic]=audio_recovery(num15,den15,xdem,M_audio,S_ic);
    
    %extracción del piloto de 19 kHz
    [pilot_band,pilot_band_ic]=filter(num19,den19,xdem,pilot_band_ic);
    %      pilot19=cos(2*pi*19.05e3/Fs*(0:length(pilot_band)-1).');
    [pilot19,pll_state,theta_e,acc]=function_pll(pll_state,pilot_band);
    
    % extraccion banda38
    [band38,band38_ic]=filter(num38,den38,xdem,band38_ic);
    
    %    pilot19=cos(2*pi*1*19e3/Fs*(1:length(pilot19))');
    pilot19h=hilbert(pilot19);
    
    pilot38=real(pilot19h.^2);
    
    mix38=band38.*pilot38;
    
    [Dd,D_ic]=audio_recovery(num15,den15,mix38,M_audio,D_ic);
    
    % Canales de audio
    R=(Sd-Dd)/2;
    L=(Sd+Dd)/2;
    
    [R,R_ic]=filter(num_de_enf,den_de_enf,R,R_ic);
    [L,L_ic]=filter(num_de_enf,den_de_enf,L,L_ic);
    
    Audio([L,R]);   
    pilot57h=pilot19h.^3;
    rdbsbb=(pilot57h).*(fir57(xdem(1:length(pilot57h))));
    [RDSbband,state]=filter(RDS_filt,1,rdbsbb,state);
    
    RDS_rs=resample(RDSbband,Q,P);
    %
    [MFout_,MFout_state]=filter(fliplr(ps),1,RDS_rs,MFout_state);
    %        [MFout_,fase]=coarse(MFout_);
    
    [MFout,err,SampleTimes,EL_s]=function_EarlyLate(EL_s,MFout_);
    %       data=[data,err];
%       MFout=SymbolSync(MFout_);
%     [bits,phe]=fine(MFout);
    [bits,CS_state]=CarrierSync(CS_state,MFout);
    %       fe=mean(diff(phe)*(Fs*Q/P)/2/pi)
    %       data=[data;phe];
    [DecodedBits,Manch_state]=Manch_decode(real(bits)>0,Manch_state);
    %       data=[data;DecodedBits];
    
    [rds_State]=RDSdecoder(DecodedBits,rds_State);
    
    set(v,'YData',[v.YData(end-199:end).'; imag((bits))],'XData',[v.XData(end-199:end).'; real((bits))]);axis([-0.7 0.7 -0.7 0.7]),grid on;   
    SA(real(MFout_),RDS_rs);
    ed((MFout_))
    
end

release(radio);delete(radio);
release(SA); delete(SA);
release(Audio); delete(Audio);
release(ed);delete(ed);
release(TS);delete(TS);
 






