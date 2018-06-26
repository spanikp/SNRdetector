function meas = createMeasurementCell(obsData,satsys,snrIndices,elevMin,elevRange,satFilter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to convert obsData structure (output of "loadObsFile.m") to meas
% cell structure used for further SNR Estimator processing.
%
% Input:  obsData - return structure of function "loadObsFile.m" (in other
%                   words: loaded RINEX using "loadRINEXObservation.m" with
%                   following processing using "getBroadcastPosition.m".
%
%         satsys  - satellite system identifier
% 
%         snrIndices - indices of SNR values which we want to store in meas
%                   structure. Indices correspond to "SYS / # / OBS TYPES"
%                   record in RINEX header.
%
%         elevMin - minimum elevation to account for satellite 
%
%         elevRange - minimum range of sat. elevation to account for satellite
%
%         satFileter - [1 x n] vector containing PRN numbers of satellites
%                   which should be proceed.
%
% Output: meas - cell structure with following structure elements:
%           .prn - satellite PRN number
%           .satsys - satellite system
%           .blockNumber - satellite block number
%           .snr - [n x 3] matrix of SNR on [S1, S2, S3]
%           .gpsweek - GPS week
%           .gpstime - GPS second of week
%           .mTime - MATLAB time
%           .elev - satellite elevation (deg)
%           .azi - satellite azimuth (deg)
%           .satR - satellite geocentric distance (m)
%           .range - range from user to satellite (m)
%
% Peter Spanik, 17.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Initialize meas structure and looping through observations in obsData
data = obsData.obs.(satsys);
meas = cell(size(data));
for i = 1:length(obsData.sat.(satsys))
    prn = obsData.sat.(satsys)(i);
    sel = obsData.satpos.(satsys){i}(:,4) > elevMin;
    selIdx = find(sel);
    elev = obsData.satpos.(satsys){i}(sel,4);
    
    % Filtration based on elevation angle
    if isempty(elev)
        continue
    else
        if range(elev) < elevRange
            continue
        end
    end
    
    % Skip satellite if it is not member of satFilter
    if ~ismember(prn,satFilter)
        continue
    end
    
    % Testing for zero columns (one or more SNR is not available for particular satellite)
    snrWithMissing = data{1,i}(sel,snrIndices);
    missingDataIdx = find(sum(snrWithMissing) == 0);
    if ~isempty(missingDataIdx)
        fprintf('%s%02d: Some SNR index not contain data!\n',satsys, prn);
        continue
    end
    
    % Further filtering SNR matrix (some epochs may be incomplete -> remove)
    sel2 = snrWithMissing(:,1) ~= 0 & snrWithMissing(:,2) ~= 0 & snrWithMissing(:,3) ~= 0;
    snr = snrWithMissing(sel2,:);
    snrIdx = selIdx(sel2);
    
    
    % Write data to meas cell structure
    meas{i}.prn = prn;
    %meas{i}.blockNumber = getPRNBlockNumber(prn);
    meas{i}.satsys = satsys;
    meas{i}.blockNumber = obsData.satblock.(satsys)(i);
    meas{i}.snr = snr;
    [meas{i}.gpsweek, meas{i}.gpstime, ~, ~] = greg2gps(obsData.t(snrIdx,1:6));
    meas{i}.mTime = obsData.t(snrIdx,9);
    meas{i}.elev = elev(sel2);
    meas{i}.azi = obsData.satpos.(satsys){i}(snrIdx,5);
    
    XYZ = obsData.satpos.(satsys){i}(snrIdx,1:3);
    meas{i}.satR = sqrt(sum(XYZ.^2,2));
    meas{i}.range = obsData.satpos.(satsys){i}(snrIdx,6);

end

% Clear empty cells in meas structure
selEmpty = cellfun(@(x) isempty(x),meas);
meas(selEmpty) = [];

% Displaying info
fprintf('\n')
fprintf('Loaded satellites: %s\n', strjoin(cellfun(@(x) num2str(x.prn),meas,'UniformOutput',false),','));
fprintf('===========================================================================\n')

