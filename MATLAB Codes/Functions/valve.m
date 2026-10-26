function [p_out, T_out, H_out, S_out, rho_out, n_out] = valve(species, varargin)
% VALVE  Isenthalpic valve for either NFP fluids or HGS mixtures.
%
% This function models a steady-state, adiabatic throttling (isenthalpic) valve.
% - For a single species (string), it uses NFP real-fluid properties.
% - For a reacting gas mixture (cell array), it uses HGS properties.
%
% -------------------------------------------------------------------------
% INPUTS:
%   species : string (single fluid) or cell array of species (HGS mixture)
%
% NFP mode inputs:
%   T_in    : inlet temperature [K]
%   p_in    : inlet pressure [Pa]
%   Pr      : pressure ratio [-]  (p_out = p_in / Pr)
%
% HGS mode inputs:
%   n       : molar flow vector [mol/s]
%   T_in    : inlet temperature [K]
%   p_in    : inlet pressure [Pa]
%   Pr      : pressure ratio [-]  (p_out = p_in / Pr)
%
% OUTPUTS:
%   p_out   : outlet pressure [Pa]
%   T_out   : outlet temperature [K]
%   H_out   : outlet total enthalpy (kJ)  (extensive)
%   S_out   : outlet total entropy (kJ/K)
%   rho_out : outlet density [kg/m^3]
%   n_out   : outlet molar flow vector (unchanged for HGS, [] for NFP)
% -------------------------------------------------------------------------

% Check input type
if ischar(species) || isstring(species)
    %% -------- NFP Mode --------
    T_in = varargin{1};
    p_in = varargin{2};
    Pr   = varargin{3};

    pbar_in = p_in / 1e5;  % bar

    % NFP limits
    % Checking NFP validity
    [isValid, ~] = checkNFPRange(species, p_in, T_in);
    if isValid

    % Inlet enthalpy
    h_in = NFP(species,'h_pt',pbar_in,T_in);   % [kJ/kg]

    % Isenthalpic throttling
    h_out = h_in;
    p_out = p_in / Pr;                         % [Pa]
    pbar_out = p_out / 1e5;

    % Outlet state
    T_out   = NFP(species,'t_hp',h_out,pbar_out);
    S_out   = NFP(species,'s_pt',pbar_out,T_out);
    rho_out = NFP(species,'r_pt',pbar_out,T_out);
    n_out   = [];  % Not used in NFP mode
    H_out   = h_out; % extensive = same as specific for single species

    else
    disp('We cannot use NFP');
    end

elseif iscell(species)
    %% -------- HGS Mode --------
    n      = varargin{1};
    T_in   = varargin{2};
    p_in   = varargin{3};
    Pr     = varargin{4};

    p_out    = p_in / Pr;
    pbar_out = p_out / 1e5;

    % Inlet enthalpy (extensive)
    H_in = HGSprop(species, n, T_in, p_in/1e5, 'H'); 

    % Isenthalpic throttling
    H_out = H_in;

    % Solve for outlet temperature --> ALWAYS SAME AS INLET WITH HGS
    f = @(T_out) HGSprop(species, n, T_out, pbar_out, 'H') - H_out;
    T_out = fzero(f, T_in);

    % Outlet properties
    S_out   = HGSprop(species, n, T_out, pbar_out, 'S');
    Rg      = HGSprop(species, n, T_out, pbar_out, 'Rg'); 
    rho_out = p_out / (Rg*1e3*T_out);  % [kg/m^3], ideal-gas EOS
    n_out   = n;  % unchanged
else
    error('species must be a string (NFP) or cell array (HGS)');
end

end
