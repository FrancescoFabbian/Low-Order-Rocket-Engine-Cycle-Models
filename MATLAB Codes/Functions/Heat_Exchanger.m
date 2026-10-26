function [p_out,h_out,s_out,rho_out,Q_eff] = ...
    Heat_Exchanger(species,p_in,T_in,T_out,mdot,Pr,varargin)
% Heat_Exchanger
%
% Unified heat exchanger function for single-species and multi-species flows.
% Computes outlet thermodynamic properties and heat transfer based on inlet
% and outlet temperatures, mass flow rate, and pressure ratio.
%
% Supports:
%   - Single species       → NFP real-fluid properties
%   - Multiple species     → HGS mixture properties (ideal-gas approximation for density)
%
% INPUTS:
%   species : string (e.g. 'H2') or cell array of strings {'H2','O2',...}
%   p_in    : inlet pressure [Pa]
%   T_in    : inlet temperature [K]
%   T_out   : outlet temperature [K]
%   mdot    : mass flow rate [kg/s]
%   Pr      : pressure ratio p_in / p_out [-]
%
% OPTIONAL INPUTS (only for mixtures):
%   n       : molar amounts vector [mol]
%   V_in    : inlet velocity [m/s] (default: 0)
%   V_out   : outlet velocity [m/s] (default: 0)
%
% OUTPUTS:
%   p_out   : outlet pressure [Pa]
%   h_out   : outlet specific enthalpy [kJ/kg]
%   s_out   : outlet specific entropy [kJ/(kg·K)]
%   rho_out : outlet density [kg/m^3] 
%             (single-species: NFP; multi-species: ideal-gas mixture)
%   Q_eff   : effective heat transfer rate [W]
%
% NOTES:
%   - For multi-species flows, mixture density is computed using the ideal
%     gas law with HGS mixture molar mass.
%   - Energy balance accounts for both enthalpy change and kinetic energy.
%   - Ensure molar amounts 'n' are provided for multi-species cases.
% -----------------------------
% Defaults
% -----------------------------
V_in  = 0;
V_out = 0;

if nargin >= 7
    if numel(varargin) >= 1
        n = varargin{1};
    end
    if numel(varargin) >= 2
        V_in = varargin{2};
    end
    if numel(varargin) >= 3
        V_out = varargin{3};
    end
end

% Pressure loss
p_out     = p_in / Pr;
pbar_in  = p_in  / 1e5;
pbar_out = p_out / 1e5;

% -----------------------------
% CASE 1 — SINGLE SPECIES → NFP
% -----------------------------
if ischar(species) || (iscell(species) && numel(species) == 1)

    if iscell(species)
        species = species{1};
    end

    % Inlet state
    h_in = NFP(species,'h_pt',pbar_in,T_in);   % kJ/kg

    % Outlet state
    h_out  = NFP(species,'h_pt',pbar_out,T_out);  % kJ/kg
    s_out  = NFP(species,'s_pt',pbar_out,T_out);  % kJ/(kg K)
    rho_out= NFP(species,'r_pt',pbar_out,T_out);  % kg/m^3

    % Energy balance
    Q_eff = mdot*(h_out - h_in)*1000 ...
          + mdot*(V_out^2 - V_in^2)/2;

% -----------------------------
% CASE 2 — MULTI-SPECIES → HGS
% -----------------------------
else
    if ~exist('n','var')
        error('For multiple species, molar amounts vector n must be provided.');
    end

    % Batch enthalpies
    H_in  = HGSprop(species,n,T_in, pbar_in, 'H');   % kJ
    H_out = HGSprop(species,n,T_out,pbar_out,'H');   % kJ
    S_out = HGSprop(species,n,T_out,pbar_out,'S');   % kJ/K

    % Mixture mass
    Mm = HGSprop(species,n,T_out,pbar_out,'Mm');     % g/mol
    M  = sum(n)*Mm/1000;                              % kg

    % Specific properties
    h_out  = H_out / M;                               % kJ/kg
    s_out  = S_out / M;                               % kJ/(kg K)

    % compute mixture density
    R_universal = 8.314462618;     % J/(mol·K)
    Rg = R_universal / (Mm/1000);  % [J/(kg·K)]
    rho_out = p_out / (Rg * T_out); % [Pa / (J/kg·K) = kg/m^3]

    % Energy balance
    Q_eff = 1000*(H_out - H_in)*(mdot/M) ...
          + mdot*(V_out^2 - V_in^2)/2;
end

end
