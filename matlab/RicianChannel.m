function [Channel,Save_dists,index_visible_sat,visible_sat_count] = RicianChannel(M_x,M_y,elevation_angle,Latitudes,Longtitudes,Altitudes,K,f_c,num_time_steps,total_Satellite_Number,Cell_radius,Cell_latitude,Cell_longtitude,Time, users, max_paths, K_base) 

    sat_max = 60; 
    
    % Pass the environment K_base to the helper function
    [K_rician] = rician_factor(K, K_base);

    Save_dists = zeros(num_time_steps,sat_max);
    visible_sat_count = zeros(num_time_steps,1);
    index_visible_sat = zeros(num_time_steps , sat_max);
    Channel = zeros(M_x*M_y , num_time_steps,sat_max,K);
    
    % Pass max_paths to the helper function
    Path = number_of_paths(total_Satellite_Number, K, max_paths); 
    
    % Pre-allocate static channel properties for temporal consistency
    g_NLOS_store = cell(total_Satellite_Number, K);
    DOA_NLOS_store = cell(total_Satellite_Number, K);
    excess_delay_store = cell(total_Satellite_Number, K);
    
    for i = 1 : total_Satellite_Number
        for k = 1 : K
            p_count = Path(i,k);                            
            g_NLOS_store{i,k} = channel_gains(p_count);
            DOA_NLOS_store{i,k} = rand(p_count, 1) * pi; 
            excess_delay_store{i,k} = rand(p_count, 1) * 10e-6; 
        end
    end

    for t = 1 : num_time_steps 
        for i = 1 : total_Satellite_Number
            lat1 = Latitudes(t,i);                          
            lon1 = Longtitudes(t,i); 
            
            dist_SatCell_onEarth = haversine(lon1, lat1, Cell_longtitude, Cell_latitude); 
            
            if dist_SatCell_onEarth < Altitudes(t,i)/tan(elevation_angle)
                visible_sat_count(t) = visible_sat_count(t) + 1;
                
                if visible_sat_count(t) > sat_max
                    visible_sat_count(t) = sat_max; 
                    continue; 
                end
                
                Save_dists(t,visible_sat_count(t)) = sqrt(dist_SatCell_onEarth^2+Altitudes(t,i)^2);
                index_visible_sat(t,visible_sat_count(t)) = i;
                
                sat_angle_to_cell_center = atan(Altitudes(t,i) / dist_SatCell_onEarth);
                
                for k = 1 : K
                    sat_user_dist_ground = haversine(Longtitudes(t,i), Latitudes(t,i), users(t,k,2), users(t,k,1));
                    sat_user_Distance = sqrt(sat_user_dist_ground^2 + Altitudes(t,i)^2);
                    
                    static_excess_delay = excess_delay_store{i,k};
                    [delay_LoS , delay_NLoS] = delay(sat_user_Distance, static_excess_delay);
                    
                    PL = path_loss(sat_user_Distance, f_c);
                    PL_compensation = 1;
                    
                    [psi,theta] = angle_of_departure(sat_angle_to_cell_center);
                    [u] = UPA_response_vector(theta, psi, f_c, M_x, M_y);
                    
                    g = g_NLOS_store{i,k};
                    DOA_NLOS = DOA_NLOS_store{i,k};

                    % Doppler is captured implicitly: delay_LoS = d(t)/c changes
                    % each timestep as the satellite moves, so the phase term
                    % exp(-j*2*pi*f_c*delay_LoS) rotates at the correct Doppler
                    % rate without any explicit double-counting.
                    h_LOS = sqrt(K_rician(k)/(K_rician(k)+1)) * exp(-1i*2*pi*f_c*delay_LoS) * u;
                    
                    temp = 0;
                    for p = 1 : Path(i,k)
                        [u_nlos] = UPA_response_vector(theta + DOA_NLOS(p), psi + pi - DOA_NLOS(p), f_c, M_x, M_y);
                        temp = temp + g(p) * exp(-1i*2*pi*f_c*delay_NLoS(p)) * u_nlos;
                    end
                    
                    h_NLOS = sqrt(1 / (Path(i,k)* (1+K_rician(k)) )) * temp;
                    Channel(:,t,visible_sat_count(t),k) = (PL_compensation/(PL)) * (h_LOS + h_NLOS);
                end
            end
        end
    end
end