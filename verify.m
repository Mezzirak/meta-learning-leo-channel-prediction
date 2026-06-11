% ==========================================================================
% verify_dataset.m
% Run this after Metalearning_prep.m to check dataset quality before training.
% Checks for: zero chunks, magnitude discontinuities, channel statistics,
% head/tail contrast, and visualises representative examples.
% ==========================================================================
clc; clear all; close all;

fprintf('Loading MetaLearning_Dataset.mat...\n');
load('MetaLearning_Dataset.mat');

num_head = length(Dataset_Head);
num_tail = length(Dataset_Tail);
fprintf('Found %d head chunks and %d tail chunks.\n\n', num_head, num_tail);

if num_head == 0 || num_tail == 0
    error('Dataset is empty. Run Metalearning_prep.m first.');
end

% ==========================================================================
% 1. CHECK EACH CHUNK FOR ZERO TIMESTEPS
%    A chunk with all-zero rows means the satellite dropped below the mask
%    mid-chunk. These will cause catastrophically high NMSE in Python.
% ==========================================================================
fprintf('--- Zero-timestep Check ---\n');
head_bad = [];
tail_bad = [];

for c = 1 : num_head
    H = Dataset_Head{c}.H;   % (9, steps, 2)
    % A timestep is "zero" if all 9 antenna values are exactly zero for user 1
    mag = squeeze(abs(H(:, :, 1)));   % (9, steps)
    zero_steps = sum(all(mag == 0, 1));
    pct = 100 * zero_steps / size(H, 2);
    if zero_steps > 0
        fprintf('  HEAD chunk %02d: %d zero timesteps (%.1f%%)\n', c, zero_steps, pct);
        head_bad(end+1) = c;
    end
end

for c = 1 : num_tail
    H = Dataset_Tail{c}.H;
    mag = squeeze(abs(H(:, :, 1)));
    zero_steps = sum(all(mag == 0, 1));
    pct = 100 * zero_steps / size(H, 2);
    if zero_steps > 0
        fprintf('  TAIL chunk %02d: %d zero timesteps (%.1f%%)\n', c, zero_steps, pct);
        tail_bad(end+1) = c;
    end
end

if isempty(head_bad) && isempty(tail_bad)
    fprintf('  All chunks clean — no zero timesteps found.\n');
else
    fprintf('  WARNING: %d head and %d tail chunks have zero timesteps.\n', ...
        length(head_bad), length(tail_bad));
    fprintf('  These will cause NMSE > 0 dB in Python and should be removed.\n');
end
fprintf('\n');

% ==========================================================================
% 2. MAGNITUDE STATISTICS PER CHUNK
%    Report mean and std of |H| for each chunk.
%    Head should have consistently higher magnitude than tail (lower path loss).
%    Large std within a chunk may indicate a discontinuity.
% ==========================================================================
fprintf('--- Channel Magnitude Statistics ---\n');
fprintf('%-10s %-8s %-10s %-10s %-10s %-10s\n', ...
    'Type', 'Chunk', 'Elev(deg)', 'Mean|H|', 'Std|H|', 'Std/Mean(%)');

head_means = zeros(num_head, 1);
tail_means = zeros(num_tail, 1);

for c = 1 : num_head
    H   = Dataset_Head{c}.H;
    mag = abs(squeeze(H(1, :, 1)));   % antenna 1, user 1
    m   = mean(mag);
    s   = std(mag);
    head_means(c) = m;
    elev = Dataset_Head{c}.Elevation;
    % Flag if coefficient of variation is suspiciously high (>10%)
    flag = '';
    if s/m > 0.10, flag = ' << HIGH VARIATION'; end
    fprintf('%-10s %-8d %-10.2f %-10.2e %-10.2e %-10.1f%s\n', ...
        'HEAD', c, elev, m, s, 100*s/m, flag);
end

for c = 1 : num_tail
    H   = Dataset_Tail{c}.H;
    mag = abs(squeeze(H(1, :, 1)));
    m   = mean(mag);
    s   = std(mag);
    tail_means(c) = m;
    elev = Dataset_Tail{c}.Elevation;
    flag = '';
    if s/m > 0.10, flag = ' << HIGH VARIATION'; end
    fprintf('%-10s %-8d %-10.2f %-10.2e %-10.2e %-10.1f%s\n', ...
        'TAIL', c, elev, m, s, 100*s/m, flag);
end

fprintf('\nMean |H| across HEAD chunks: %.4e\n', mean(head_means));
fprintf('Mean |H| across TAIL chunks: %.4e\n', mean(tail_means));
fprintf('Head/Tail magnitude ratio:   %.2fx\n\n', mean(head_means)/mean(tail_means));

