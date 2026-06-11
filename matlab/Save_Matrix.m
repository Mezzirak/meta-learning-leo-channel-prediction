% n = 1;
% T = n / TimeStep;
% T_th = Max_T  / (TimeStep*T);
% for i = 1:T
%     filename = ['output_' num2str(i) '.xlsx']; 
%     writematrix(Latitudes((i-1)*T_th+1:i*T_th,:), filename, 'Sheet', 'Latitudes');
%     writematrix(Longtitudes((i-1)*T_th+1:i*T_th,:), filename, 'Sheet', 'Longtitudes');
%     writematrix(Altitudes((i-1)*T_th+1:i*T_th,:), filename, 'Sheet', 'Altitudes');
% end

filename = 'output_1.xlsx';  % Name of the Excel file

% Define sheet name
sheetName = sprintf('Latitudes');

% Write the slice to the Excel file
writematrix(Latitudes, filename, 'Sheet', sheetName);

% Define sheet name
sheetName = sprintf('Longtitudes');

% Write the slice to the Excel file
writematrix(Longtitudes, filename, 'Sheet', sheetName);

% Define sheet name
sheetName = sprintf('Altitudes');

% Write the slice to the Excel file
writematrix(Altitudes, filename, 'Sheet', sheetName);


% Define sheet name
sheetName = sprintf('Time');

% define Time
Time = zeros(size(Latitudes,1),size(Latitudes,2));
for i = 1 : size(Latitudes,2)
    Time(:,i) = t_sim;
end
Yes = 0;
% Write the slice to the Excel file
writematrix(Time, filename, 'Sheet', sheetName);


save('Latitudes.mat', 'Latitudes', '-v7.3');
save('Longtitudes.mat', 'Longtitudes', '-v7.3');
save('Altitudes.mat', 'Altitudes', '-v7.3');
save('Time.mat', 'Time', '-v7.3');
save('Channel4.mat', 'Channel_Sorted', '-v7.3');