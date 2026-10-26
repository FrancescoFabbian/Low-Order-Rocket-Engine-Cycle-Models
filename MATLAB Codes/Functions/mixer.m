function out = mixer(in1, in2, p3)
% MIXERUNIFIED  Adiabatic steady-state mixer (NFP or HGS automatically).
%
% This function models a mixing junction where two inlet streams merge
% and exit at a prescribed outlet pressure p3.
%
% The thermodynamic model is selected automatically:
%   - NFP: single-species, real-fluid mixing
%   - HGS: multi-species or composition-changing mixing (ideal gas)
%
% -------------------------------------------------------------------------
% INPUTS:
%   in1, in2 : structs with fields
%       .species   : string (NFP) or cell array (HGS)
%       .mdot      : mass flow rate [kg/s]
%       .p         : pressure [Pa]
%       .T         : temperature [K]
%       .n         : molar flow vector [mol/s] (OPTIONAL → triggers HGS)
%
%   p3       : outlet pressure [Pa]
%
% OUTPUT (struct):
%   out.species : outlet species list
%   out.mdot    : outlet mass flow rate [kg/s]
%   out.T       : outlet temperature [K]
%   out.h       : outlet specific enthalpy [kJ/kg]
%   out.rho     : outlet density [kg/m^3]
%
%   (HGS-only fields)
%   out.n       : outlet molar flow vector [mol/s]
%   out.H       : outlet total enthalpy [kJ]
%   out.S       : outlet total entropy [kJ/K]
% -------------------------------------------------------------------------

%% ===================== MODEL SELECTION =====================
useHGS = ...
    isfield(in1,'n') || isfield(in2,'n') || ...
    ~isequal(in1.species, in2.species);

p3_bar = p3 / 1e5;


%% ======================= NFP MIXER ========================

% This function models a *non-reactive*, *adiabatic*, *steady-flow* mixing chamber 
% for a real fluid (liquid or supercritical), using the NFP property database.
%
% The control volume includes both:
%   - the mixing of the two streams
%   - the pressure drop from p1=p2 to the imposed outlet pressure p3
%
% The process is assumed to have:
%   - No shaft work       (Ẇ_sh = 0)
%   - No heat transfer     (Q̇ = 0)
%   - Negligible kinetic/potential energy changes
%   - Single-species flow  (e.g., pure H2)
%
% -------------------------------------------------------------------------
% ASSUMPTIONS AND PHYSICAL MODEL:
%   • Adiabatic mixing:
%         m1*h1 + m2*h2 = m3*h3
%
%   • The outlet pressure p3 is known. 
%     This represents a pressure loss due to geometry, friction, or downstream boundary.
%
%   • Because species are identical, no mixing enthalpy or chemical effects appear.
%
%   • Real-fluid behavior (no ideal-gas assumption). 
%
% -------------------------------------------------------------------------
if ~useHGS
    % Same species, real-fluid, no composition change

    species = in1.species;

    % ---------------------------------------------------------------------
    % STEP 1 — Mass conservation
    % The total mass flow rate is the sum of the incoming streams.
    out.mdot = in1.mdot + in2.mdot;

    % Inlet pressures (bar)
    p1_bar = in1.p / 1e5;
    p2_bar = in2.p / 1e5;

    % ---------------------------------------------------------------------
    % STEP 2 — Compute inlet specific enthalpies using NFP
    % h_pt(p,T) returns specific enthalpy in [kJ/kg]
    h1 = NFP(species,'h_pt',p1_bar,in1.T);   % [kJ/kg]
    h2 = NFP(species,'h_pt',p2_bar,in2.T);   % [kJ/kg]

    % ---------------------------------------------------------------------
    % STEP 3 — Energy equation for steady adiabatic mixing
    % For an adiabatic steady-flow CV with no shaft work and negligible KE/PE:
    %
    %     ṁ1*h1 + ṁ2*h2 = ṁ3*h3
    %
    % Solve for h3 (specific enthalpy at outlet).
    out.h = (in1.mdot*h1 + in2.mdot*h2) / out.mdot;

    % ---------------------------------------------------------------------
    % STEP 4 — Compute outlet temperature from (h3, p3)
    % Use the real-fluid inversion T = T(h, p).
    % t_hp(h,p) returns temperature [K] corresponding to specific enthalpy h3 at pressure p3.
    out.T   = NFP(species,'t_hp',out.h,p3_bar);

    % ---------------------------------------------------------------------
    % STEP 5 — Compute outlet density
    % ρ = ρ(p,T) from real-fluid EOS (not ideal gas).
    out.rho = NFP(species,'r_pt',p3_bar,out.T);

    out.species = species;

    return
