function meas = loadINPUTFile(INPUTFileName,snrIndices,elevMin,elevRange,satFilter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load INPUT structure (from MulipathAnalysis application).
% Output is cell with following structure elements:
%
% meas.prn - satellite PRN number
%     .snr - [n x 3] matrix of SNR on [S1, S2, S3]
%     .gpsweek - GPS week
%     .gpstime - GPS second of week
%     .el - satellite elevation (deg)
%     .azi - satellite azimuth (deg)
%     .satR - satellite geocentric distance (m)
%     .range - range from user to satellite (m)
%
% Peter Spanik, 25.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load(INPUTFileName)
data = INPUT.ObsPosBoth.G;
userpos = INPUT.Aproxpos';
    
p = 0;
for i = 1:size(data,2)
    sel = data{1,i}(end-1,:) > elevMin;
    elev = data{1,i}(end-1,sel)';
    
    if isempty(elev)
        continue
    else
        if range(elev) < elevRange
            continue
        end
    end
    
    if ~ismember(data{1,i}(1,1),satFilter)
        continue
    end
    
    % Testing for zero rows
    snr = data{1,i}(snrIndices,sel)';
    if ~all(sum(snr))
        disp(['G', sprintf('%02d',data{1,i}(1,1)), ': one or more SNR indices not contain data!']);
        continue
    end
    
    % Write data to meas cell structure
    p = p + 1;
    meas{1,p}.prn = data{1,i}(1,1);
    meas{1,p}.blockNumber = getPRNBlockNumber(meas{1,p}.prn);
    meas{1,p}.snr = snr;
    [meas{1,p}.gpsweek, meas{1,p}.gpstime, ~, ~] = greg2gps(data{1,i}(2:7,sel)');
    meas{1,p}.elev = elev;
    meas{1,p}.azi = data{1,i}(end,sel)';
    
    XYZ = data{1,i}(end-7:end-5,sel);
    meas{1,p}.satR = sqrt(sum(XYZ.^2))';
    dXYZ = userpos*ones(1,length(elev)) - XYZ;
    meas{1,p}.range = sqrt(sum(dXYZ.^2))';

end

disp(' ')
disp(['Loaded satellites: ', strjoin(cellfun(@(x) num2str(x.prn),meas,'UniformOutput',false),',')])
disp('===========================================================================')

