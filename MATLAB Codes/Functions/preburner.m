function [species,Tp,np,OF,m_dot,H,S,Rg,rho,Mm] = preburner(species,mH2_dot,mO2_dot,TH2,TO2,P_H2,P_O2,P0,eta)
% C_CHAMBER  Adiabatic equilibrium combustion chamber model (LOX/LH2).
%
% This function computes the equilibrium combustion state inside a rocket
% combustion chamber using:
%   - NFP for real-fluid inlet enthalpies at the actual inlet pressures
%   - HGS for high-temperature chemical equilibrium at chamber pressure
%
% The model assumes:
%   - Steady-state operation
%   - Adiabatic combustion chamber (no heat losses)
%   - Complete mixing prior to reaction
%   - Chemical equilibrium at chamber pressure P0
%   - Reactants enter as pure H2 and O2 at known inlet pressures and temperatures
%
% -------------------------------------------------------------------------
% INPUTS:
%   mH2_dot  [kg/s]  Hydrogen mass flow rate at chamber inlet
%   mO2_dot  [kg/s]  Oxygen mass flow rate at chamber inlet
%   TH2      [K]     Hydrogen inlet temperature
%   TO2      [K]     Oxygen inlet temperature
%   P_H2     [Pa]    Hydrogen inlet pressure
%   P_O2     [Pa]    Oxygen inlet pressure
%   P0       [Pa]    Combustion chamber pressure
%   species  {cell}  Species list for equilibrium calculation
%
% OUTPUTS:
%   Tp   [K]         Equilibrium flame temperature at chamber pressure
%   np   [mol]       Equilibrium molar amounts of all species
%   OF   [-]         Oxidizer-to-fuel mass ratio
%   m_dot[kg/s]      Total mass flow rate
%   H    [kJ]        Total enthalpy of equilibrium mixture (extensive)
%   S    [kJ/K]      Total entropy of equilibrium mixture (extensive)
%   Rg   [kJ/(kg·K)] Mixture gas constant
%   rho  [kg/m^3]    Mixture density (ideal-gas EOS)
%   Mm   [g/mol]     Average molecular weight of equilibrium mixture
%
% -------------------------------------------------------------------------
% STEP 0 — Oxidizer-to-fuel ratio (diagnostic)
OF = mO2_dot / mH2_dot;

% -------------------------------------------------------------------------
% STEP 1 — Pressure conversion and mass conservation
P0_bar   = P0   / 1e5;
P_H2_bar = P_H2 / 1e5;
P_O2_bar = P_O2 / 1e5;
m_dot    = mH2_dot + mO2_dot;

% -------------------------------------------------------------------------
% STEP 2 — Initial molar amounts of reactants
% Reactants are introduced as pure H2 and O2; products are initially zero.
np = [ mH2_dot / NFP('H2','MM'), ...
       mO2_dot / NFP('O2','MM'), ...
       0, 0, 0, 0 ];

% -------------------------------------------------------------------------
% STEP 3 — Inlet enthalpy conversion to HGS reference state
% Real-fluid inlet enthalpies (NFP) are mapped onto the HGS reference
% by correcting the 400 K HGS enthalpy with the actual inlet temperature.

% Oxygen inlet enthalpy (HGS reference)
deltah_O2 = (NFP('O2','h_pT',P_O2_bar,400) - NFP('O2','h_pt',P_O2_bar,TO2) ) * NFP('O2','MM');
hO2 = HGSsingle('O2','h',400) - deltah_O2;

% Hydrogen inlet enthalpy (HGS reference)
deltah_H2 = (NFP('H2','h_pT',P_H2_bar,400) - NFP('H2','h_pt',P_H2_bar,TH2) ) * NFP('H2','MM');
hH2 = HGSsingle('H2','h',400) - deltah_H2;

% -------------------------------------------------------------------------
% STEP 4 — Total inlet enthalpy flow
% This is the conserved quantity used in the equilibrium calculation.
Hin = np(2)*hO2 + np(1)*hH2;

%% STEP 5 — Combustion efficiency model (chemical heat reduction)
% The combustion efficiency is modeled as a reduction of the chemical heat
% released, evaluated at a fixed reference state (Tref, P0).
Tref = 400;  % Reference temperature consistent with HGS

% Reference enthalpy of reactants and equilibrium products
H_react_ref = HGSprop(species, np, Tref, P0_bar, 'H');
[~,n_eq_ref,~] = HGSeq(species, np, Tref, P0_bar);
H_prod_ref  = HGSprop(species, n_eq_ref, Tref, P0_bar, 'H');

% Chemical heat available and effective enthalpy for equilibrium
Q_chem  = H_react_ref - H_prod_ref;
Q_loss  = (1 - eta) * Q_chem;
Hin_real = Hin - Q_loss;

% -------------------------------------------------------------------------
% STEP 5 — Chemical equilibrium at chamber pressure
% The equilibrium temperature and composition satisfy:
%   H_products(Tp, P0) = Hin
[Tp, species, np, flag] = HGStp(species, np, 'H', Hin_real, P0_bar);

if flag ~= 1
    error('HGStp did not converge.');
end

% -------------------------------------------------------------------------
% STEP 6 — Thermodynamic properties of equilibrium mixture
[Mm, H, S, Rg] = HGSprop(species, np, Tp, P0_bar, 'Mm','H','S','Rg');

% -------------------------------------------------------------------------
% STEP 7 — Mixture density (ideal-gas EOS)
rho = P0 / (Rg * 1e3 * Tp);
end