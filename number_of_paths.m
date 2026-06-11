function path = number_of_paths(total_Satellite_Number, K, max_paths)
    % Ensures at least 1 path, up to the maximum dictated by the environment
    temp = randi([1, max_paths], total_Satellite_Number, K);
    path = temp;
end