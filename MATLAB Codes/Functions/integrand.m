function val = integrand(p, species, s_in)
%INTEGRAND Returns specific volume as a function of pressure
%
%   val = INTEGRAND(p, species, s_in) computes the specific volume
%   (1/ρ) at a given pressure for a specified fluid and inlet entropy.
%
%   Inputs:
%       p       - Pressure [Pa]
%       species - Working fluid identifier (string or char array)
%       s_in    - Specific entropy at inlet [J/(kg·K)]
%
%   Output:
%       val     - Specific volume [m^3/kg]
%
%   The function:
%     1. Converts pressure from Pa to bar (required by NFP)
%     2. Computes temperature from pressure and entropy
%     3. Computes density from pressure and temperature
%     4. Returns the inverse of density (specific volume)

% Convert pressure from pascals to bar
pbar = p / 1e5;

% Compute temperature as a function of pressure and entropy
T = NFP(species, 't_ps', pbar, s_in);

% Compute density as a function of pressure and temperature
rho = NFP(species, 'r_pt', pbar, T);

% Specific volume (inverse of density)
val = 1 ./ rho;

end
