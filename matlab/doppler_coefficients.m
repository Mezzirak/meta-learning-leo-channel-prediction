function [doppler_matrix_sat] = doppler_coefficients(velocity_matrix,angle_matrix,f_c)
doppler_matrix_sat = velocity_matrix * f_c * cos(angle_matrix) / physconst('LightSpeed') ;

end