end

%% ======================= HGS MIXER ========================

% -------- Pressures --------
p1_bar = in1.p / 1e5;
p2_bar = in2.p / 1e5;

% -------- Mass conservation --------
out.mdot = in1.mdot + in2.mdot;

%% -------- Convert both streams to molar form --------

% --- Stream 1 ---
if isfield(in1,'n')
    species1 = in1.species;
    n1 = in1.n;
else
    species1 = {in1.species};
    Mm1 = NFP(in1.species,'MM');        % [kg/mol]
    n1 = in1.mdot / Mm1;                % [mol/s]
end

% --- Stream 2 ---
if isfield(in2,'n')
    species2 = in2.species;
    n2 = in2.n;
else
    species2 = {in2.species};
    Mm2 = NFP(in2.species,'MM');        % [kg/mol]
    n2 = in2.mdot / Mm2;                % [mol/s]
end

%% -------- Merge species and molar flows --------
species_all = unique([species1, species2],'stable');
n_tot = zeros(1,numel(species_all));

[~,i1] = ismember(species1,species_all);
n_tot(i1) = n_tot(i1) + n1;

[~,i2] = ismember(species2,species_all);
n_tot(i2) = n_tot(i2) + n2;

out.species = species_all;
out.n       = n_tot;

%% -------- Energy balance (HGS reference) --------

% Stream 1 enthalpy
if isfield(in1,'n')
    H1 = HGSprop(species1,n1,in1.T,p1_bar,'H');   % [kJ]
else
    % Convert NFP enthalpy to HGS reference (400 K)
    delta_h1 = ( ...
        NFP(in1.species,'h_pt',p1_bar,400) - ...
        NFP(in1.species,'h_pt',p1_bar,in1.T) ) * Mm1;
    h1 = HGSsingle(in1.species,'h',400);           % [kJ/mol]
    H1 = n1 * h1 - delta_h1;                       % [kJ]
end

% Stream 2 enthalpy
if isfield(in2,'n')
    H2 = HGSprop(species2,n2,in2.T,p2_bar,'H');   % [kJ]
else
    delta_h2 = ( ...
        NFP(in2.species,'h_pt',p2_bar,400) - ...
        NFP(in2.species,'h_pt',p2_bar,in2.T) ) * Mm2;
    h2 = HGSsingle(in2.species,'h',400);           % [kJ/mol]
    H2 = n2 * h2 - delta_h2;                       % [kJ]
end

out.H = H1 + H2;

%% -------- Solve for outlet temperature --------
fT = @(T) HGSprop(out.species,out.n,T,p3_bar,'H') - out.H;

% Robust initial guess
if in1.mdot >= in2.mdot
    T_guess = in1.T;
else
    T_guess = in2.T;
end

out.T = fzero(fT,T_guess);

%% -------- Outlet properties --------
out.S = HGSprop(out.species,out.n,out.T,p3_bar,'S');  % [kJ/K]

Mm_mix = HGSprop(out.species,out.n,out.T,p3_bar,'Mm');  % [g/mol]
M_mix  = sum(out.n)*Mm_mix/1000;                        % [kg]

out.h = out.H / M_mix;

Rg = HGSprop(out.species,out.n,out.T,p3_bar,'Rg');     % [kJ/(kg·K)]
out.rho = p3 / (Rg*1e3*out.T);                          % [kg/m^3]

end
