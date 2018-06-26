function res = loadResFile(filename,satsys)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to read CSRS-PPP *.res file
%
% Input: filename - file have to be compliant with CSRS RES file format
%        satsys - satellite system identifier ('G' or 'R')
%
% Output: res - [1 x n] cell (for GPS n = 32, for GLO n = 24)
%          .gpstime - GPS second of week (sec)
%          .mTime - MATLAB internal time format (days)
%          .el - sat. elevation (deg)
%          .azi - sat. azimuth (deg)
%          .codeRes - pseudorange residual (m)
%          .phaseRes - phase residual (m)
%            
% Example: res = readResFile('REKT1161.res','G')
%
% Peter Spanik, 3.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loading file
finp = fopen(filename,'r');
data = textscan(finp,'%s %f-%f-%f  %f %f:%f:%f  %1s%2s%f %f %f %f %f %f %f %f %f %f %f %f %f %f','Headerline',7);
fclose(finp);

% Get all data
satnumber = data{1,11};
azi = data{1,12};
el = data{1,13};
codeRes = data{1,14};
phaseRes = data{1,15};
time = [data{1,2}, data{1,3}, data{1,4}, data{1,6}, data{1,7}, data{1,8}];

% Sorting the data accroding to sat. system and sat. number
switch satsys
    case 'G'
    	selsys = cellfun(@(x) x == 'P', data{1,9});
        res = cell(1,32);
        
        for j = 1:32
            selsat = satnumber == j;
            sel = selsys & selsat;
            [res{1,j}.gpsweek, res{1,j}.gpstime, ~, ~] = greg2gps(time(sel,:));
            res{1,j}.mTime = datenum(time(sel,:));
            res{1,j}.azi = azi(sel);
            res{1,j}.el = el(sel);
            res{1,j}.codeRes = codeRes(sel);
            res{1,j}.phaseRes = phaseRes(sel);
        end
        
    case 'R'
        selsys = cellfun(@(x) x == 'R', data{1,9});
        res = cell(1,24);
        
        for j = 1:24
            selsat = satnumber == j;
            sel = selsys & selsat;
            [res{1,j}.gpsweek, res{1,j}.gpstime, ~, ~] = greg2gps(time(sel,:));
            res{1,j}.azi = azi(sel);
            res{1,j}.el = el(sel);
            res{1,j}.codeRes = codeRes(sel);
            res{1,j}.phaseRes = phaseRes(sel);
        end
    otherwise
        error('Only GPS or GLONASS allowed!')  
end
