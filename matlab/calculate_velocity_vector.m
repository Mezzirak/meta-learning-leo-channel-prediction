function velocity_vector = calculate_velocity_vector(lat1, lon1, alt1, lat2, lon2, alt2, time_diff)
    % Convert latitude and longitude to Cartesian coordinates
    p1 = geographic_to_cartesian(lat1, lon1, alt1);
    p2 = geographic_to_cartesian(lat2, lon2, alt2);
    % Displacement vector
    displacement = p2 - p1;
    % Velocity vector (displacement/time)
    if time_diff ~= 0
        velocity_vector = displacement / time_diff;
    else
        velocity_vector = [0, 0, 0];
    end
end