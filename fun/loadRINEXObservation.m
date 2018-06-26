function rnx = loadRINEXObservation(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load RINEX v3 observation file to matlab structure.
%
% Usage:
%
% rnx = loadRINEXObservation('myRINEX.yyo','GR'); <- Load only GR obs.
%       loadRINEXObservation('myRINEX.yyo');      <- Load all what is inside
%
% Input: filename - name of input RINEX v3 file
%        filterSystems - array of characters (e.g. 'GR') which should be
%                        extracted from RINEX. If this argument is skipped
%                        all available measurements will be extracted.
%
% Output: rnx - structure containing RINEX loaded data
%
%     Variables used to describe content of RINEX:
%     GNSS - stands for number of stored GNSS systems
%     Epochs - stands for number of stored GNSS systems
%     NoSats - number of specific satellite measurements
%
% rnx.approxPos - [3 x 1] vector of approximate ECEF coordinates
%    .interval - sampling interval in seconds
%    .gnss - [1 x GNSS] character array of GNSS systems (e.g. 'GRE')
%    .obsTypes.(gnss){1 x obsTypes} cell with lists of observation types
%    .noObsTypes - [1 x GNSS] matrix with counts of observation types
%    .t - [Epochs x 8] where columns in matrix have the following format:
%
%       [year, month, day, hour, minute, second, GPSWeek, GPSSecond, mTime]
%
%    .obs.(gnss){1 x NoSats} - [Epochs x noObsTypes] matrix containing
%          measurements. Columns corresponds to obsTypes cell of particular
%          GNSS system.
%
%    .obsqi.(gnss)[Epochs x 2*obsTypes] - character array of quality of
%          observations. Every observation in RINEX is defined by 14 digits
%          (14.3f) and 2 digits defining quality of measurement. These
%          digits are stored in char array rnx.obsqi.(gnss) -> every
%          measurement has 2 digits, that is why width = 2*obsTypes.
%
%    .sat.(gnss) - [1 x nSats] - array defining satellite numbers of
%          particular satellite system.
%
%    .satblock.(gnss) - [1 x nSats] - array defining satellite block numbers
%          according to function "getPRNBlockNumber.m".
%
% Peter Spanik, 8.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear
% clc
% 
% filename = 'obs/LOMS1601.14o';
% filterSystems = 'GREJCIS';
% nargin = 2;
% varargin = {filename, filterSystems};

tic % Start timer

if nargin == 1
    filename = varargin{1};
    filterSystems = 'GREC'; % <-- If necessary to load data of SBAS and IRNSS, just add identifiers here.
elseif nargin == 2
    filename = varargin{1};
    filterSystems = varargin{2};
else
    error('Only 1 or 2 input arguments allowed!');
end

% Reading raw RINEX data using textscan
fprintf('Opening RINEX file: %s\n', filename);
finp = fopen(filename, 'r');
fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
fileBuffer = fileBuffer{1};
fclose(finp);

%% Parsing header records 
lineIndex = 0;

% Initialize rnx structure
fprintf('Reading header ...\n');
rnx = struct('approxPos',[],'interval',0, 'gnss', char(), 'obsTypes', struct(), 'noObsTypes', []);
noSys = 0;

while 1
    lineIndex = lineIndex + 1;
    line = fileBuffer{lineIndex};
    
    if contains(line,'APPROX POSITION XYZ')
        rnx.approxPos = sscanf(line(1:60),'%f');
    end   
    
    if contains(line,'INTERVAL')
        rnx.interval = sscanf(line(1:60),'%f');
    end  
    
    if contains(line,'SYS / # / OBS TYPES')
        if ismember(line(1),filterSystems)
            noSys = noSys + 1;
            rnx.gnss(noSys) = line(1);
            rnx.noObsTypes(noSys) = str2double(line(5:6));

            obsTypes = strsplit(line(8:60));
            obsTypes = obsTypes(1:end-1);
            rnx.obsTypes.(line(1)) = obsTypes;
            
            if strcmp(fileBuffer{lineIndex+1}(1),' ') && contains(fileBuffer{lineIndex+1},'SYS / # / OBS TYPES')
                obsTypes = strsplit(fileBuffer{lineIndex+1}(8:60));
                obsTypes = obsTypes(1:end-1);
                rnx.obsTypes.(line(1))(end+1:end+length(obsTypes)) = obsTypes;
            end
        else
            if ~strcmp(line(1),' ')
                fprintf('   --> sat. system: %s skipped!\n',line(1));
            end
        end
    end
    
    % Breaks if lineIndex reaches 'END OF HEADER'
    if contains(line,'END OF HEADER')
        break
    end
end

% Print message if there are not types given in filter
if nargin == 2
    unavailableGnss = setdiff(filterSystems,rnx.gnss);
    for i = 1:length(unavailableGnss)
        fprintf('   --> sat. system: %s unavailable!\n',unavailableGnss(i));
    end
end

% Check if program should continue
if strcmp(rnx.gnss,'')
    return
end

% Copy body part to new structure
bodyBuffer = fileBuffer(lineIndex+1:end);

% Initializing body structure
rnx.t = [];
rnx.obs = struct();

% Find time moments
fprintf('\nResolving measurement''s epochs ...')
timeSelection = cellfun(@(x) strcmp(x(1),'>'), bodyBuffer);
gregTime= cell2mat(cellfun(@(x) sscanf(x,'> %f %f %f %f %f %f')',...
                  bodyBuffer(timeSelection),'UniformOutput',false));
[GPSWeek, GPSSecond, ~, ~] = greg2gps(gregTime);

rnx.t = [gregTime, GPSWeek, GPSSecond, datenum(gregTime)];

% Allocating cells for satellites
for i = 1:length(rnx.gnss)
    noRows = size(rnx.t,1);
    noCols = rnx.noObsTypes(i);
	rnx.obs.(rnx.gnss(i)) = cell(1,32);
    rnx.obs.(rnx.gnss(i))(:) = {zeros(noRows,noCols)};
    
    % Quality flags as numbers -> slower
    %rnx.obsqi.(rnx.gnss(i))(:) = {zeros(noRows,noCols)};
    
    % Quality flags as array of chars
    rnx.obsqi.(rnx.gnss(i)) = cell(1,32);
    rnx.obsqi.(rnx.gnss(i))(:) = {repmat(' ',[noRows,noCols*2])};
end

fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bResolving measurement''s epochs done!\n')
fprintf('Totally %d epochs will be loaded.\n\n',size(rnx.t,1));

%% Reading body part line by line
carriageReturn = 0;
idxt = 0;
for i = 1:length(bodyBuffer)
    line = bodyBuffer{i};
    
    if strcmp(line(1),'>')
        idxt = idxt + 1;
    else
        sys = line(1);
        sysidx = find(sys == rnx.gnss);
        if ~isempty(sysidx)
            prn = str2double(line(2:3));
            
            lineLength = rnx.noObsTypes(sysidx)*16;
            line = pad(line(4:end),lineLength);
            qi1 = 15:16:lineLength;
            qi2 = 16:16:lineLength;
            
            % Quality info as doubles -> slower
            %qi   = repmat('  .0 ',[1,rnx.noObsTypes(sysidx)]);
            %qi(1:5:5*rnx.noObsTypes(sysidx)) = line(qi1);
            %qi(2:5:5*rnx.noObsTypes(sysidx)) = line(qi2);
            %colqi = sscanf(qi,'%f')';
            
            % Quality info as chars
            colqi = line(sort([qi1, qi2]));
            
            % Erase quality flags and convert code,phase,snr to numeric values
            line([qi1, qi2]) = [];
            line(11:14:lineLength-rnx.noObsTypes(sysidx)*2) = '.';
            col = sscanf(replace(line,' .   ','0.000'),'%f')';
            
            rnx.obs.(sys){1,prn}(idxt,:) = col;
            rnx.obsqi.(sys){1,prn}(idxt,:) = colqi;
        end
    end
    
    % Fast version of text waitbar 
    if rem(i/round(length(bodyBuffer),-3),0.01) == 0
        if carriageReturn == 0
            fprintf('Loading RINEX: %3.0f %%',(i/round(length(bodyBuffer),-3))*100);
            carriageReturn = 1;
        else
            fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bLoading RINEX: %3.0f %%',(i/round(length(bodyBuffer),-3))*100);
        end
    end
end
fprintf('\b\b\b\b\bDone!\n\n');

% Adding field to structure containning available satellites in file
rnx.sat = struct();
rnx.satblock = struct();
for i = 1:length(rnx.gnss)
    satSel = cellfun(@(x) sum(sum(x))~=0, rnx.obs.(rnx.gnss(i)));
	rnx.sat.(rnx.gnss(i)) = find(satSel);
    rnx.satblock.(rnx.gnss(i)) = getPRNBlockNumber(rnx.sat.(rnx.gnss(i)), rnx.gnss(i));
    rnx.obs.(rnx.gnss(i))(~satSel) = [];
    rnx.obsqi.(rnx.gnss(i))(~satSel) = [];
end

toc % Stop timer

