function plotCalibrationResults(plotVals,tit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to plot calibration results according to plotVals variable
% (output of function getCalibrationParameters.m).
%
% Input:
%
% plotVals - [n x 11] matrix with given columns (snr variable has 3 cols):
%            [elev, snr, snr12, snr15, estSnr12, estSnr15, S, estS, kritS]
% 
% tit - string defining overall title of figure (in fact it is title of
%       uppermost subplot). E.g. 'Overal figure title'.
%
% Output:
% 
% MATLAB figure with several graphs showing calibration parameters.
%
% Note: For big screen displays it may be suitable to change output figure
% size on display on line 31.
% 
% Peter Spanik, 30.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find out lower limit of elevation
minElev = min(plotVals(:,1))-1;

% Fitted distributions
rc = fitdist(plotVals(:,9),'rician');
nk = fitdist(plotVals(:,9),'nakagami');
ga = fitdist(plotVals(:,9),'gamma');
%criticalnk = nk.icdf(0.99);
%criticalga = ga.icdf(0.99);

% Figure with S-values, diff(S1-Sx), raw SNR and S-value histogram
figure('Position',[300, 50, 900, 700]);

subplot(3,2,1:2)
plot(plotVals(:,1),plotVals(:,9),'.','Color',[.5 .5 .5]);
grid on
hold on
plot(plotVals(:,1),plotVals(:,10),'k.');
plot(plotVals(:,1),plotVals(:,11),'r.');
%plot(movmean(el,15),movmean(S,15),'y-');
%plot(el,polyval(fitS,el),'.','Color','k');
%plot(el,polyval(fitS,el)+3*sigmaS,'.','Color','r');
%plot(el,criticalnk*ones(size(el)),'.','Color','g');
%plot(el,criticalga*ones(size(el)),'.','Color','b');
%legend({'S-values','S moving average','S-fit function','S-fit + 3\sigma','Nakagami 99%'},'interpreter','tex')
xlim([minElev 90])
legend({'S','fitS','fitS+3\sigma'},'Location','NorthEast','Interpreter','tex')
title(tit)
xlabel('Elevation (deg)')
ylabel('S-value (dBHz)')

subplot(3,2,3)
plot(plotVals(:,1),plotVals(:,5),'b.');
grid on
hold on
plot(plotVals(:,1),plotVals(:,7),'k.');
xlim([minElev 90])
legend({'S1-S2','fit'},'Location','best')
%xlabel('Elevation (deg)')
ylabel('diff SNR (dBHz)')

subplot(3,2,4)
plot(plotVals(:,1),plotVals(:,6),'b.');
grid on
hold on
plot(plotVals(:,1),plotVals(:,8),'k.');
xlim([minElev 90])
legend({'S1-S5','fit'},'Location','southEast')
%xlabel('Elevation (deg)')
ylabel('diff SNR (dBHz)')

subplot(3,2,5)
plot(plotVals(:,1),plotVals(:,2),'b.');
grid on
hold on
plot(plotVals(:,1),plotVals(:,3),'r.');
plot(plotVals(:,1),plotVals(:,4),'g.');
xlim([minElev 90])
legend({'S1','S2','S5'},'Location','best')
xlabel('Elevation (deg)')
ylabel('SNR (dBHz)')
title('SNR values (corr. level applied)')

subplot(3,2,6)
h = histogram(plotVals(:,9),50,'Normalization','pdf');
grid on
hold on
plot(h.BinEdges+0.5*h.BinWidth,pdf(rc,h.BinEdges+0.5*h.BinWidth),'r.-','LineWidth',1.5)
plot(h.BinEdges+0.5*h.BinWidth,pdf(nk,h.BinEdges+0.5*h.BinWidth),'g.-','LineWidth',1.5)
plot(h.BinEdges+0.5*h.BinWidth,pdf(ga,h.BinEdges+0.5*h.BinWidth),'b.-','LineWidth',1.5)
legend({'Data','Rician PDF','Nakagami PDF','Gamma PDF'},'Location','best')
xlabel('S-value')
ylabel('Relative count (PDF)')
title('Histogram of S-values')


