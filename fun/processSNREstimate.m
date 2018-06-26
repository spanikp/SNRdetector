function meas = processSNREstimate(meas,calibration,K)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute S-value from real data and calibration file.
% Smoothing is controlled via [1 x 3] K matrix.
% 
% Inputs:
%
% meas - meas structure after loading data using "loadINPUTFile.m",
% calibration - calibration structure output of "getCalibration.m",
% K - [1 x 3] matrix defining length of smoothing moving average (@movmean)
%      1st element: smoothing S1-S2
%      2nd element: smoothing S1-S5
%      3rd element: smoothing S
% fig - [1 x 2] switch for plotting graphs [allSats, individualPlots]
%
% Output:
%
% meas - input structure with added fields:
%   .S - S-values for given satellite
%   .Streshold - threshold value for given elevation
%
% Peter Spanik, 3.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find out what PRNs are in calibration file
calPrn = cellfun(@(x) x.prn, calibration);
calType = cellfun(@(x) x.type, calibration);

% Looping over satellites in meas structure
for i = 1:size(meas,2)
    % Extracting SNR measurements and elevation
    snr = meas{1,i}.snr;
    elev = meas{1,i}.elev;
    prn = meas{1,i}.prn;
    
    % Choose individual/universal calibration
    [prnCalibrated, indexCal] = ismember(prn, calPrn);
    if prnCalibrated == 1 && calType(indexCal) == 1
        tit = ' (individual calibration)';
        cal = calibration{1,indexCal};
    else
        tit = ' (universal calibration)';
        cal = calibration{1,end};
    end
    
    disp(['Computing S-values of G', sprintf('%02d',meas{1,i}.prn), tit]);
    [S, threshold] = getSNREstimator(elev,snr,cal,K);
    
    % Adding computed S-vals to meas structure
    meas{1,i}.S = S;
    meas{1,i}.Sthreshold = threshold;
    
end



