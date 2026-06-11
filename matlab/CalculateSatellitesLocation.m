function [Latitudes,Longtitudes,Altitudes] = CalculateSatellitesLocation(Semi_Major_axis,eccentricity,argument_of_perigee,longitude_of_ascending_node,Sat_inclination,mean_anomaly,num_satellites, t_Sim)

global EarthAng_0 GM

% initial values ----------------------------------------------------------
period_Earth = (23 + 56/60 + 4.0910/3600)*3600;  % sec
omega_Earth  = 2*pi/period_Earth;                % rad/sec
O  = [0             , -omega_Earth  , 0 ;
      omega_Earth   , 0             , 0 ;
      0             , 0             , 0];

t_Sim_L = t_Sim /period_Earth;
%--------------------------------------------------------------------------

earth_Az  = EarthAng_0 + omega_Earth*t_Sim_L*period_Earth;


Latitudes = zeros(length(t_Sim),num_satellites);
Longtitudes = zeros(length(t_Sim),num_satellites);
Altitudes = zeros(length(t_Sim),num_satellites);

for a = 1 : num_satellites
 
    [x_sat,y_sat,z_sat,v_x_sat,v_y_sat,v_z_sat] = f_kepl2svec(GM,Semi_Major_axis(a),eccentricity(a),argument_of_perigee(a),longitude_of_ascending_node(a),Sat_inclination(a),mean_anomaly(a),0,t_Sim_L);

    
    X_sat   = zeros(size(x_sat,1),1);
    Y_sat   = zeros(size(X_sat));
    Z_sat   = zeros(size(X_sat));
    V_X_sat = zeros(size(X_sat));
    V_Y_sat = zeros(size(X_sat));
    V_Z_sat = zeros(size(X_sat));
    
    for b = 1:size(x_sat,1)
        pos_vec  = [x_sat(b,1);y_sat(b,1);z_sat(b,1)];
        vel_vec  = [v_x_sat(b,1);v_y_sat(b,1);v_z_sat(b,1)];
        POS_VEC  = f_rotz(earth_Az(b,1)*180/pi)*pos_vec;
        VEL_VEC  = f_rotz(earth_Az(b,1)*180/pi)*vel_vec - O*POS_VEC;
        X_sat(b,1)   = POS_VEC(1,1);
        Y_sat(b,1)   = POS_VEC(2,1);
        Z_sat(b,1)   = POS_VEC(3,1);
        V_X_sat(b,1) = VEL_VEC(1,1);
        V_Y_sat(b,1) = VEL_VEC(2,1);
        V_Z_sat(b,1) = VEL_VEC(3,1);
    end
    


    LatLongAlt = ecef2lla([X_sat,Y_sat,Z_sat],'WGS84');

    Latitudes(:,a) = LatLongAlt(:,1);
    Longtitudes(:,a) = LatLongAlt(:,2);
    Altitudes(:,a) = LatLongAlt(:,3);


end


