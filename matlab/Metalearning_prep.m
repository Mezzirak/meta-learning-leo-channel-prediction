clc; clear all; close all;
global EarthAng_0 GM
r_earth = 6371e3;        
GM      = 3.986004418e14; 
EarthAng_0 = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% Simulation Setup %%%%%%%%%%%%%%%%%%%
Total_Time = 30; 
TimeStep   = 0.001;      
Total_Steps = ceil(Total_Time / TimeStep);

Chunk_Duration = 2; 
Num_Chunks = ceil(Total_Time / Chunk_Duration);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Constellation Parameters %%%%%%%%%%%%%%%%
num_layers = 4;
num_planes =[72 36 6 72];
num_sats_per_plane =[22 20 58 22];
inclination =[53 70 97.6 53.2];
orbit_altitude =[550000 570000 560000 540000];
RAAN =[360 360 360 360];
Sat_phase_diff_in_adjacent_cells =[1.1364 1.1364 1.1364 1.1364];
True_anomaly =[16.4 16.4 16.4 16.4];

count = 1;
Sat_Elements = struct('a', [], 'i', [], 'M0', [], 'W', [], 'w', [], 'e',[]);

for i = 1 : num_layers
    num_satellites_per_layer(i) = num_planes(i)*num_sats_per_plane(i);
    delta_RAAN = RAAN(i)/num_planes(i);
    delta__anomaly = 360/num_sats_per_plane(i);
    for j = 1 : num_planes(i)
        for k = 1 : num_sats_per_plane(i)
            Sat_Elements(count).a = r_earth + orbit_altitude(i);
            Sat_Elements(count).i = inclination(i);
            Sat_Elements(count).M0 = (j-1)*Sat_phase_diff_in_adjacent_cells(i)+(k-1)*delta__anomaly;
            Sat_Elements(count).W = True_anomaly(i)+delta_RAAN*(j-1);
            Sat_Elements(count).w = 0;
            Sat_Elements(count).e = 0; 
            count = count + 1;
        end
    end
end
num_satellites = sum(num_satellites_per_layer);

