function [SNR_dB,PN_dB] = rho_dB(BW,T,PT_dB,GT_dB,GR_dB)
%BW=500*10^6;
B_dB = 10*log10(BW); %BandWidth
K_dB =10*log10(1.380649 * 10^(-23)); %Boltzman constant
T_dB = 10*log10(T); %Noise Tempreture
PN_dB = K_dB + T_dB + B_dB ; %Noise Power
SNR_dB = PT_dB + GT_dB + GR_dB - PN_dB; %Received SNR at the Satellite antenna
end