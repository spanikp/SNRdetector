function obsData = loadObsFile(filepath,saving)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load observation data in Matlab MAT or text RINEX format.
%
% Peter Spanik, 17.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set defaults
if nargin == 1
   saving = true; 
end

% Split the filename and extract extension
[splitted,filename,ext] = fileparts(filepath);

% Decide if load Matlab MAT file or text RINEX file
if strcmpi(ext,'.mat')
    obsData = load(filepath);
    obsData = obsData.obsData;
    fprintf('MAT file "%s" loaded.\n',filepath);
    
elseif regexp(lower(ext),'.[0-9][0-9][oO]')
    obsData = loadRINEXObservation(filepath);
    obsData = getBroadcastPosition(obsData);
    fprintf('RINEX file "%s" loaded.\n',filepath);
    
    % Save loaded file as MAT file
    if saving
        outMatFileName = fullfile(splitted,[filename '.mat']);
        fprintf('\nSaving MAT file to "%s"\n',outMatFileName);
        save(outMatFileName,'obsData');
    end
end
