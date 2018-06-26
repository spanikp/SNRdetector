function plotDetectionResults(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to make figures of SNR estimator values and L3 residuals of PPP
% NRCan processing. Function does not return anything, only figures are
% plotted.
%
% Input:
% meas - meas structure after loading data using "loadINPUTFile.m" and
%        following computation of SNR estimator using "processSNREstimate.m"
%
% fig = [Common figure azimuth/elevation all satellites;
%        individual figures each satellite;
%        correlation residuals <-> S-values]
%
% res - residuals structure - result of function "loadResFile.m"
%     - not mandatory input
%
% Usage: plotDetectionResults(meas,[1,1])
%
% Peter Spanik, 3.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meas = varargin{1};
fig = varargin{2};

if nargin == 3
    res = varargin{3};
end


% Overal figure of all satellites with azimuth/elevation dependency
if fig(1)
    figure('Position',[100,50,800,400])
    detectedAzi = [];
    detectedElev = [];
    cols = lines(size(meas,2));
    legText = cell(0);
    for i = 1:size(meas,2)
        over = meas{1,i}.S > meas{1,i}.Sthreshold;
        plot(meas{1,i}.azi(~over),meas{1,i}.elev(~over),'.','Color',cols(i,:))
        hold on
        grid on
        box on
        detectedAzi = [detectedAzi; meas{1,i}.azi(over)];
        detectedElev = [detectedElev; meas{1,i}.elev(over)];
        legText(end+1) = {sprintf('%s%02d',meas{1,i}.satsys,meas{1,i}.prn)};
    end
    plot(detectedAzi,detectedElev,'ro')
    legend(legText,'Location','SouthEast')
    axis([0 360 0 90])
    title('Detected S-values higher than threshold')
    xlabel('Azimuth (deg)')
    ylabel('Elevation (deg)')
end

% Select residuals part from RES structure
if fig(2)
    for i = 1:size(meas,2)
        elev = meas{1,i}.elev;
        S = meas{1,i}.S;
        threshold = meas{1,i}.Sthreshold;
        Mtime = gps2matlabtime([meas{1,i}.gpsweek, meas{1,i}.gpstime]);
        
        if nargin == 3
            resData = res{1,meas{1,i}.prn};
            resMtime = gps2matlabtime([resData.gpsweek, resData.gpstime]);
            resPhaseRes = 1000*abs(resData.phaseRes);
        end
        
        figure('Position',[200,200,900,400])
        set(gcf,'defaultAxesColorOrder',[[.5 .5 .5]; [0 .5 0]]);
        
        yyaxis left
        if nargin == 3
            plot(resMtime,resPhaseRes,'.','Color',[0 0 1])
        end
        hold on
        box on
        grid on
        plot(Mtime(~(S > threshold)),S(~(S > threshold)),'.','Color',[.5 .5 .5])
        hold on
        box on
        grid on
        plot(Mtime(S > threshold),S(S > threshold),'r.')
        plot(Mtime,threshold,'r-')
        title(sprintf('%s%02d',meas{1,i}.satsys,meas{1,i}.prn))
        ylabel({'Residuals (mm)';'S-value (dBHz)'})
        xlabel('GPS time (HH:MM)')
        
        yyaxis right
        plot(Mtime,elev,'.','Color',[0 .5 0])
        hold on
        box on
        grid on
        datetick('x','HH:MM')
        ylabel('Elevation (deg)')
        if isempty(S(S > threshold))
            if nargin == 3
                legend({'Residual','S-value','Criterion','Elevation'},'Location','NorthEast')
            else
                legend({'S-value','Criterion','Elevation'},'Location','NorthEast')
            end
        else
            if nargin == 3
                legend({'Residual','S-value','S-val > crit','Criterion','Elevation'},'Location','NorthEast')
            else
                legend({'S-value','S-val > crit','Criterion','Elevation'},'Location','NorthEast')
            end
        end
    end
end


