function obsData = loadObsFile(filepath)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load observation data in Matlab MAT or text RINEX format.
%
% Peter Spanik, 17.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Split the filename and extract extension
splitted = strsplit(filepath,{'.','/','\'});
filename = splitted{end-1};
ext = splitted{end};

% Decide if load Matlab MAT file or text RINEX file
if strcmpi(ext,'mat')
    obsData = load(filepath);
    obsData = obsData.obsData;
    
elseif regexp(lower(ext),'[0-9][0-9][oO]')
    obsData = loadRINEXObservation(filepath);
    obsData = getBroadcastPosition(obsData);

    % Save loaded file as MAT file
    outMatFileName = [strjoin(splitted(1:end-1),'/'), '.mat'];
    fprintf('\nSaving RINEX observation "%s.%s" to "%s.mat" in the same folder.\n',filename,ext,filename);
    save(outMatFileName,'obsData');
end