% ==========================================================================
% 3. DOPPLER FREQUENCY CHECK
%    Estimate the dominant oscillation frequency in the real part of H
%    for one head and one tail chunk using FFT.
%    Head (high elev, slow sat angle change) should have lower Doppler.
%    Tail (low elev, fast sat angle change) should have higher Doppler.
% ==========================================================================
fprintf('--- Doppler Frequency Estimate (FFT on real(H), antenna 1, user 1) ---\n');

fs = 1000;   % 1/TimeStep = 1000 Hz

for c = [1, num_head]
    H       = Dataset_Head{c}.H;
    sig     = real(squeeze(H(1, :, 1)));
    N       = length(sig);
    f       = (0:N-1) * fs / N;
    S       = abs(fft(sig));
    S(1)    = 0;   % remove DC
    [~, idx] = max(S(1:floor(N/2)));
    fprintf('  HEAD chunk %02d (elev %.1f deg): dominant frequency = %.1f Hz\n', ...
        c, Dataset_Head{c}.Elevation, f(idx));
end

for c = [1, num_tail]
    H       = Dataset_Tail{c}.H;
    sig     = real(squeeze(H(1, :, 1)));
    N       = length(sig);
    f       = (0:N-1) * fs / N;
    S       = abs(fft(sig));
    S(1)    = 0;
    [~, idx] = max(S(1:floor(N/2)));
    fprintf('  TAIL chunk %02d (elev %.1f deg): dominant frequency = %.1f Hz\n', ...
        c, Dataset_Tail{c}.Elevation, f(idx));
end
fprintf('\n');

% ==========================================================================
% 4. VISUALISE ONE HEAD AND ONE TAIL CHUNK SIDE BY SIDE
%    Real/imag parts and magnitude envelope for comparison.
% ==========================================================================
figure('Name', 'Head vs Tail Verification', 'Position', [50, 50, 1400, 700]);

datasets  = {Dataset_Head{1}, Dataset_Tail{1}};
titles    = {'HEAD (Easy) — Rural/Ped', 'TAIL (Hard) — Urban/Veh'};
colours   = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980]};

for col = 1 : 2
    task = datasets{col};
    H    = task.H;
    T    = task.Time;
    sig  = squeeze(H(1, :, 1));   % antenna 1, user 1

    % --- Real and imaginary (zoomed to 0.1 s) ---
    subplot(2, 2, (col-1)*2 + 1);   % wrong layout, fix below
end

% Redo as 2x2 grid: [head_IQ, tail_IQ; head_mag, tail_mag]
for col = 1 : 2
    task = datasets{col};
    H    = task.H;
    T    = task.Time;
    sig  = squeeze(H(1, :, 1));

    zoom_end = T(1) + 0.1;

    % Top row: real and imaginary (0.1 s zoom)
    subplot(2, 2, col);
    plot(T, real(sig), 'b', 'LineWidth', 1.2); hold on;
    plot(T, imag(sig), 'r', 'LineWidth', 1.2);
    xlim([T(1), zoom_end]);
    title(sprintf('%s\nElev: %.1f deg | Speed: %d m/s', ...
        titles{col}, task.Elevation, task.Speed));
    xlabel('Time (s)'); ylabel('Amplitude');
    legend('Real', 'Imag'); grid on;

    % Bottom row: magnitude envelope (full chunk)
    subplot(2, 2, col + 2);
    plot(T, abs(sig), 'k', 'LineWidth', 1.5);
    xlim([T(1), T(end)]);
    title(sprintf('Magnitude |H| — %s', titles{col}));
    xlabel('Time (s)'); ylabel('|H|'); grid on;

    % Highlight any zero regions in red
    zero_mask = (abs(sig) == 0);
    if any(zero_mask)
        hold on;
        plot(T(zero_mask), zeros(sum(zero_mask), 1), 'rx', 'MarkerSize', 8);
        legend('|H|', 'Zero timesteps');
    end
end

% ==========================================================================
% 5. SUMMARY REPORT
% ==========================================================================
fprintf('=== SUMMARY ===\n');
fprintf('Head chunks: %d total, %d with zero timesteps\n', num_head, length(head_bad));
fprintf('Tail chunks: %d total, %d with zero timesteps\n', num_tail, length(tail_bad));

total_bad = length(head_bad) + length(tail_bad);
if total_bad == 0
    fprintf('Dataset looks clean. Safe to train.\n');
else
    fprintf('\nACTION NEEDED: %d chunks have satellite dropout.\n', total_bad);
    fprintf('Either fix Metalearning_prep.m to reject these chunks,\n');
    fprintf('or use the Python filter (chunk_is_valid) before training.\n');
end

if mean(head_means) <= mean(tail_means)
    fprintf('\nWARNING: Head magnitude is not larger than tail.\n');
    fprintf('Expected head > tail due to lower path loss at high elevation.\n');
    fprintf('Check satellite selection logic in Metalearning_prep.m.\n');
end