Semi_Major_axis = [Sat_Elements.a];
eccentricity = [Sat_Elements.e];
argument_of_perigee =[Sat_Elements.w];
longitude_of_ascending_node = [Sat_Elements.W];
Sat_inclination = [Sat_Elements.i];
mean_anomaly = [Sat_Elements.M0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% System & Channel Params %%%%%%%%%%%%%%%
K = 2;                      
M_x = 3; M_y = 3;           
elevation_angle_mask = pi/6; % 10 degrees mask     
Cell_radius = 40;           
Cell_latitude = 54.5260000; 
Cell_longtitude = -3.3000000;

% Minimum fraction of timesteps that must have valid (non-zero) channel data.
COVERAGE_THRESHOLD = 0.95;

% --- DATA STRUCTURES FOR META-LEARNING ---
Dataset_Head = {}; 
Dataset_Body = {}; 
Dataset_Tail = {}; 
Head_Counter = 1;
Body_Counter = 1;
Tail_Counter = 1;

fprintf('Starting Simulation...\n');

for chunk = 1 : Num_Chunks
    t_start = (chunk - 1) * Chunk_Duration;
    t_end = min(chunk * Chunk_Duration, Total_Time) - TimeStep;
    if t_end < t_start, t_end = t_start; end
    
    t_sim_chunk = t_start : TimeStep : t_end;
    t_sim_chunk = t_sim_chunk'; 
    chunk_steps = length(t_sim_chunk);
    if chunk_steps == 0, break; end

    % =======================================================
    % Randomize Physical Environment per Chunk (Task)
    % =======================================================
    scenario_rand = rand();
    %  Adjusted probability to 60/40 to ensure enough Tail chunks
    if scenario_rand < 0.6
        env_type = 'Rural/Ped';
        max_speed_ms = 3;
        K_base = 20;
        max_paths = 2;
    else
        env_type = 'Urban/Veh';
        max_speed_ms = 30;
        K_base = 2;
        max_paths = 8;
    end

    % Randomize carrier frequency (2GHz, 7GHz, 12GHz)
    fc_options = [2e9, 7e9, 12e9];
    f_c = fc_options(randi(3));

    % 1. Calculate Sat Positions
    [Latitudes, Longtitudes, Altitudes] = CalculateSatellitesLocation(...
        Semi_Major_axis, eccentricity, argument_of_perigee, ...
        longitude_of_ascending_node, Sat_inclination, mean_anomaly, ...
        num_satellites, t_sim_chunk);
    Altitudes = Altitudes / 1000; 

    % 2. Generate User Slice specifically for this Task's speed
    chunk_users = generate_user_movements(K, chunk_steps, Cell_radius, Cell_latitude, Cell_longtitude, max_speed_ms);

    % 3. Generate Channels
    [Channel, Save_dists, index_visible_sat, visible_sat_count] = RicianChannel(...
        M_x, M_y, elevation_angle_mask, Latitudes, Longtitudes, Altitudes, ...
        K, f_c, chunk_steps, num_satellites, Cell_radius, ...
        Cell_latitude, Cell_longtitude, t_sim_chunk, chunk_users, max_paths, K_base);

    % 4. Identify Serving Satellite & Determine "Difficulty"
    if sum(visible_sat_count) > 0
        mid_idx = ceil(chunk_steps/2);
        
        if visible_sat_count(mid_idx) > 0
            dists = nonzeros(Save_dists(mid_idx,:));
            
            % Select a random visible satellite to allow orbital geometry 
            % to naturally dictate elevation distribution, avoiding confounding biases.
            dist_idx = randi(length(dists));
            
            sat_id = index_visible_sat(mid_idx, dist_idx);
            
            sat_lat = Latitudes(mid_idx, sat_id);
            sat_lon = Longtitudes(mid_idx, sat_id);
            dist_ground = haversine(sat_lon, sat_lat, Cell_longtitude, Cell_latitude);
            
            current_elevation_rad = atan(Altitudes(mid_idx, sat_id) / dist_ground);
            current_elevation_deg = rad2deg(current_elevation_rad);
            
            % Track sat_id across timesteps to handle slot index changes
            Chunk_Data = zeros(M_x*M_y, chunk_steps, K);
            for t_idx = 1:chunk_steps
                slot = find(index_visible_sat(t_idx, :) == sat_id, 1);
                if ~isempty(slot)
                    Chunk_Data(:, t_idx, :) = Channel(:, t_idx, slot, :);
                end
            end

            valid_steps = sum(any(squeeze(Chunk_Data(:, :, 1)) ~= 0, 1));
            coverage = valid_steps / chunk_steps;

            if coverage < COVERAGE_THRESHOLD
                continue;   % skip to next chunk, do not save
            end
            
            % ============================================================
            % META-LEARNING SPLIT LOGIC: Normalized Continuous Score
            % Score components map linearly from 0.0 (easiest) to 1.0 (hardest)
            % ============================================================
            elev_score  = (90 - current_elevation_deg) / 90; % 0 (90 deg) to ~0.89 (10 deg)
            speed_score = (max_speed_ms - 3) / 27;           % 0 (3 m/s) to 1 (30 m/s)
            freq_score  = (f_c - 2e9) / 10e9;                % 0 (2GHz), 0.5 (7GHz), 1 (12GHz)

            difficulty_score = elev_score + speed_score + freq_score;
            
            DataStruct.H = Chunk_Data;
            DataStruct.Time = t_sim_chunk;
            DataStruct.Elevation = current_elevation_deg;
            DataStruct.Environment = env_type;
            DataStruct.Speed = max_speed_ms;
            DataStruct.fc = f_c;
            DataStruct.Difficulty = difficulty_score;
            
            if difficulty_score < 1.2
                Dataset_Head{Head_Counter} = DataStruct;
                Head_Counter = Head_Counter + 1;
                type = sprintf('HEAD (Score: %.2f)', difficulty_score);
            elseif difficulty_score > 2.0
                Dataset_Tail{Tail_Counter} = DataStruct;
                Tail_Counter = Tail_Counter + 1;
                type = sprintf('TAIL (Score: %.2f)', difficulty_score);
            else
                Dataset_Body{Body_Counter} = DataStruct;
                Body_Counter = Body_Counter + 1;
                type = sprintf('BODY (Score: %.2f)', difficulty_score);
            end
            
            fprintf('Chunk %d: Elev %.1f, Env %s, f_c %dGHz -> %s\n', ...
                chunk, current_elevation_deg, env_type, f_c/1e9, type);
        end
    end
end

fprintf('Saving Organized Datasets...\n');
save('MetaLearning_Dataset.mat', 'Dataset_Head', 'Dataset_Body', 'Dataset_Tail', '-v7.3');
fprintf('Done. Head: %d, Body: %d, Tail: %d\n', length(Dataset_Head), length(Dataset_Body), length(Dataset_Tail));