function Gain = getGainCorrection(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to interpolate antenna gain pattern for given set of angles.
%
% Input: angles - vector of elevation or nadir angles in degrees
%        table can be: 
%           * matrix consisting of gain pattern (first column is elevation 
%             or nadir angle in deg, second column is gain in dB or dBi).
%
%           * string containing absolute or relative path to file with
%            following values:
%
%              El,Gain1,Gain2,Gain3       <- File contains exactly 1 header 
%              0.0,-6.452,-9.154,-8.125      line with comma as delimiter
%              0.5,-6.361,-10.154,-8.455
%              1.0,-6.270,-10.458,-8.548
%              1.5,-6.178,-10.789,-8.884
%              2.0,-6.088,-10.898,-8.991
%              2.5,-6.003,-10.925,-9.145
%              
% Usage: gain = getGainCorrection(angles, [angles_gain, Gain_dB], 2)
%        gain = getGainCorrection(angles, 'antGain.txt', 3)
%
% Peter Spanik, 25.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin ~= 3
    error('Only three inputs are allowed - required elevation, gain pattern table and index of gain! \n%s\n%s',...
          '',...
          ' Example usage: Gain = getGainCorrection(elev,[GainEl, Gain1, Gain2, Gain3],2)');
end

angle = varargin{1};
table = varargin{2};
index = varargin{3};

if isfloat(table) 
	GainTable = table;
elseif ischar(table) 
    GainTableAll = importdata(table, ',', 1);
    GainTable = GainTableAll.data(:,[1, index]);
end

Gain = interp1(GainTable(:,1),GainTable(:,2),angle,'linear','extrap');
