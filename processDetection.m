%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main script to process observation RINEX files (or alternatively also 
% preprocessed MATLAB *.mat file) to detect multipath using combination of
% SNR measurements. 
%
% Peter Spanik, 26.6.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
clear
clc

%% Adding functions to path
addpath('fun')
addpath('eph')

%% Setting of Calibration 
% Input file settings
settings.inputObsFileName          = 'obs/calibration/example_calibration.18o';    % ObsData MAT file or RINEX file accepted
settings.inputFileSNRIndices       = [9,10,12];             % 1x3 matrix defining indices of SNR vals in RINEX file
settings.inputFileSNRFreq          = [1,2,5];               % 1x3 matrix defining carrier frequencies, e.g. [1,2,5], also [1,2,2] allowed
settings.inputSatsys               = 'G';                   % Satellite systems G,R,E and C are allowed

% Computation settings
settings.calibrationType           = 0;                     % 0 (all sats together), 1 (every satellite alone), 2 (common cal. parameters for block)
settings.levelSysEffectModel       = 0;                     % level of modeling systematic effects (see getSystematicEffect.m)                          
settings.fittingPolynomialOrder    = [3,3,3];               % polynomials used for SNR differences modeling
settings.smoothingWindowLength     = [1,1,1];               % length of smoothing window [S1-S2, S1-S5, S]

% Satellite selection settings
settings.inputSatFilter            = [1,3,8,9,27,30,32];  % 1xn vector defining sat. selection
%settings.inputSatFilter([6])       = [];                    % Reject some satellites from calibration
settings.minElevAngle              = 10;                    % cut-off angle for satellite observations
settings.minElevRange              = 10;                    % setting of minimal elevation range (reject short observations)

% Plotting/printing settings
settings.calibrationPlot           = [1,1];                 % plots of calibration results: [makePlot, savePlotAsPNG]
settings.calibrationPlotPrefix     = 'img/example';         % prefix for naming PNG images (path have to exist)
settings.calibrationPlotResolution = '-r150';               % resolution of PNG


%% Loading content of input observation file
obsDataCal = loadObsFile(settings.inputObsFileName);


%% Convert calibration obsData structure to meas structure
meas = createMeasurementCell(obsDataCal,...
                             settings.inputSatsys,...
                             settings.inputFileSNRIndices,...
                             settings.minElevAngle,...
                             settings.minElevRange,...
                             settings.inputSatFilter);

                 
%% Evaluate systematic effects
% Evaluation of systematic effects is available only for GPS and Galileo.
% In case of other system comment following line and uncomment next one.
[measCorr, sysEffect] = getSystematicEffect(meas,settings.inputFileSNRFreq,settings.levelSysEffectModel);
%measCorr = meas;

%% Processing calibration measurement
calibration = getCalibration(measCorr,settings.fittingPolynomialOrder,...
                             settings.smoothingWindowLength,...
                             settings.calibrationType,...
                             settings.calibrationPlot,...
                             settings.calibrationPlotPrefix,...
                             settings.calibrationPlotResolution);

                         
%% Loading data under testing conditions
% Input file settings
testing.inputObsFileName           = 'obs/testing/example_detection.18o';  % ObsData MAT file or RINEX file accepted
testing.inputFileSNRIndices        = [9,10,12];           % 1x3 matrix defining indices of SNR vals in RINEX file
testing.inputFileSNRFreq           = [1,2,5];             % 1x3 matrix defining carriers, e.g. [1,2,5], also [1,2,2] allowed
testing.inputSatsys                = 'G';                 % Satellite system (one of G,R,E,C)
testing.NRCanResFile               = 'res/track.res';     % Path to residual's file from PPP NRCan service processing (not mandatory)

testing.minElevAngle               = 0;                   % Settings for satellite selection as above in calibration case
testing.minElevRange               = 0;
testing.inputSatFilter             = 1:32;
testing.levelSysEffectModel        = settings.levelSysEffectModel;
testing.smoothingWindowLength      = [1,1,1];
testing.drawPlots                  = [1,1];               % plot detection results: [makePlot, savePlotAsPNG]


%% Loading obsData structure and convert it to 
obsDataTest = loadObsFile(testing.inputObsFileName);

%% Convert calibration obsData structure to meas structure
measTest = createMeasurementCell(obsDataTest,...
                                 testing.inputSatsys,...
                                 testing.inputFileSNRIndices,...
                                 testing.minElevAngle,...
                                 testing.minElevRange,...
                                 testing.inputSatFilter);


%% Compute systematic effects
% Evaluation of systematic effects is available only for GPS and Galileo.
% In case of other system comment following line and uncomment next one.
[measTestCorr, testSysEffect] = getSystematicEffect(measTest,testing.inputFileSNRFreq,testing.levelSysEffectModel);
%measTestCorr = measTest;


%% Compute SNR estimator
testCorr = processSNREstimate(measTestCorr,calibration,testing.smoothingWindowLength);


%% Plotting 
if exist(fullfile(pwd,testing.NRCanResFile),'file')
    res = loadResFile(testing.NRCanResFile,testing.inputSatsys);
    plotDetectionResults(testCorr,testing.drawPlots,res)
else
    plotDetectionResults(testCorr,testing.drawPlots)
end








