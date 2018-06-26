function [S, threshold] = getSNREstimator(elev,snr,calibration,K)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute SNR estimator values S from given SNR (on 2 or three
% different frequencies and given polynomial calibration functions.
%
% Input:
% 
% elev - [n x 1] matrix defining elevation angle of satellite
%
% snr - [x x 3] matrix of SNR values [S1, S2, S3] - may or may not be 
%       corrected using getSystematicEffect.m function.
%
% calibration - structure with following fields:
%        .fit12 - polynomial fit parameters for S1-S2
%        .fit15 - polynomial fit parameters for S1-S5
%        .fitS  - polynomial fit parameters for S statistic
%        .sigmaS  - sigma of fitS polynomial
%
% K - [1 x 3] matrix defining length of smoothing moving average (@movmean)
%        1st element: smoothing S1-S2
%        2nd element: smoothing S1-S5
%        3rd element: smoothing S
%
% Peter Spanik, 2.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute SNR differences and difference residuals
dsnr12 = movmean(snr(:,1) - snr(:,2),K(1)) - polyval(calibration.fit12,elev);
dsnr15 = movmean(snr(:,1) - snr(:,3),K(2)) - polyval(calibration.fit15,elev);

% Computing estimator value
S = movmean(sqrt(dsnr12.^2 + dsnr15.^2),K(3));

% Comparing to threshold
threshold = (polyval(calibration.fitS,elev) + 3*calibration.sigmaS);
aboveThreshold = S > threshold;

