function [K_rician] = rician_factor(K, K_base)
    % Generates a K-factor around the given baseline.
    % High K_base (e.g., 20) = Strong Line of Sight (Rural)
    % Low K_base (e.g., 2)  = Weak Line of Sight (Urban)
    
    K_rician = randi([K_base, K_base + 5], 1, K);
end