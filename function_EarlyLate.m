function [y,err,SampleTimes,EL_state_out]=function_EarlyLate(EL_state,x)

delta_idx=EL_state.delta_idx;
Nsym=EL_state.Nsym;
prev_Energy=EL_state.prev_Energy;
x=x(:);
N=length(x);
Energ=(abs(x)).^2;
err=zeros(ceil(length(x)/Nsym),1);
SampleTimes=zeros(ceil(length(x)/Nsym),1);
if delta_idx<Nsym/2
    prev_Early=sum(Energ(Nsym/2-delta_idx:Nsym-delta_idx-1));
else
    prev_Early=prev_Energy+sum(Energ(1:Nsym-delta_idx-1));
end
first_Late=sum(Energ(Nsym-delta_idx+1:3*Nsym/2-delta_idx));
if EL_state.first_use_flag
    SampleTimes(1)=Nsym;
else
    tol=eps(first_Late);
    SampleTimes(1)=Nsym-delta_idx;%(((prev_Early-first_Late)<tol)-((prev_Early-first_Late)>tol));
end
% alfa=1/Nsym;
alfa=0.25;
k=1;
while((SampleTimes(k)+Nsym)<N)
    if (k==1)
        Early=prev_Early;
    else
        Early=sum(Energ(SampleTimes(k)-Nsym/2:SampleTimes(k)-1));
    end
    Late=sum(Energ(SampleTimes(k)+1:SampleTimes(k)+Nsym/2));
    tol=eps(Late);
    if all([abs(Early-Late)<=tol,real(x(SampleTimes(k)))<real(x(SampleTimes(k)+Nsym/2))])
        SampleTimes(k+1)=SampleTimes(k)+Nsym/2;
        k=k+1;
        continue;
    else
        err(k+1)=(1-alfa)*err(k)+alfa*(((Early-Late)<tol)-((Early-Late)>tol));
    end
    SampleTimes(k+1)=round(SampleTimes(k)+Nsym+err(k+1));
    k=k+1;
end
SampleTimes=SampleTimes(1:k);
y=x(SampleTimes);
EL_state_out.Nsym=Nsym;
EL_state_out.delta_idx=N-SampleTimes(k)-1;
EL_state_out.prev_Energy=(N>SampleTimes(k)+Nsym/2)*sum(Energ(Nsym/2+SampleTimes(k)+1:N));
EL_state_out.first_use_flag=false;

end

