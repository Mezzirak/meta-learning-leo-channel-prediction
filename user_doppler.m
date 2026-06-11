function [doppler_matrix_user,doppler_matrix_user_NLOS] = user_doppler(num_time_steps,total_Satellite_Number,K,path)

doppler_matrix_user = zeros(num_time_steps,total_Satellite_Number,K);
doppler_matrix_user_NLOS = zeros(num_time_steps,total_Satellite_Number,K,max(max(max(path))));
end