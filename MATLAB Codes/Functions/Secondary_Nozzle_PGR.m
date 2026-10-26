function [Ae,Pe,Te,rhoe] = Secondary_Nozzle_PGR(species,Ve,epsilon,Ma,de,Fe,m_dot,pa)
% Secondary_Nozzle_PGR
%
% This function computes the exit conditions of a secondary nozzle using
% the Perfect Gas Rocket (PGR) equations, derived from the analysis of a
% steady, one-dimensional, isentropic (adiabatic and reversible) expansion.
%
% The gas is assumed to behave as a perfect gas, with constant specific heats
% and constant gamma. Viscous effects, heat transfer and chemical reactions
% are neglected.
%
% -------------------------------------------------------------------------
% INPUTS:
% species : string      | Name of the working fluid (used only to obtain the molecular mass via NFP)
% Ve : double [m/s]     |Exit velocity of the flow
% epsilon : double [-]  |Nozzle expansion ratio Ae/At
% Ma : double [-]       |Exit Mach number
% de : double [m]       |Nozzle exit diameter
% Fe : double [N]       |Thrust produced by the nozzle
% m_dot : double [kg/s] |Mass flow rate through the nozzle
% pa : double [Pa]      |Ambient pressure
%
% -------------------------------------------------------------------------
% OUTPUTS:
% Ae : double [m^2]     |Nozzle exit area
% Pe : double [Pa]      |Nozzle exit static pressure
% Te : double [K]       |Nozzle exit static temperature
%
% -------------------------------------------------------------------------

%% Gas properties (perfect gas assumption)
Mm = NFP(species,'MM');     % Molecular mass [kg/mol]
R0 = 8.314;                % Universal gas constant [J/(mol·K)]
R  = R0/Mm;                % Specific gas constant [J/(kg·K)]

%% Evaluation of gamma from the isentropic area–Mach relation
% Gamma is obtained by inverting the isentropic area ratio relation
% Ae/At = f(Ma, gamma)
f = @(gamma) iso_a_ratio(Ma,gamma) - epsilon;
gamma = fzero(f,1.4);

%% Exit area computation
Ae = de^2*pi/4;            % Exit area [m^2]

%% Exit pressure from thrust equation
% Thrust equation:
% Fe = m_dot*Ve + (Pe - pa)*Ae
Pe = (Fe - m_dot*Ve)/Ae + pa;   % Exit pressure [Pa]

%% Exit temperature from Mach number definition
% Ma = Ve / sqrt(gamma*R*Te)
Te = Ve^2/(Ma^2*gamma*R);       % Exit temperature [K]

%% Exit density from ideal gas
rhoe = Pe / (R * Te);

end
