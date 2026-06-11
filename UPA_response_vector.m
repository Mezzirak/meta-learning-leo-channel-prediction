function [u] = UPA_response_vector(theta,phi,f_c,M_x,M_y)
lnda = physconst('LightSpeed') / f_c;
d = 0.5 * lnda;
a_x = steering_vector(M_x,cos(theta) * sin(phi),d,lnda);
a_y = steering_vector(M_y, cos(phi) , d , lnda);
u = kron(a_x,a_y);
end