%% COMPRESSIBLE CASE
function[T_out,p_out,rho_out,h_out,s_out] = pumpNFP(species,W,eta,mdot,p_in,T_in)
% COMPRESSIBLE PUMP MODEL USING REAL-FLUID PROPERTIES (NFP)
%
% This formulation accounts for:
%   - Density variation with pressure
%   - Real-fluid thermodynamics
%   - Isentropic reference process
%   - Finite pump efficiency
%
% The outlet pressure is obtained by solving the integral form
% of the steady-flow energy equation for a compressible fluid:
%
%   Ẇ / ṁ = (1/η) ∫ v(p,s) dp
%
% where:
%   v = 1 / ρ(p,s)
%
% This is the correct formulation for:
%   - Cryogenic pumps
%   - High pressure rise
%   - Near-critical or supercritical fluids
%
% -------------------------------------------------------------------------
% INPUTS:
%   species : working fluid identifier (NFP)
%   W       : shaft power input [W]
%   eta     : pump isentropic efficiency [-]
%   mdot    : mass flow rate [kg/s]
%   p_in    : inlet pressure [Pa]
%   T_in    : inlet temperature [K]
%
% OUTPUTS:
%   T_out   : outlet temperature [K]
%   p_out   : outlet pressure [Pa]
%   rho_out : outlet density [kg/m^3]
%   h_out   : outlet specific enthalpy [kJ/kg]
%   s_out   : outlet specific entropy [kJ/(kg·K)]
% -------------------------------------------------------------------------

% Convert inlet pressure from Pa to bar (required by NFP)
pbar_in = p_in/1e5;

% Checking NFP validity
[isValid, ~] = checkNFPRange(species, p_in, T_in);

if isValid

    % ---------------------------------------------------------------------
    % Inlet thermodynamic state
    % ---------------------------------------------------------------------

    h_in=NFP(species,'h_pt',pbar_in,T_in); %[kJ/Kg]
    s_in=NFP(species,'s_pt',pbar_in,T_in); %[kJ/kg K]

    % ---------------------------------------------------------------------
    % Pressure-rise equation for compressible flow
    % ---------------------------------------------------------------------
    % The integral represents:
    %
    %   ∫ v(p,s_in) dp
    %
    % evaluated along an isentropic path (s = s_in).
    % Pump efficiency scales the ideal isentropic work.

    f = @(p_out) ...
        (1/eta) * integral( ...
            @(p) integrand(p, species, s_in), ...
            p_in, p_out, 'ArrayValued', true) ...
        - W/mdot;

    % ---------------------------------------------------------------------
    % Initial pressure guess (incompressible approximation)
    % ---------------------------------------------------------------------
    rho_in = NFP(species,'r_pt',pbar_in,T_in);      % [kg/m^3]
    delta_p = eta * W* rho_in / mdot;               % W in Watts -->  Pa
    p_guess = p_in + delta_p;

    % ---------------------------------------------------------------------
    % Solve for outlet pressure
    % ---------------------------------------------------------------------
    p_out = fzero(f, p_guess);
    pbar_out = p_out/1e5;

    % ---------------------------------------------------------------------
    % Isentropic reference outlet state
    % ---------------------------------------------------------------------
    s_out_s = s_in;
    T_out_s=NFP(species,'t_ps',pbar_out,s_out_s);   %[K]
    h_out_s=NFP(species,'h_pt',pbar_out,T_out_s);   %[kJ/Kg]

    % ---------------------------------------------------------------------
    % Apply pump efficiency (real outlet enthalpy)
    % ---------------------------------------------------------------------
    h_out=h_in+(h_out_s-h_in)/eta;                  % Pump formula

    % ---------------------------------------------------------------------
    % Real outlet state
    % ---------------------------------------------------------------------
    T_out=NFP(species,'t_hp',h_out,pbar_out);%[K]
    s_out=NFP(species,'s_pt',pbar_out,T_out);%[kJ/kg K]
    rho_out=NFP(species,'r_pt',pbar_out,T_out);

    else
    disp('We cannot use NFP');
end

end


% -------------------------------------------------------------------------
% (KEPT FOR REFERENCE — NOT USED)
% -------------------------------------------------------------------------

% % INCOMPRESSIBLE CASE
% function[T_out,p_out,rho_out,h_out,s_out] = pumpNFP(species,W,eta,mdot,p_in,T_in)
% 
% pbar_in = p_in/1e5;                         % conversion from Pa to bar
% % % are we in the temperature and pressure range?
% % %(Maybe everithing here should go inside a function)
% Tmin_NFP = 14;      % Kelvin
% Tmax_NFP = 1000;    % Kelvin
% pmin_NFP = 0.01;    % bar
% pmax_NFP = 1000;    % bar
% 
% if (T_in > Tmin_NFP) && (T_in < Tmax_NFP) && ...
%    (pbar_in > pmin_NFP) && (pbar_in < pmax_NFP) 
% 
%     % input pressure in Pa, input power in Watt, Temperature in Kelvin
%     %pbar_in = p_in/1e5;                         % conversion from Pa to bar
%     rho = NFP(species,'r_pt',pbar_in,T_in);     % kg/m^3
%     delta_p = eta*W*rho/mdot;                   % W in Watts -->  Pa
%     p_out = p_in + delta_p;                     % Pa
%     pbar_out = p_out/1e5;                       % bar
% 
%     h_in=NFP(species,'h_pt',pbar_in,T_in); %[kJ/Kg]
%     s_in=NFP(species,'s_pt',pbar_in,T_in); %[kJ/kg K]
%     s_out_s = s_in;
%     T_out_s=NFP(species,'t_ps',pbar_out,s_out_s); %[K]
%     h_out_s=NFP(species,'h_pt',pbar_out,T_out_s); %[kJ/Kg]
%     h_out=h_in+(h_out_s-h_in)/eta;                 % Pump formula
% 
%     T_out=NFP(species,'t_hp',h_out,pbar_out);%[K]
%     s_out=NFP(species,'s_pt',pbar_out,T_out);%[kJ/kg K]
%     rho_out = rho;
%     else
%     disp('We cannot use NFP');
% end
% end