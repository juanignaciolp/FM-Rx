
function [s,agc_state_out,error,a]=function_agc(agc_state,x)
agc_state_out=agc_state;
N=length(x);
P=agc_state.P; 
mu=agc_state.mu; 
Nwin=agc_state.Nwin;
 a=zeros(N,1);
a(1)=agc_state.a;% initialize AGC parameter
a(2)=a(1);
s=zeros(N,1); % i n i t i a l i z e outputs
error=zeros(N,1); % vector to s tor e averaging terms
for k=2:N-1
    s(k)=a(k)*x(k); % normal i ze by a(k) & add to avec
%     error=[error(1:end-1);(s(k)^2-P )*(s(k)^2)/a(k)];
%     a(k+1)=a(k)-mu*mean(error); % average adaptive update of a (k)
     if k<=Nwin
        error(k)=error(k-1)+((s(k)^2-P)*(s(k)^2)/a(k))/Nwin;
    else
        error(k)=error(k-1)+((s(k)^2-P)*(s(k)^2)/a(k)-(s(k-Nwin)^2-P )*(s(k-Nwin)^2)/a(k-Nwin))/Nwin;
    end
%     a(k+1)=a(k)-mu*mean( avec ) ; % average adaptive update of a (k)
     a(k+1)=a(k)-mu*error(k) ;
end
agc_state_out.a=a(k+1);
agc_state_out.error=error(k);
end