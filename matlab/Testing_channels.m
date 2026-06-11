clc;clear all; close all;
b = load("Ch_MultiSat_Tc_M9.mat");
d = load("Save_dists.mat");
H2 = b.Channel;
D2 = d.Save_dists;
M=size(H2,1);
num_time_steps = size(H2,2);
visible_sat_count = 40;
K=size(H2,4);
Ch_Sorted = zeros(M,num_time_steps,visible_sat_count,K);
Distance_Saved = zeros(num_time_steps,size(H2,3));
for t = 2 : num_time_steps
    sorted = sort(nonzeros(D2(t,:)));
    Distance_Saved(t,1:length(sorted)) = sorted;
    for i = 1 : visible_sat_count %max(visible_sat_count)
        Ch_Sorted(:,t,i,:) = H2(:,t,find(D2(t,:)==sorted(i)),:);
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

L=9;
Channel_Sorted = zeros(L,num_time_steps,K);
for l=1:L
    Channel_Sorted(l,:,:) = Ch_Sorted(1,:,l,:);
end

figure
hold on
for l=1:9
    semilogy(abs(Channel_Sorted(l,:,1)))
end

save('Ch_M1_L9.mat', 'Channel_Sorted', '-v7.3');

% H3=zeros(size(H2,1),size(H2,2),size(H2,4));
% for i=1:size(H2,1)
%     for t = 1 : size(H2,2)
%         H3 (i,t,:) = H2(i,t,1,:);
%     end
% end
% 
% save('Ch_Tc_NH.mat', 'H3', '-v7.3');


% H4=zeros(size(H2,1),size(H2,2),size(H2,4));
% M=3;
% for t = 1: size(H2,2)
%     for l = 1 : 3
%         H4((l-1)*M+1:l*M,t,:)= H2(1:M,t,l,:);
%     end
% end
% save('Ch_M3_L3.mat', 'H4', '-v7.3');


figure
hold on
for l=1:3
    aa = mean(H4((l-1)*M+1:l*M,:,:));
    plot(abs(aa(1,:,1)))
end