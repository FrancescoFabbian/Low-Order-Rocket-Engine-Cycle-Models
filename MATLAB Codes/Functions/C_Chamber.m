function [Tp,np,OF,m_dot,H,S,Rg,rho,Mm] = C_Chamber(mH2_dot,mO2_dot,TH2,TO2,P_H2,P_O2,P0,species)
% C_CHAMBER  Computes the equilibrium combustion state in a rocket engine chamber.
%
% This function evaluates the adiabatic equilibrium temperature, species composition,
% and thermodynamic properties at the chamber pressure using:
%   - NFP (for cryogenic inlet enthalpies at arbitrary temperatures)
%   - HGS  (for high-temperature equilibrium in the chamber)
%
% The model assumes:
%   - Adiabatic combustion chamber (no heat losses)
%   - Complete mixing before reaction
%   - Chemical equilibrium at chamber pressure P0
%   - Reactants enter as pure O2 and H2 at arbitrary temperatures
%
% -------------------------------------------------------------------------
% INPUTS:
%   mH2_dot  [kg/s]   Mass flow rate of hydrogen entering the chamber
%   mO2_dot  [kg/s]   Mass flow rate of oxygen entering the chamber
%   TH2      [K]      Temperature of the hydrogen stream at chamber inlet
%   TO2      [K]      Temperature of the oxygen stream at chamber inlet
%   P0       [Pa]    Chamber pressure
%
% OUTPUTS:
%   Tp   [K]        Equilibrium adiabatic flame temperature in the chamber
%   np   [mol]      Equilibrium molar amounts of all species in 'species'
%   OF   [-]        Oxidizer-to-fuel mass ratio mO2_dot / mH2_dot
%   H    [kJ]       Total enthalpy of the equilibrium mixture (extensive)
%   S    [kJ/K]     Total entropy of the equilibrium mixture (extensive)
%   Rg   [kJ/(kg·K)]   Gas constant of the equilibrium mixture
%   rho  [kg/m^3]   Mixture density at (Tp, P0) using ideal-gas EOS
%   Mm   [g/mol]    Average molecular weight of the equilibrium mixture
%
% -------------------------------------------------------------------------
% STEP 0 — Compute oxidizer-to-fuel ratio (sanity check)
% OF is used only for diagnostic purposes (not for calculations).
OF = mO2_dot / mH2_dot;
%
% STEP 1 - Pass the pressure from Pa --> bar (needed for HGS and NFP) and
% compute the exiting mass flow rate from the mass conservation
P0_bar = P0/1e5;
P_H2_bar = P_H2/1e5;
P_O2_bar = P_O2/1e5;
m_dot = mH2_dot + mO2_dot;
%
% STEP 2 — Define species list and initial molar amounts
% Initial reactants: H2 and O2 in arbitrary mass flow rates.
% Product species included:
%   H2, O2 → reactants
%   H2O, H, O, OH → typical high-T dissociation products of LOX/LH2.
%
%species = {'H2','O2','H2O','H','O','OH'};
%
% Convert mass flow rates [kg/s] to molar flow rates [mol/s] using NFP molar masses [kg/mol].
np = [ mH2_dot / NFP('H2','MM'), ...   % mol/s of H2
       mO2_dot / NFP('O2','MM'), ...   % mol/s of O2
       0, 0, 0, 0 ];                   % initially no products present
%
% -------------------------------------------------------------------------
% STEP 3 — Convert the inlet enthalpies to the HGS reference system
%
% We must convert the actual inlet enthalpies from NFP (real-fluid model)
% into equivalent HGS enthalpies at 400 K, so that:
%
%     h_in(HGS) = h_HGS(400K) – Δh
%
% where Δh compensates for the actual inlet temperature.
%
% Oxygen inlet enthalpy (converted to HGS scale), [kJ/mol]
deltah_O2 = ( NFP('O2','h_pT',P_O2_bar,400) - NFP('O2','h_pt',P_O2_bar,TO2) ) * NFP('O2','MM');
hO2 = HGSsingle('O2','h',400) - deltah_O2;
%
% Hydrogen inlet enthalpy (converted to HGS scale), [kJ/mol]
deltah_H2 = ( NFP('H2','h_pT',P_H2_bar,400) - NFP('H2','h_pt',P_H2_bar,TH2) ) * NFP('H2','MM');
hH2 = HGSsingle('H2','h',400) - deltah_H2;
%
% -------------------------------------------------------------------------
% STEP 4 — Compute total inlet enthalpy flow (needed for HGStp)
%
Hin = np(2)*hO2 + np(1)*hH2;   % total inlet enthalpy flow [kJ/s equivalent]
%
% -------------------------------------------------------------------------
% STEP 5 — Call HGStp to compute equilibrium temperature and composition
% taking into account the dissociation
%
% HGStp(species, n0, 'H', Hin, P0) solves:
%   H_products(Tp, P0) = Hin
% using an equilibrium solver (secant + Gibbs minimization).
%
[Tp, ~, np, flag] = HGStp(species, np, 'H', Hin, P0_bar);
%
% Ensure convergence: flag = 1 means successful solution.
if flag ~= 1
    error('HGStp did not converge: flag must be 1.');
end
%
% -------------------------------------------------------------------------
% STEP 6 — Evaluate thermodynamic properties of equilibrium mixture
%
% HGSprop returns total mixture properties:
%   Mm [g/mol]   molecular weight
%   H  [kJ]      total enthalpy
%   S  [kJ/K]    total entropy
%   Rg [kJ/(kg·K)] mixture gas constant
%
[Mm, H, S, Rg] = HGSprop(species, np, Tp, P0, 'Mm','H','S','Rg');
%
% -------------------------------------------------------------------------
% STEP 7 — Compute mixture density using ideal-gas EOS
%
rho = P0 / (Rg * 1e3 * Tp);   % [kg/m^3]
%
end
