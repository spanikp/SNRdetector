function [calibration, plotVals] = getCalibrationParameters(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute polynomial fits of differences S1-S2, S1-S5 and S
% with given order N. Optionally you can set smoothing of SNR differences 
% and final statistic S.
%
% Inputs: - 3, 4 or 5 inputs possible:
%
% a) three case (varargin = [elev, snr, N])
% elev - [n x 1] matrix of satellite elevation (deg)
% snr - [n x 3] matrix of SNR measurements [S1, S2, S5] (dBHz)
% N - [1 x 3] matrix containing orders of polynomials to made regression.
%        1st element: S1-S2 modelling
%        2nd element: S1-S5 modelling
%        3rd element: S modelling
%
% b) four case (varargin = [elev, snr, N, K])
% K - [1 x 3] matrix defining length of smoothing moving average (@movmean)
%        1st element: smoothing S1-S2
%        2nd element: smoothing S1-S5
%        3rd element: smoothing S
% 
% c) five case (varargin = [elev, snr, N, K, edgesSats])
% edgesSats - [n x 1] logical vector defining different satellites (used in
% 
%
% Output:
% calibration - structure with following fields
%      .prn - PRN sat. number (100 in case of universal)
%      .fit12 - polynomial fit parameters for S1-S2
%      .fit15 - polynomial fit parameters for S1-S5
%      .fitS  - polynomial fit parameters for S statistic
%      .sigmaS  - sigma of fitS polynomial
% 
% plotVals - [n x 11] matrix with given columns (snr variable has 3 cols):
%            [elev, snr, snr12, snr15, estSnr12, estSnr15, S, estS, kritS]
% 
% Peter Spanik, 26.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Chcech the number of input arguments
if nargin == 3
    elev = varargin{1};
    snr = varargin{2};
    N = varargin{3};
    K = [1, 1, 1];
    edgesSats = [1; length(elev)];
    
elseif nargin == 4
    elev = varargin{1};
    snr = varargin{2};
    N = varargin{3};
    K = varargin{4};
    edgesSats = [1; length(elev)];
    
elseif nargin == 5
    elev = varargin{1};
    snr = varargin{2};
    N = varargin{3};
    K = varargin{4};
    edgesSats = varargin{5};
end

% Compute SNR differences
if nargin == 3 || nargin == 4
    snr12 = movmean(snr(:,1) - snr(:,2),K(1));
    snr15 = movmean(snr(:,1) - snr(:,3),K(2));
    
elseif nargin == 5
    snr12 = zeros(size(elev));
    snr15 = zeros(size(elev));
    
    for k = 1:size(edgesSats,2)
        edgeSel = edgesSats(1,k):edgesSats(2,k);
        snr12(edgeSel,1) = movmean(snr(edgeSel,1) - snr(edgeSel,2),K(1));
        snr15(edgeSel,1) = movmean(snr(edgeSel,1) - snr(edgeSel,3),K(2));
    end
end

% Estimate polynomial of differences
p12 = polyfit(elev,snr12,N(1));
p15 = polyfit(elev,snr15,N(2));

% Estimated values of polynomials
estSnr12 = polyval(p12,elev);
estSnr15 = polyval(p15,elev);

% Compute statistics and its fit
if nargin == 3 || nargin == 4
    S = movmean(sqrt((snr12 - estSnr12).^2 + (snr15 - estSnr15).^2),K(3));
elseif nargin == 5
    S = zeros(size(elev));
    for k = 1:size(edgesSats,2)
        edgeSel = edgesSats(1,k):edgesSats(2,k);
        S(edgeSel,1) = movmean(sqrt((snr12(edgeSel) - estSnr12(edgeSel)).^2 + ...
                                    (snr15(edgeSel) - estSnr15(edgeSel)).^2),K(3));
    end
end

% Fit of S statistic polynomial
fitS = polyfit(elev,S,N(3));
estS = polyval(fitS,elev);
sigmaS = std(S - estS,1);
kritS = estS + 3*sigmaS;

% Write results to calibration structure
calibration.fit12 = p12;
calibration.fit15 = p15;
calibration.fitS = fitS;
calibration.sigmaS = sigmaS;

% Write to plotVals matrix
plotVals = [elev, snr, snr12, snr15, estSnr12, estSnr15, S, estS, kritS];
