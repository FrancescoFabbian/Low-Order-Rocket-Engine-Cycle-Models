function [species,Tp,n_tot,OF,m_dot,H,S,Rg,rho,Mm] =C_Chamber_Main(mH2_dot,mO2_dot,m1HGS_dot,m2HGS_dot,T_H2,T_O2,T1_HGS,T2_HGS,P_H2,P_O2,P1_HGS,P2_HGS,P0,n1_HGS,n2_HGS,eta,species_H2,species_O2,species1_HGS,species2_HGS)
% C_CHAMBER_MAIN  Equilibrium combustion chamber model with efficiency.
%
% Computes the equilibrium temperature, composition, and thermodynamic
% properties of a rocket combustion chamber fed by cryogenic reactants
% (H2, O2) and hot-gas streams.
%
% Thermodynamic models:
%   - NFP: real-fluid properties of cryogenic inlet streams
%   - HGS: equilibrium chemistry and high-temperature gas properties
%
% Main assumptions:
%   - Steady-state operation
%   - Complete mixing before reaction
%   - Chemical equilibrium at chamber pressure P0
%   - Combustion efficiency modeled as a reduction of chemical heat release
%
% -------------------------------------------------------------------------
% INPUTS:
%   mH2_dot, mO2_dot     [kg/s]   Cryogenic reactant mass flow rates
%   m1HGS_dot, m2HGS_dot [kg/s]   Hot-gas stream mass flow rates
%
%   T_H2, T_O2           [K]      Cryogenic inlet temperatures
%   T1_HGS, T2_HGS       [K]      Hot-gas inlet temperatures
%
%   P_H2, P_O2           [Pa]     Cryogenic inlet pressures
%   P1_HGS, P2_HGS       [Pa]     Hot-gas inlet pressures
%   P0                  [Pa]     Chamber pressure
%
%   n1_HGS, n2_HGS       [mol/s]  Molar composition vectors of hot-gas streams
%   eta                 [-]      Combustion efficiency (0 < eta ≤ 1)
%
%   species_*            {cell}   Species lists of each inlet stream
%
% -------------------------------------------------------------------------
% OUTPUTS:
%   Tp     [K]        Equilibrium chamber temperature
%   n_tot  [mol/s]    Equilibrium molar flow rates of all species
%   OF     [-]        Elemental oxidizer-to-fuel ratio (O/H)
%   m_dot  [kg/s]     Total mass flow rate
%   H      [kJ]       Total mixture enthalpy
%   S      [kJ/K]     Total mixture entropy
%   Rg     [kJ/(kg·K)]Mixture gas constant
%   rho    [kg/m^3]   Mixture density (ideal-gas EOS)
%   Mm     [g/mol]    Mean molecular weight
% -------------------------------------------------------------------------

%% STEP 1 — Pressure conversion and total mass flow
% Convert pressures to bar for HGS/NFP consistency and compute total mass flow.
P0_bar      = P0/1e5;
P_H2_bar    = P_H2/1e5;
P_O2_bar    = P_O2/1e5;
P1_HGS_bar  = P1_HGS/1e5;
P2_HGS_bar  = P2_HGS/1e5;

m_dot = mH2_dot + mO2_dot + m1HGS_dot + m2HGS_dot;

%% STEP 2 — Cryogenic reactant molar flow rates
% Convert cryogenic mass flow rates into molar flow rates.
n_H2 = mH2_dot / NFP('H2','MM');   % [mol/s]
n_O2 = mO2_dot / NFP('O2','MM');   % [mol/s]

%% STEP 3 — Assembly of inlet mixture composition
% Merge all inlet species lists and construct the total inlet molar vector.
species_all = unique([species_H2, species_O2, species1_HGS, species2_HGS], 'stable');
n_in = zeros(1, numel(species_all));

[~,i] = ismember(species_H2, species_all);   n_in(i) = n_in(i) + n_H2;
[~,i] = ismember(species_O2, species_all);   n_in(i) = n_in(i) + n_O2;
[~,i] = ismember(species1_HGS, species_all); n_in(i) = n_in(i) + n1_HGS;
[~,i] = ismember(species2_HGS, species_all); n_in(i) = n_in(i) + n2_HGS;

%% STEP 4 — Inlet enthalpy evaluation (HGS reference at 400 K)
% Cryogenic enthalpies are converted from NFP to the HGS reference system.
% Hot-gas stream enthalpies are directly evaluated with HGS.
deltah_O2 = ( NFP('O2','h_pT',P_O2_bar,400) - NFP('O2','h_pt',P_O2_bar,T_O2) ) ...
             * NFP('O2','MM');
hO2 = HGSsingle('O2','h',400) - deltah_O2;

deltah_H2 = ( NFP('H2','h_pT',P_H2_bar,400) - NFP('H2','h_pt',P_H2_bar,T_H2) ) ...
             * NFP('H2','MM');
hH2 = HGSsingle('H2','h',400) - deltah_H2;

H1_HGS = HGSprop(species1_HGS, n1_HGS, T1_HGS, P1_HGS_bar,'H');
H2_HGS = HGSprop(species2_HGS, n2_HGS, T2_HGS, P2_HGS_bar,'H');

% Total inlet enthalpy rate
Hin = n_O2*hO2 + n_H2*hH2 + H1_HGS + H2_HGS;

%% STEP 5 — Combustion efficiency model (chemical heat reduction)
% The combustion efficiency is modeled as a reduction of the chemical heat
% released, evaluated at a fixed reference state (Tref, P0).
Tref = 400;  % Reference temperature consistent with HGS

% Reference enthalpy of reactants and equilibrium products
H_react_ref = HGSprop(species_all, n_in, Tref, P0_bar, 'H');
[~,n_eq_ref,~] = HGSeq(species_all, n_in, Tref, P0_bar);
H_prod_ref  = HGSprop(species_all, n_eq_ref, Tref, P0_bar, 'H');

% Chemical heat available and effective enthalpy for equilibrium
Q_chem  = H_react_ref - H_prod_ref;
Q_loss  = (1 - eta) * Q_chem;
Hin_real = Hin - Q_loss;

%% STEP 6 — Equilibrium solution at chamber pressure
% Final equilibrium state obtained with reduced available enthalpy.
[Tp,~,n_tot,flag] = HGStp(species_all, n_in, 'H', Hin_real, P0_bar);
if flag ~= 1
    error('HGStp did not converge.');
end

%% STEP 7 — Thermodynamic properties of equilibrium mixture
[Mm,H,S,Rg] = HGSprop(species_all, n_tot, Tp, P0_bar, 'Mm','H','S','Rg');

%% STEP 8 — Mixture density (ideal-gas EOS)
rho = P0 / (Rg * 1e3 * Tp);

%% STEP 9 — Elemental oxidizer-to-fuel ratio (O/H)
% Computed from atomic balances on the equilibrium mixture.
M_H = 1.00794e-3;   % [kg/mol]
M_O = 15.999e-3;    % [kg/mol]

n_H = 0; n_O = 0;
for i = 1:numel(species_all)
    sp = species_all{i};
    ni = n_tot(i);
    switch sp
        case 'H2',  n_H = n_H + 2*ni;
        case 'O2',  n_O = n_O + 2*ni;
        case 'H2O', n_H = n_H + 2*ni; n_O = n_O + ni;
        case 'H',   n_H = n_H + ni;
        case 'O',   n_O = n_O + ni;
        case 'OH',  n_H = n_H + ni; n_O = n_O + ni;
    end
end

OF = (n_O*M_O) / (n_H*M_H);

species = species_all;

end
