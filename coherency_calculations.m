Gravitational_constant = 6.674 * 10^(-11);  % gravitational constant in m^3kg^-1s^-2
Mass = 5.972 * 10^(24);  % mass of the Earth in kg
Radius_of_earth = 6.371 * 10^6;  % radius of the Earth in m

f_c =2* 10^9;


altitude_of_constellation =540000;
theta_max = 8.9*pi/20;
v_calculation = sqrt(Gravitational_constant*Mass/(Radius_of_earth+altitude_of_constellation))*cos(theta_max);
T_c = physconst('LightSpeed') / (v_calculation * f_c)
T_d = altitude_of_constellation/(sin(theta_max)*physconst('LightSpeed'))
