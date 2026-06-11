function [Mean,Expectation,Channels_shaped] = CSI_error_amended(Channel_Sorted,T)
M = size(Channel_Sorted,1);
num_time_steps = size(Channel_Sorted,2);
num_sats =1;% size(Channel_Sorted,3);
K = size(Channel_Sorted,3);
Exp_Period = 9;
Time_duration = T+1:Exp_Period:num_time_steps;

%% Generate the instantaneous CSI errors
G_tilde_shaped = zeros(M,K,num_sats,num_time_steps);

for t = T+1:num_time_steps
    for l=1:num_sats
        for k = 1 : K
            G_tilde_shaped(:,k,l,t) =  Channel_Sorted(:,t-T,k) - Channel_Sorted(:,t,k);
        end
    end
end
%% Generate the CSI error Mean
Mean0 = zeros(M,K,num_sats,length(Time_duration));
Mean = zeros(M,K,num_sats,num_time_steps);

for i = 1 : length(Time_duration)-1
    count = 0;
    temp00 = zeros(M,K,num_sats);
    for  t = Time_duration(i):Time_duration(i+1)-1
        temp00 = temp00 + G_tilde_shaped(:,:,:,t);
        count = count + 1;
    end
    Mean0(:,:,:,i) = temp00 / count;
    for tt = Time_duration(i):Time_duration(i+1)-1
        Mean(:,:,:,tt) = Mean0(:,:,:,i);
    end

end
%% Generate the CSI error Correlation Matrix
Expectation0 = zeros(M,M,num_sats,num_sats,length(Time_duration));
Expectation = zeros(M,M,num_sats,num_sats,num_time_steps);
for i = 1 : length(Time_duration)-1
    count = 0;
    temp0 = zeros(M,M,num_sats,num_sats);
    for  t = Time_duration(i):Time_duration(i+1)-1
        for l=1:num_sats
            for j = 1 : num_sats
                temp0(:,:,l,j) = temp0(:,:,l,j)+ G_tilde_shaped(:,:,l,t) * G_tilde_shaped(:,:,j,t)';
            end
        end
        count = count + 1;
    end
    Expectation0(:,:,:,:,i) = temp0 / count;
    for tt = Time_duration(i):Time_duration(i+1)-1
        Expectation(:,:,:,:,tt) = Expectation0(:,:,:,:,i);
    end

end

%% Shaping the channels
Channels_shaped = zeros(M,K,num_sats,num_time_steps);

 for t = 1 : num_time_steps
     for k = 1 : K
         for l = 1 : num_sats
             Channels_shaped(:,k,l,t) = Channel_Sorted(:,t,k);
         end
     end
 end



end