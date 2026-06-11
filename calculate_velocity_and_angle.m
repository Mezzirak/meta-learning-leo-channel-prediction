function [velocity_matrix , angle_matrix] = calculate_velocity_and_angle (t, s,Latitudes,Longtitudes,Altitudes,Time,Cell_latitude, Cell_longtitude)

    % Handle index 1 crash (MATLAB starts at 1, so t-1=0 is death)
    if t == 1
        % For the first step, look forward to step 2 to estimate velocity
        % (Forward difference: p2 - p1)
        if size(Latitudes, 1) > 1
            idx_prev = 1; 
            idx_curr = 2;
        else
            % Edge case: Chunk size is 1 (shouldn't happen, but safety first)
            velocity_matrix = 0; angle_matrix = 0; return;
        end
        % For boresight angle, we are at t=1 (idx_prev)
        idx_pos = 1;
    else
        % Normal behaviour: look backward (Backward difference: pt - pt-1)
        idx_prev = t - 1;
        idx_curr = t;
        % For boresight angle, we are at t (idx_curr)
        idx_pos = t;
    end

    % Velocity Calculation Points
    lat1 = Latitudes(idx_prev,s); lon1 = Longtitudes(idx_prev,s); alt1 = Altitudes(idx_prev,s); time1 = Time(idx_prev,1);
    lat2 = Latitudes(idx_curr,s); lon2 = Longtitudes(idx_curr,s); alt2 = Altitudes(idx_curr,s); time2 = Time(idx_curr,1);
    
    velocity_vector = calculate_velocity_vector(lat1, lon1, alt1, lat2, lon2, alt2, time2-time1);
    velocity_matrix = norm(velocity_vector);
    
    % Boresight Calculation (Position relative to Cell Center)
    lat_pos = Latitudes(idx_pos,s); 
    lon_pos = Longtitudes(idx_pos,s); 
    alt_pos = Altitudes(idx_pos,s);

    boresight_vector = geographic_to_cartesian(lat_pos, lon_pos, alt_pos) - geographic_to_cartesian(Cell_latitude, Cell_longtitude, 0);
    angle_matrix = angle_between_vectors(velocity_vector, boresight_vector);
end