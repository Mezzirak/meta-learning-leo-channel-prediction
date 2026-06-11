function [mse,Rate] = Metrics(G_hat,G,V,L,M,K,Mean,Exp,sigma)
MSE = zeros(L,1);
for l = 1 : L
    A_l = zeros(M,K);
    G_l = G_hat(:,:,l);
    V_l = V(:,:,l);
    for i = 1 : L
        V_i = V(:,:,i);
        G_i = G_hat(:,:,i);
        A_l = A_l + G_l * G_i'*V_i + Exp(:,:,l,i)*V_i...
            -Mean(:,:,l)*G_i'*V_i-G_l*Mean(:,:,i)'*V_i;
    end
    MSE(l) = MSE(l) + trace(V_l'*A_l)...
        - 2*real(trace(V_l'*G_l-V_l'*Mean(:,:,l)));

end
mse = sum( real(MSE) );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Rate %%%%%%%%%%%%%%%%%%%%%%%%

% P_T = 0;
% for l = 1 : L
%     P_T = trace(V(:,:,l)*V(:,:,l)');
% end
% [~,PN_dB] = rho_dB(BW,280,10*log10(P_T),10*log10(M*L*1),3.5);
% sigma = 10 ^ (PN_dB/10);
V_bar = zeros(M*L,K);
G_bar = zeros(M*L,K);
R = zeros(K,1);
for k = 1 : K
    for l = 1 : L
        V_bar (M*(l-1)+1:M*l,k) = V(:,k,l);
        G_bar (M*(l-1)+1:M*l,k) = G(:,k,l);
    end
end
for k = 1 : K
    temp = 0;
    for i = 1 : K
        if i ~= k
            temp = temp + G_bar(:,k)' * V_bar(:,i) * V_bar(:,i)' * G_bar(:,k);
        end
    end
    Nom = G_bar(:,k)' * V_bar(:,k) * V_bar(:,k)' * G_bar(:,k);
    R(k) = log2(1+Nom/(temp+sigma));
end
Rate = real(sum(R));


end