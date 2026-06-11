function [a] = steering_vector(N,psi,d,lnda)
a = 1i* zeros(N,1);
for k = 1 : N
    a(k) = exp(-1i * 2 * pi * d * psi * (k-1) / lnda) / sqrt(N);
end
end