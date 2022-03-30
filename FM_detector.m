function xdem=FM_detector(I,Q,fs)
    der_I=[I(1);diff(I)]*fs;
    der_Q=[Q(1);diff(Q)]*fs;
    xdem=1/2/pi*(der_I.*Q-der_Q.*I)./(I.^2+Q.^2);
    xdem=xdem/max(abs(xdem));
end