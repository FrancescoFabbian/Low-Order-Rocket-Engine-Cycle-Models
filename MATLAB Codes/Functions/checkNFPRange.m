function [isValid, msg] = checkNFPRange(species, p_in, T_in)
% CHECKNFPRANGE  Checks whether a thermodynamic state is within NFP limits
%
% INPUTS:
%   species : string (e.g. 'H2', 'CH4')
%   p_in    : pressure [Pa]
%   T_in    : temperature [K]
%
% OUTPUTS:
%   isValid : logical (true if state is valid for NFP)
%   msg     : diagnostic message (string)
%

% Convert pressure to bar (NFP convention)
pbar = p_in / 1e5;

% NFP validity limits
Tmin = NFP(species,'mint');   % [K]
Tmax = NFP(species,'maxt');   % [K]
pmin = NFP(species,'minp');   % [bar]
pmax = NFP(species,'maxp');   % [bar]

% Initialize
isValid = true;
msg = 'State is within NFP validity range';

% Temperature check
if T_in < Tmin
    isValid = false;
    msg = sprintf('Temperature %.2f K below NFP minimum %.2f K', T_in, Tmin);
    return
end

if T_in > Tmax
    isValid = false;
    msg = sprintf('Temperature %.2f K above NFP maximum %.2f K', T_in, Tmax);
    return
end

% Pressure check
if pbar < pmin
    isValid = false;
    msg = sprintf('Pressure %.3f bar below NFP minimum %.3f bar', pbar, pmin);
    return
end

if pbar > pmax
    isValid = false;
    msg = sprintf('Pressure %.3f bar above NFP maximum %.3f bar', pbar, pmax);
    return
end

end
