function L_atm = getAtmosphericAttenuation(elev)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute attenuation of arbitrary GNSS signal due to
% attenuation in neutral atmosphere (main contribution).
%
% Formula is taken from: Steigenberger, P., Thoelert, S., Montenbruck, O.:
% GNSS satellite transmit power and its impact on orbit determination.
% Journal of Geodesy, November 2017, DOI 10.1007/s00190-017-1082-2.
%
% Input:  elev  - elevation above horizon in degrees
% Output: L_atm - atmospheric attenuation in dB
%
% Peter Spanik, 18.4.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

a = 6/6378;
L_atm = 0.07*(1 + a/2)./(sind(elev) + sqrt(sind(elev).^2) + 2*a + a^2);


