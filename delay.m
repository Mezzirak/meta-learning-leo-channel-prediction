function [delay_LoS, delay_NLoS] = delay(distance_km, excess_delay)
    % distance_km: Input distance in Kilometres (dynamically changes over time)
    % excess_delay: Array of pre-generated static delays for NLOS paths
    
    % 1. Convert km to meters for physics calculations
    distance_m = distance_km * 1000;
    
    % 2. LoS Delay (T = D/c)
    c = physconst('LightSpeed');
    delay_LoS = distance_m / c;

    % 3. NLOS Delay: Add static excess delay passed from RicianChannel
    % This keeps the reflectors statically positioned relative to the LoS path
    delay_NLoS = delay_LoS + excess_delay;
end