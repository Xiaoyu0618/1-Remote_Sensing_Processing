clc;    % Clear command window
clear;  % Clear workspace variables

% Convert annual and monthly AI from NetCDF dataset to GeoTIFF format

% Path to NetCDF dataset (modify if needed)
ncFilePath = 'H:\Arid index\AI_annual_2018.nc';
ncdisp(ncFilePath);  % Display NetCDF structure

% Read spatial reference from a sample GeoTIFF
[~, R] = geotiffread('H:\Arid index\ai_Layer.tif');  
info   = geotiffinfo('H:\Arid index\ai_Layer.tif');

% Read AI data from NetCDF (modify variable name if necessary)
data = ncread(ncFilePath, 'ai');

for year = 2018:2018   % Currently only processing year 2018
    % Extract 12 monthly slices (time dimension)
    data1 = data(:, :, 1 + 12 * (year - 2018) : 12 * (year - 2017));

    % Annual mean
    data3 = sum(data1, 3) / 12;

    % Rotate and flip to match GeoTIFF orientation
    data_rot  = rot90(data3);
    data_flip = flipud(data_rot);

    if ~isequal(size(data_flip), R.RasterSize)
        data_flip = data_flip';  % Fix dimension mismatch
    end

    % Output annual GeoTIFF
    filename = strcat('H:\Arid index\AI_annual', num2str(year), 'ai.tif');
    if isfield(info.GeoTIFFTags, 'GeoKeyDirectoryTag')
        geotiffwrite(filename, data_flip, R, ...
            'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);
    else
        geotiffwrite(filename, data_flip, R);
    end

    % Monthly output
    for mon = 1:12
        data2 = data1(:, :, mon);

        data_rot  = rot90(data2);
        data_flip = flipud(data_rot);

        if ~isequal(size(data_flip), R.RasterSize)
            data_flip = data_flip';
        end

        filename = strcat('H:\Arid index\AI_annual\', ...
                          num2str(year), '_', num2str(mon), 'yai.tif');

        if isfield(info.GeoTIFFTags, 'GeoKeyDirectoryTag')
            geotiffwrite(filename, data_flip, R, ...
                'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);
        else
            geotiffwrite(filename, data_flip, R);
        end
    end
end
