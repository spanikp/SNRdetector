function [measCorr, sysEffects] = getSystematicEffect(meas,frequencies,level)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to calculate antenna dependent systematic effect on SNR
% values. Function works only for Trimble R8 Model 3 receiver. Tables of
% receiver/satellites antenna gains are given in folder 'gains'. For usage
% with different antenna model please change the antenna gain paths.
%
% Input: meas - cell [1 x nSats] structure with following fields
%           .elev - elevation angle of satellite (deg)
%           .prn - satellite PRN number (int)
%           .snr - [n x 3] matrix of SNR raw measurement at given
%                  [frequencies]
%           .satR - geocentric distance to satellite (~26000 km) (m)
%
%        frequencies - [1 x 3] frequency bands, e.g. [1, 2, 5]
%
%        level - integer number defining which systematic efects should be
%                evaluated:
%              0 -> no systematic effect assumed
%              1 -> RX antenna gain is evaluated
%              2 -> 1 + TX antenna gain 
%              3 -> 2 + atmospheric attenuation
%              4 -> 3 + free space loss
%
% Output: [measCorr, systemEffects] where:
%         measCorr - copy of input meas cell structure, but with corrected
%                    field sum of all systematic effect for given. No new
%                    field in original meas cell structure is added.
%
%         systemEffects - [n x 12] matrix with correction according to level
%             level = 0 -> [0 0 0 0 0 0 0 0 0 0 0 0]
%             level = 0 -> [x 0 0 0 x 0 0 0 x 0 0 0]            
%             level = 2 -> [x x 0 0 x x 0 0 x x 0 0]
%             level = 3 -> [x x x 0 x x x 0 x x x 0]
%             level = 4 -> [x x x x x x x x x x x x]
%
% Values in [systemEffects] has to be added to raw SNR to get corrected values:
%          
%           snr_corrected = snr_raw + effect
%
% Peter Spanik, 30.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Copying input to output
measCorr = meas;
sysEffects = cell(size(meas));

% Looping for all satellites in meas cell structure
for i = 1:size(meas,2)
    
    % Initialization of sysEffect matrix
    sysEffects{1,i} = zeros(length(meas{1,i}.elev),12);

    % Find out PRN block number
    blockNumber = meas{1,i}.blockNumber;
    
    % Compute nadir angle
    nadir_angle = getSatNadirAngle(meas{1,i}.elev,'G');
    
    % Compute relative attenuation due to atmosphere
    atmAttenuation = getAtmosphericAttenuation(meas{1,i}.elev);
    
    % Select correct satellite gain pattern and compute receiver/antenna
    % gains according to frequency
    for f = 1:3
        
        freq = frequencies(f);
        if freq == 1
                RxGainCorrection = getGainCorrection(meas{1,i}.elev, 'gains/gainTRMR8_L1L2L5.csv', 2);
                TxGainCorrection = getGainCorrection(nadir_angle, 'gains/GPS_AntennaGains_L1Band.csv', blockNumber);
        elseif freq == 2
                RxGainCorrection = getGainCorrection(meas{1,i}.elev, 'gains/gainTRMR8_L1L2L5.csv', 3);
                TxGainCorrection = getGainCorrection(nadir_angle, 'gains/GPS_AntennaGains_L2Band.csv', blockNumber);
        elseif freq == 5
                RxGainCorrection = getGainCorrection(meas{1,i}.elev, 'gains/gainTRMR8_L1L2L5.csv', 4);
                TxGainCorrection = getGainCorrection(nadir_angle, 'gains/GPS_AntennaGains_L5Band.csv', blockNumber);
        end
        
        % Removing absolute part of TX gain
        TxGainCorrection = TxGainCorrection - mean(TxGainCorrection); 
        
        % Evaluate only if level == 4
        if level == 4
            % Find out wavelength
            wavelength = getWavelength('G', freq, meas{1,i}.prn);
            
            % Compute relative attenuation due to free space loss
            FSPLCorrection = fspl(meas{1,i}.satR,wavelength);
            FSPLCorrection = FSPLCorrection - mean(FSPLCorrection);
        end
           
        % Sum all effects together according to systematic effect level
        switch level
            case 0
                effectMatrix = zeros(length(meas{1,i}.elev),4);
            case 1
                effectMatrix = [-RxGainCorrection, zeros(length(meas{1,i}.elev),3)];
                measCorr{1,i}.snr(:,f) = measCorr{1,i}.snr(:,f) - RxGainCorrection;
            case 2
                effectMatrix = [-RxGainCorrection, TxGainCorrection, zeros(length(meas{1,i}.elev),2)];
                measCorr{1,i}.snr(:,f) = measCorr{1,i}.snr(:,f) - RxGainCorrection + TxGainCorrection;
            case 3
                effectMatrix = [-RxGainCorrection, TxGainCorrection, atmAttenuation, zeros(length(meas{1,i}.elev),1)];
                measCorr{1,i}.snr(:,f) = measCorr{1,i}.snr(:,f) - RxGainCorrection + TxGainCorrection + atmAttenuation;
            case 4
                effectMatrix = [-RxGainCorrection, TxGainCorrection, atmAttenuation, FSPLCorrection];
                measCorr{1,i}.snr(:,f) = measCorr{1,i}.snr(:,f) - RxGainCorrection + TxGainCorrection + atmAttenuation + FSPLCorrection;
        end
        
        % Resulting sysEffect matrix for given satellite
        sysEffects{1,i}(:,f*4-3:f*4) = effectMatrix;
    end
end

disp(' ')
disp(['Correction level: ', num2str(level)])
disp(['Corrected SNR: ', strjoin(arrayfun(@(x) num2str(x),frequencies,'UniformOutput',false),',')])
disp(['Corrected satellites: ', strjoin(cellfun(@(x) num2str(x.prn),measCorr,'UniformOutput',false),',')])
disp('===========================================================================')
