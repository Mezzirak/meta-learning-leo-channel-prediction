function cartesian_coords = geographic_to_cartesian(lat, lon, alt)
    % Earth's radius in meters (mean radius)
    R = 6371000;
    % Convert latitude and longitude from degrees to radians
    lat_rad = deg2rad(lat);
    lon_rad = deg2rad(lon);
    % Cartesian coordinates
    x = (R + alt) * cos(lat_rad) * cos(lon_rad);
    y = (R + alt) * cos(lat_rad) * sin(lon_rad);
    z = (R + alt) * sin(lat_rad);
    cartesian_coords = [x, y, z];
end