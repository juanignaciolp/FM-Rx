function [y,g]=agc(R,alpha,x)
x=x(:);
N=length(x);
xh=hilbert(x);
log_y=zeros(N,1);
for n=1:N-1
    log_y(n+1)=log_y(n)*(1-alpha)-alpha*log(abs(xh(n))/R);  
end
g=exp(log_y); %agcgain;
y=g.*x; %output

end