function [g] = channel_gains(P)
% Complex Gaussian gains for NLOS paths (as is standard in literature)
g = (randn(P,1) + 1i*randn(P,1)) / sqrt(2);
end