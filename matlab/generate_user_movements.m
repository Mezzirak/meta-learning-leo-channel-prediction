function [user_locations] = generate_user_movements(K, num_time_steps, Cell_radius, Cell_latitude, Cell_longtitude, max_speed_ms)
    R = 6371;       % Earth Radius in km
    dt = 0.001;     % Time step in seconds (1 ms)

    user_locations = zeros(num_time_steps, K, 2);

    for k = 1 : K
        % 1. Initialize Starting Position (t=1)
        theta = 2 * pi * rand;
        r = Cell_radius * sqrt(rand);
        
        lat_offset_rad = r * cos(theta) / R;
        long_offset_rad = r * sin(theta) / (R * cos(deg2rad(Cell_latitude)));
        
        user_locations(1, k, 1) = Cell_latitude + rad2deg(lat_offset_rad);
        user_locations(1, k, 2) = Cell_longtitude + rad2deg(long_offset_rad);

        % 2. Generate Random Velocity Vector
        % User speed depends on the scenario type passed into the function
        speed_ms = max_speed_ms * rand;  
        speed_kms = speed_ms / 1000;     
        direction = 2 * pi * rand;       

        v_north = speed_kms * cos(direction);
        v_east  = speed_kms * sin(direction);

        % 3. Propagate Movement Over Time
        for t = 2 : num_time_steps
            prev_lat = user_locations(t-1, k, 1);
            prev_lon = user_locations(t-1, k, 2);

            d_lat_rad = (v_north * dt) / R;
            d_lon_rad = (v_east * dt) / (R * cos(deg2rad(prev_lat)));

            user_locations(t, k, 1) = prev_lat + rad2deg(d_lat_rad);
            user_locations(t, k, 2) = prev_lon + rad2deg(d_lon_rad);
        end
    end
end