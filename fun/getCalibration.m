function calibration = getCalibration(meas,N,K,type,fig,prefix,PNGresolution)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to estimate calibration parameters for SNR estimator. Can work
% in three different modes:
% 
% type = 0 : Estimate universal calibration parameters for all SNR
%            measurements in meas structure together 
% type = 1 : Estimate calibration parameters individually for each satellite
% type = 2 : Estimate calibration parameters individually each distinctive
%            satellite block (e.g. IIR-M, IIF ... )
%
% In any case, output structure calibration has dimension [1,length(meas)+1].
% Additional one is at the end with prn = 100 and represent universal
% calibration results for type = 0 (this case will be always computed).
%
% Inputs:
%
% type 0 - estimate calibration parameters together for all satellites
%      1 - estimate calibration parameters for individual satellites
%      2 - estimate calibration parameters according to satellite block 
%
% N - [1 x 3] matrix containing orders of polynomials to made regression.
%        1st element: S1-S2 modelling
%        2nd element: S1-S5 modelling
%        3rd element: S modelling
%
% K - [1 x 3] matrix defining length of smoothing moving average (@movmean)
%        1st element: smoothing S1-S2
%        2nd element: smoothing S1-S5
%        3rd element: smoothing S
%
% meas - meas cell structure described in "loadINPUTFile.m" file
%
% fig - [1 x 2] matrix defining switches to get figure (fig(1) = 1) and to 
%       save figure as PNG file (fig(2) = 1)
%
% prefix - string containing prefix of output image (or optionally also
%          path where exported images should be stored, e.g. 'img/test')
%
% PNGresolution - string defining resolution of output images (e.g. '-r300')
%
%
% Output: 
%
% calibration - cell structure with same dimensions as meas input.
%               corresponding cell {1,i} is following structure:
% calibration{1,i}.prn - PRN of satellite (100 in case of universal)
%                 .type - calibration type for given satellite
%                 .fit12 - polynomial fit parameters for S1-S2
%                 .fit15 - polynomial fit parameters for S1-S5
%                 .fitS  - polynomial fit parameters for S statistic
%                 .sigmaS  - sigma of fitS polynomial
%
% Peter Spanik, 3.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize calibration cell structure
calibration = cell(1,size(meas,2)+1);

% Compute calibration parameters using all satellites together
snr = cell2mat(cellfun(@(x) x.snr, meas, 'UniformOutput', false)');
elev = cell2mat(cellfun(@(x) x.elev, meas, 'UniformOutput', false)');

% Find edges between satellites
edgesSatsHelp =  cumsum(cellfun(@(x) length(x.elev), meas));
edgesSats = [[1, edgesSatsHelp(1:end-1)+1]; edgesSatsHelp];

[universalCal, plotVals] = getCalibrationParameters(elev,snr,N,K,edgesSats);

if fig(1)
    tit = 'Calibration parameters for all satellites together';
    plotCalibrationResults(plotVals,tit);
    
    if fig(2)
        % Add functionality to check if the path exist, if not create
        % folder
        set(gcf,'PaperPositionMode','auto');
        print([prefix, '_cal_all-sats'],'-dpng',PNGresolution);
    end
end

% Compute calibration parameters for each satellite individually
if type == 0
    calibration(:) = {universalCal};
    for i = 1:size(meas,2)
        calibration{1,i}.prn = meas{1,i}.prn;
        calibration{1,i}.type = 0;
    end
    
    calibration{1,end}.prn = 100;
    calibration{1,end}.type = 0;
    
elseif type == 1
    plotVals = cell(size(meas));
    for i = 1:size(meas,2)
        snr = meas{1,i}.snr;
        elev = meas{1,i}.elev;
        [calibration{1,i}, plotVals{1,i}] = getCalibrationParameters(elev,snr,N,K);
        calibration{1,i}.prn = meas{1,i}.prn;
        calibration{1,i}.type = 1;
        
        % Adding universal calibration
        if i == size(meas,2)
            calibration{1,end} = universalCal;
            calibration{1,end}.prn = 100;
            calibration{1,end}.type = 0;
        end
        
        if fig(1)
            tit = ['Calibration parameters for sat ', sprintf('%s%02d',meas{1,i}.satsys,meas{1,i}.prn)];
            plotCalibrationResults(plotVals{1,i},tit);
            if fig(2)
                set(gcf,'PaperPositionMode','auto')
                print([prefix,sprintf('_cal_ind-sat-%s%02d',meas{1,i}.satsys,meas{1,i}.prn)],'-dpng',PNGresolution);
            end
        end
    end
    
% Compute calibration parameters for each satellite block individually
elseif type == 2
    % Find distinct satellite blocks
    blockNumbers = cellfun(@(x) x.blockNumber, meas);
    distinctBlockNumbers = unique(blockNumbers);
    
    % Initialize plotting matrix structure
    plotVals = cell(1,length(distinctBlockNumbers));
    
    % Make loop throught satellite blocks
    for b = 1:length(distinctBlockNumbers)
        selSameBlock = distinctBlockNumbers(b) == blockNumbers;
        measBlock = meas(selSameBlock);
        
        % Find edges between satellites
        edgesSatsHelp =  cumsum(cellfun(@(x) length(x.elev), measBlock));
        edgesSats = [[1, edgesSatsHelp(1:end-1)+1]; edgesSatsHelp];
        
        snr = cell2mat(cellfun(@(x) x.snr, measBlock, 'UniformOutput', false)');
        elev = cell2mat(cellfun(@(x) x.elev, measBlock, 'UniformOutput', false)');
        
        calibration(selSameBlock) = {getCalibrationParameters(elev,snr,N,K,edgesSats)};
        [~, plotVals{1,b}] = getCalibrationParameters(elev,snr,N,K,edgesSats);
        
        if fig(1)
            satellitesUsed = ['(', strjoin(cellfun(@(x) num2str(x.prn),measBlock,'UniformOutput',false),','), ')'];
            tit = ['Calibration parameters for satellite block: ', sprintf('%1d ',distinctBlockNumbers(b)), satellitesUsed];
            plotCalibrationResults(plotVals{1,b},tit);
            if fig(2)
                set(gcf,'PaperPositionMode','auto')
                print([prefix,sprintf('_cal_ind-block-%1d',distinctBlockNumbers(b))],'-dpng',PNGresolution);
            end
        end
    end
    
    % Adding universal calibration at the end of calibration structure
    for i = 1:size(meas,2)
        calibration{1,i}.prn = meas{1,i}.prn;
        calibration{1,i}.type = 2;
        if i == size(meas,2)
            calibration{1,end} = universalCal;
            calibration{1,end}.prn = 100;
            calibration{1,end}.type = 0;
        end
    end
end

