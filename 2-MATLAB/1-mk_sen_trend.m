% Mann-Kendall test and Sen's slope trend analysis for raster time series (2000–2022)

[a, R] = readgeoraster('I:\MK\A_2000.tif');   % Read sample raster to get projection info
info    = geotiffinfo('I:\MK\A_2000.tif');    % Read GeoTIFF metadata (projection, GeoKeyDirectoryTag)

[m, n] = size(a);
cd     = 2022 - 2000 + 1;                    % Number of years (time span: 2000–2022, inclusive)

% Initialize a matrix with (number_of_pixels × number_of_years)
datasum = zeros(m * n, cd) + 0;

p = 1;
for year = 2000:1:2022                       % Start year:step:end year
    filename = ['I:\MK\A_', int2str(year), '.tif']; % Build full path
    
    data = importdata(filename);             % Read raster data
    data = reshape(data, m * n, 1);          % Reshape
    
    datasum(:, p) = data;
    p             = p + 1;
end

sresult = zeros(m, n);                       % MK statistic S
result  = zeros(m, n);                       % Sen's slope B

% Mann-Kendall S statistic
for i = 1:size(datasum, 1)
    data = datasum(i, :);
    
    if min(data) >= 0                        % Valid pixel filter
        sgnsum = [];
        for k = 2:cd
            for j = 1:(k - 1)
                sgn = data(k) - data(j);
                if sgn > 0
                    sgn = 1;
                elseif sgn < 0
                    sgn = -1;
                else
                    sgn = 0;
                end
                sgnsum = [sgnsum; sgn];
            end
        end
        
        sresult(i) = sum(sgnsum);            % MK statistic S
    end
end

% Sen's slope B
for i = 1:size(datasum, 1)
    data = datasum(i, :);
    
    if min(data) >= 0
        valuesum = [];
        for k1 = 2:cd
            for k2 = 1:(k1 - 1)
                cz = data(k1) - data(k2);
                jl = k1 - k2;
                value = cz ./ jl;
                valuesum = [valuesum; value];
            end
        end
        
        result(i) = median(valuesum);        % Sen's slope B
    end
end

% Z-value computation 
vars = cd * (cd - 1) * (2 * cd + 5) / 18;    % MK variance term

zc  = zeros(m, n);
sy  = find(sresult == 0);
zc(sy) = 0;

sy = find(sresult > 0);
zc(sy) = (sresult(sy) - 1) ./ sqrt(vars);

sy = find(sresult < 0);
zc(sy) = (sresult(sy) + 1) ./ sqrt(vars);

% Trend classification
result1 = reshape(result, m * n, 1);
zc1     = reshape(zc, m * n, 1);

tread   = zeros(m, n);

for i = 1:size(datasum, 1)
    
    if result1(i) > 0
        if abs(zc1(i)) >= 2.58
            tread(i) = 4;
        elseif (1.96 <= abs(zc1(i))) && (abs(zc1(i)) < 2.58)
            tread(i) = 3;
        elseif (1.645 <= abs(zc1(i))) && (abs(zc1(i)) < 1.96)
            tread(i) = 2;
        else
            tread(i) = 1;
        end
        
    elseif result1(i) < 0
        if abs(zc1(i)) >= 2.58
            tread(i) = -4;
        elseif (1.96 <= abs(zc1(i))) && (abs(zc1(i)) < 2.58)
            tread(i) = -3;
        elseif (1.645 <= abs(zc1(i))) && (abs(zc1(i)) < 1.96)
            tread(i) = -2;
        else
            tread(i) = -1;
        end
        
    else
        tread(i) = 0;                       % No trend
    end
end

% Export TIFF
geotiffwrite('I:\MK\mk\mk.tif', zc, R,'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);
