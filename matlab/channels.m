function [channel] = channels()
loaded_data = load('your_matrix.mat');
channel = loaded_data.your_matrix;
end