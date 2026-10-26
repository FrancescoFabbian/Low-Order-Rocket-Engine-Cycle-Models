function Ar = iso_a_ratio(M, gamma)
%ISO_A_RATIO Computes the isentropic area ratio A/A*
%
%   Ar = ISO_A_RATIO(M, gamma) returns the isentropic area ratio (A/A*)
%   for a given Mach number M and ratio of specific heats gamma.
%
%   Inputs:
%       M     - Mach number (can be scalar or vector)
%       gamma - Ratio of specific heats (e.g., 1.4 for air)
%
%   Output:
%       Ar    - Isentropic area ratio A/A*
%
%   This relation is commonly used in compressible flow and
%   gas dynamics for isentropic nozzle flow analysis.

% Compute the isentropic area–Mach number relationship
Ar = (1 ./ M) .* ...
     ((2 ./ (gamma + 1)) .* ...
     (1 + (gamma - 1)/2 .* M.^2)) .^ ...
     ((gamma + 1) / (2 * (gamma - 1)));

end