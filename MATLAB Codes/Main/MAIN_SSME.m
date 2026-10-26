clear; close all; clc;

%% storage arrays - gives out a table in the end and easier to plot
Position = strings(0,1);
number = strings(0,1);
Elements = strings(0,1);
pressure = [];
temperature = [];
density = [];
massflow = [];

%% LH2 Analysis
species = 'H2';

% tank data (K24)
mdot_K24 = 73.22;        %[kg/s]
p_K24    = 2.07*1e5;     %[Pa]
T_K24    = 20.6;         %[K]
rho_K24  = 70.57;        %[kg/m3]

% state check
state = state_checkNEW(p_K24, T_K24, species);
fprintf('%s: %s\n', "K24", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Tank", "K24", species, p_K24, T_K24, rho_K24, mdot_K24);
%% Pump (K25)
W_K25   = 2.755*1e6;   % [Watt]
eta_K25 = 0.650;       % Isentropic efficiency

[T_K25, p_K25, rho_K25, h_K25, s_K25] = pumpNFP(species, W_K25, eta_K25, ...
                                      mdot_K24, p_K24, T_K24);

% state check
state = state_checkNEW(p_K25, T_K25, species);
fprintf('%s: %s\n', "K25", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", "K25", species, p_K25, T_K25, rho_K25, mdot_K24);
%% Pump (K26)
mdot_K26 = mdot_K24;     %[kg/s]
W_K26   = 57.79*1e6;     %[Watt]
eta_K26 = 0.73;          % Isentropic efficiency

[T_K26, p_K26, rho_K26, h_K26, s_K26] = pumpNFP(species, W_K26, eta_K26, ...
                                      mdot_K26, p_K25, T_K25);

% state check
state = state_checkNEW(p_K26, T_K26, species);
fprintf('%s: %s\n', "K26", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", "K26", species, p_K26, T_K26, rho_K26, mdot_K26);

%% Valve (K64)
Pr= 1.05;       %Pressure ratio

[p_K64,T_K64,h_K64,s_K64,rho_K64] = valve(species,T_K26,p_K26,Pr);

% state check
state = state_checkNEW(p_K64, T_K64, species);
fprintf('%s: %s\n', "K64", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K64", species, p_K64, T_K64, rho_K64, mdot_K26);

%% Distribution H2 (K27)
%the flow is going to be splitted in 2 lines:
mdot_S34 = 57.76;                   %[kg/s]
mdot_S41 = mdot_K26 - mdot_S34;     %[kg/s]

%% Line 1: 
%% Distribution --> CCV (K35)
%the flow is going to be splitted in 2 subsublines:
mdot_S87 = mdot_S34/2;
mdot_S88 = mdot_S34/2;
%% Heat Exchanger (K28) (Subsubline 1)
Pr = 1.074;
T_K28 = 257.8;      %[K]

[p_K28,h_K28,s_K28,rho_K28,Q_eff_K28] = Heat_Exchanger(species,p_K64,T_K64,T_K28,mdot_S87,Pr);

% state check
state = state_checkNEW(p_K28, T_K28, species);
fprintf('%s: %s\n', "K28", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Heat Exchanger", "K28", species, p_K28, T_K28, rho_K28, mdot_S87);

%% Valve (K36) (Subsubline 2)
Pr= 1.074;       %Pressure ratio


[p_K36,T_K36,h_K36,s_K36,rho_K36] = valve(species,T_K64,p_K64,Pr);

% state check
state = state_checkNEW(p_K36, T_K36, species);
fprintf('%s: %s\n', "K36", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K36", species, p_K36, T_K36, rho_K36, mdot_S88);

%% Mixer H2 (K37)
p_K37 = p_K36;

% --- Build inlet 1 (Heat Exchanger K28) ---
in1.species = species;
in1.mdot    = mdot_S87;
in1.p       = p_K28;
in1.T       = T_K28;

% --- Build inlet 2 (valve K36) ---
in2.species = species;
in2.mdot    = mdot_S88;
in2.p       = p_K36;
in2.T       = T_K36;

% --- Call unified mixer ---
outK37 = mixer(in1, in2, p_K37);

% --- Extract results ---
mdot_K37 = outK37.mdot;
T_K37    = outK37.T;
h_K37    = outK37.h;
rho_K37  = outK37.rho;

% state check
state = state_checkNEW(p_K37, T_K37, species);
fprintf('%s: %s\n', "K37", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Mixer", "K37", species, p_K37, T_K37, rho_K37, mdot_K37);

%% Distribution H2--> PB (K30)
%the flow is going to be splitted again in other 2 subsublines:
mdot_S37 = 37.82;       %[kg/s]
mdot_S39 = 19.94;       %[kg/s]

%% Valve (K31) (Subsubline 1)
Pr= 1.102;       %Pressure ratio

[p_K31,T_K31,h_K31,s_K31,rho_K31] = valve(species,T_K37,p_K37,Pr);

% state check
state = state_checkNEW(p_K31, T_K31, species);
fprintf('%s: %s\n', "K31", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K31", species, p_K31, T_K31, rho_K31, mdot_S37);

%% Valve (K38) (Subsubline 2)

Pr= 1.114;       %Pressure ratio

[p_K38,T_K38,h_K38,s_K38,rho_K38] = valve(species,T_K37,p_K37,Pr);

% state check
state = state_checkNEW(p_K38, T_K38, species);
fprintf('%s: %s\n', "K38", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K38", species, p_K38, T_K38, rho_K38, mdot_S39);

%% Line 2: 
%% Heat Exchanger (K32)
Pr = 1.341;
T_K32 = 252.8;      %[K]

[p_K32,h_K32,s_K32,rho_K32,Q_eff_K32] = Heat_Exchanger(species,p_K64,T_K64,T_K32,mdot_S41,Pr);

% state check
state = state_checkNEW(p_K32, T_K32, species);
fprintf('%s: %s\n', "K32", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Heat Exchanger", "K32", species, p_K32, T_K32, rho_K32, mdot_S41);

%% Turbine (K34)
W_K34 = 2.755*1e6;
eta_K34 = 0.52;

[T_K34,p_K34,h_K34,s_K34,rho_K34] = turbine(species,W_K34,eta_K34,mdot_S41,p_K32,T_K32);

% state check
state = state_checkNEW(p_K34, T_K34, species);
fprintf('%s: %s\n', "K34", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Turbine", "K34", species, p_K34, T_K34, rho_K34, mdot_S41);

%% Distribution H2--> TankpresFuel (K71)
%the flow is going to be splitted again in other 2 subsublines:
mdot_S48 = 0.35;       %[kg/s]
mdot_S45 = 15.11;       %[kg/s]

%% Valve (K73) (Subsubline 1)
p_K73 = 3.51 * 1e5;     %[bar]
Pr = p_K34/p_K73;       %Pressure ratio

[p_K73,T_K73,h_K73,s_K73,rho_K73] = valve(species,T_K34,p_K34,Pr);

% state check
state = state_checkNEW(p_K73, T_K73, species);
fprintf('%s: %s\n', "K73", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K73", species, p_K73, T_K73, rho_K73, mdot_S48);

%% Distribution H2--> HGM Fuel (K72) (Subsubline 2)
%the flow is going to be splitted again in other 2 subsubsublines:
mdot_S47 = 1.9;       %[kg/s]
mdot_S46 = 13.22;     %[kg/s]

%% Valve (K59) (Subsubsubline 1)
Pr = 1.053;       %Pressure ratio

[p_K59,T_K59,h_K59,s_K59,rho_K59] = valve(species,T_K34,p_K34,Pr);

% state check
state = state_checkNEW(p_K59, T_K59, species);
fprintf('%s: %s\n', "K59", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K59", species, p_K59, T_K59, rho_K59, mdot_S47);

%% Distribution H2--> MCC (K74) (Subsubsubline 2)
%the flow is going to be splitted again in other 2 sublines of 4th order:
mdot_S70 = 0.47;       %[kg/s]
mdot_S77 = 12.75;     %[kg/s]

%% Valve (K76) (Subline 1 of 4th order)
Pr = 1.134;       %Pressure ratio

[p_K76,T_K76,h_K76,s_K76,rho_K76] = valve(species,T_K34,p_K34,Pr);

% state check
state = state_checkNEW(p_K76, T_K76, species);
fprintf('%s: %s\n', "K76", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K76", species, p_K76, T_K76, rho_K76, mdot_S77);

%% Valve (K58) (Subline 2 of 4th order)
Pr = 1.053;       %Pressure ratio

[p_K58,T_K58,h_K58,s_K58,rho_K58] = valve(species,T_K34,p_K34,Pr);

% state check
state = state_checkNEW(p_K58, T_K58, species);
fprintf('%s: %s\n', "K58", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K58", species, p_K58, T_K58, rho_K58, mdot_S70);

%% LO2 Analysis
species = 'O2';

% tank data (K9)
mdot_K9 = 439.34;        %[kg/s]
p_K9    = 6.89*1e5;     %[Pa]
T_K9    = 91.1;         %[K]
rho_K9  = 1137.99;      %[kg/m3]

% state check
state = state_checkNEW(p_K9, T_K9, species);
fprintf('%s: %s\n', "K9", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Tank", "K9", species, p_K9, T_K9, rho_K9, mdot_K9);

%% Pump (K10)
W_K10   = 1.396*1e6;   % [Watt]
eta_K10 = 0.63;       % Isentropic efficiency

[T_K10, p_K10, rho_K10, h_K10, s_K10] = pumpNFP(species, W_K10, eta_K10, ...
                                      mdot_K9, p_K9, T_K9);

% state check
state = state_checkNEW(p_K10, T_K10, species);
fprintf('%s: %s\n', "K10", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", "K10", species, p_K10, T_K10, rho_K10, mdot_K9);

%% Stage K11
mdot_K11 = 83.06;   %[kg/s]
p_K11 = 29.7*1e5;   %[Pa]
T_K11 = 107.8;      %[K]

%% Mixer O2 (K12)
p_K12 = 29.7*1e5;

% --- Build inlet 1 (Pump K10) ---
in1.species = species;
in1.mdot    = mdot_K9;
in1.p       = p_K10;
in1.T       = T_K10;

% --- Build inlet 2 (stage K11) ---
in2.species = species;
in2.mdot    = mdot_K11;
in2.p       = p_K11;
in2.T       = T_K11;

% --- Call unified mixer ---
outK12 = mixer(in1, in2, p_K12);

% --- Extract results ---
mdot_K12 = outK12.mdot;
T_K12    = outK12.T;
h_K12    = outK12.h;
rho_K12  = outK12.rho;

% state check
state = state_checkNEW(p_K12, T_K12, species);
fprintf('%s: %s\n', "K12", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Mixer", "K12", species, p_K12, T_K12, rho_K12, mdot_K12);

%% Pump (K13)
W_K13   = 20.51*1e6;   % [Watt]
eta_K13 = 0.67;       % Isentropic efficiency

[T_K13, p_K13, rho_K13, h_K13, s_K13] = pumpNFP(species, W_K13, eta_K13, ...
                                      mdot_K12, p_K12, T_K12);

% state check
state = state_checkNEW(p_K13, T_K13, species);
fprintf('%s: %s\n', "K13", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", "K13", species, p_K13, T_K13, rho_K13, mdot_K12);

%% Distribution LOX -->LPOTP (K14)
%the flow is going to be splitted again in 2 sublines of the 1st order:
mdot_S15 = 83.06;       %[kg/s]
mdot_S17 = 439.34;      %[kg/s]

%% Turbine (K15)  (Subline 1, 1st order)
W_K15 = 1.396*1e6;      %[W]
eta_K15 = 0.62;         

[T_K15,p_K15,h_K15,s_K15,rho_K15] = turbine(species,W_K15,eta_K15,mdot_S15,p_K13,T_K13);

% state check
state = state_checkNEW(p_K15, T_K15, species);
fprintf('%s: %s\n', "K15", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Turbine", "K15", species, p_K15, T_K15, rho_K15, mdot_S15);

%% Distribution O2 -->TankpresOx (K66) (Subline 2 of 1st order)
%the flow is going to be splitted again in 2 sublines of the 2st order:
mdot_S74 = 0.75;        %[kg/s]
mdot_S29 = 438.59;      %[kg/s]

%% Heat Exchanger (K67) (Subline 1 of 2nd order)
Pr = 1.157;
T_K67 = 507.8;       %[K]

[p_K67,h_K67,s_K67,rho_K67,Q_eff_K67] = Heat_Exchanger(species,p_K13,T_K13,T_K67,mdot_S74,Pr);

% state check
state = state_checkNEW(p_K67, T_K67, species);
fprintf('%s: %s\n', "K67", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Heat Exchanger", "K67", species, p_K67, T_K67, rho_K67, mdot_S74);

%% Valve (K70) 
p_K70 = 2.49*1e5;         %Exit pressure
Pr = p_K67/p_K70;         %Pressure ratio

[p_K70,T_K70,h_K70,s_K70,rho_K70] = valve(species,T_K67,p_K67,Pr);

% state check
state = state_checkNEW(p_K70, T_K70, species);
fprintf('%s: %s\n', "K70", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K70", species, p_K70, T_K70, rho_K70, mdot_S74);

%% Distribution O2 -->2nd Stage (K16) (Subline 2 of 2nd order)
%the flow is going to be splitted again in 2 sublines of the 3th order:
mdot_S18 = 388.13;     %[kg/s]
mdot_S20 = 50.46;      %[kg/s]

%% Pump (K18) (Subline 1 of 3th order)
W_K18   = 1.263*1e6;    % [Watt]
eta_K18 = 0.8;          % Isentropic efficiency

[T_K18, p_K18, rho_K18, h_K18, s_K18] = pumpNFP(species, W_K18, eta_K18, ...
                                      mdot_S20, p_K13, T_K13);

% state check
state = state_checkNEW(p_K18, T_K18, species);
fprintf('%s: %s\n', "K18", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", "K18", species, p_K18, T_K18, rho_K18, mdot_S20);

%% Distribution Pump HPOTP 2SL (K19)
%the flow is going to be splitted again in 2 sublines of the 4th order:
mdot_S22 = 13.56;      %[kg/s]
mdot_S24 = 36.89;      %[kg/s]

%% Valve (K61) (Subline 1 of 4th order)
Pr = 1.182;         %Pressure ratio

[p_K61,T_K61,h_K61,s_K61,rho_K61] = valve(species,T_K18,p_K18,Pr);

% state check
state = state_checkNEW(p_K61, T_K61, species);
fprintf('%s: %s\n', "K61", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K61", species, p_K61, T_K61, rho_K61, mdot_S22);

%% Valve (K20) 
Pr = 1.221;         %Pressure ratio

[p_K20,T_K20,h_K20,s_K20,rho_K20] = valve(species,T_K61,p_K61,Pr);

% state check
state = state_checkNEW(p_K20, T_K20, species);
fprintf('%s: %s\n', "K20", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K20", species, p_K20, T_K20, rho_K20, mdot_S22);

%% Valve (K62) (Subline 2 of 4th order)
Pr = 1.151;         %Pressure ratio

[p_K62,T_K62,h_K62,s_K62,rho_K62] = valve(species,T_K18,p_K18,Pr);

% state check
state = state_checkNEW(p_K62, T_K62, species);
fprintf('%s: %s\n', "K62", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K62", species, p_K62, T_K62, rho_K62, mdot_S24);

%% Valve (K21) 
Pr = 1.240;         %Pressure ratio

[p_K21,T_K21,h_K21,s_K21,rho_K21] = valve(species,T_K62,p_K62,Pr);

% state check
state = state_checkNEW(p_K21, T_K21, species);
fprintf('%s: %s\n', "K21", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K21", species, p_K21, T_K21, rho_K21, mdot_S24);

%% Valve (K63) (Subline 1 of 4th order)
Pr = 1.163;         %Pressure ratio

[p_K63,T_K63,h_K63,s_K63,rho_K63] = valve(species,T_K13,p_K13,Pr);

% state check
state = state_checkNEW(p_K63, T_K63, species);
fprintf('%s: %s\n', "K63", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K63", species, p_K63, T_K63, rho_K63, mdot_S18);

%% Valve (K17) 
Pr = 1.233;         %Pressure ratio

[p_K17,T_K17,h_K17,s_K17,rho_K17] = valve(species,T_K63,p_K63,Pr);

% state check
state = state_checkNEW(p_K17, T_K17, species);
fprintf('%s: %s\n', "K17", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K17", species, p_K17, T_K17, rho_K17, mdot_S18);

%% --------------------------
% ORANGE LINES
% ---------------------------
%% Oxidizer Preburner (K40) 
p_K40 = 387.25*1e5;
eta = 0.995;
species = {'H2','O2','H2O','H','O','OH'};

[species,T_K40,n_K40,OF_K40,mdot_K40,H_K40,S_K40,Rg_K40,rho_K40,Mm_K40] = preburner(species,mdot_S39,mdot_S22,T_K38,T_K20,p_K38,p_K20,p_K40,eta);

% state check
state = state_checkNEW(p_K40, T_K40, species, n_K40);
fprintf('%s: %s\n', "K40", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Oxidizer Preburner", "K40", species, p_K40, T_K40, rho_K40, mdot_K40);

%% Fuel Preburner (K45) 
p_K45 = 391.47*1e5;
eta = 0.995;
species = {'H2','O2','H2O','H','O','OH'};

[species,T_K45,n_K45,OF_K45,mdot_K45,H_K45,S,Rg_K45,rho_K45,Mm_K45] = preburner(species,mdot_S37,mdot_S24,T_K31,T_K21,p_K31,p_K21,p_K45,eta);

% state check
state = state_checkNEW(p_K45, T_K45, species, n_K45);
fprintf('%s: %s\n', "K45", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Fuel Preburner", "K45", species, p_K45, T_K45, rho_K45, mdot_K45);

%% Turbine (K46)
W_K46 = 57.79*1e6;
eta_K46 = 0.78;

%[T_K46,p_K46,H_K46,S_K46,mdot_K46] = turbine(species,n_K45,W_K46,eta_K46,mdot_K45,p_K45,T_K45);
[T_K46,p_K46,h_K46,s_K46,rho_K46] = turbine(species,W_K46,eta_K46,mdot_K45,p_K45,T_K45,n_K45);

% state check
state = state_checkNEW(p_K46, T_K46, species, n_K45);
fprintf('%s: %s\n', "K46", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Turbine", "K46", species, p_K46, T_K46, rho_K46, mdot_K45);

%% Turbine (K41)
W_K41 = 21.77*1e6;
eta_K41 = 0.78;

[T_K41,p_K41,h_K41,s_K41,rho_K41] = turbine(species,W_K41,eta_K41,mdot_K40,p_K40,T_K40,n_K40);

% state check
state = state_checkNEW(p_K41, T_K41, species, n_K40);
fprintf('%s: %s\n', "K41", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Turbine", "K41", species, p_K41, T_K41, rho_K41, mdot_K40);

%% Heat Exchanger HGS (K68)
Pr = 1.013;
T_K68 = 759.5;         %[K]

[p_K68,h_K68,s_K68,rho_K68,Q_eff_K68] = Heat_Exchanger(species,p_K41,T_K41,T_K68,mdot_K40,Pr,n_K40);

% state check
state = state_checkNEW(p_K68, T_K68, species, n_K40);
fprintf('%s: %s\n', "K68", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Heat Exchanger", "K68", species, p_K68, T_K68, rho_K68, mdot_K40);

%% -----------------------
% GREEN LINES
% ---------------------------
%% HotGas-Mixer (K49)
species_K46 = {'H2','O2','H2O','H','O','OH'};
species_K59 = 'H2';
p_K49 = 248.21*1e5;

% --- Build inlet 1 (Turbine K46) ---
in1.species = species_K46;
in1.mdot    = mdot_K45;
in1.p       = p_K46;
in1.T       = T_K46;
in1.n       = n_K45;

% --- Build inlet 2 (valve K59) ---
in2.species = species_K59;
in2.mdot    = mdot_S47;
in2.p       = p_K59;
in2.T       = T_K59;

% --- Call unified mixer ---
outK49 = mixer(in1, in2, p_K49);

% --- Extract results ---
mdot_K49 = outK49.mdot;
T_K49    = outK49.T;
h_K49    = outK49.h;
rho_K49  = outK49.rho;
n_K49    = outK49.n;

% state check
state = state_checkNEW(p_K49, T_K49, species, n_K49);
fprintf('%s: %s\n', "K49", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "HotGas-Mixer", "K49", species, p_K49, T_K49, rho_K49, mdot_K49);

%% Valve (K47) 
Pr = 1.077;         %Pressure ratio

[p_K47,T_K47,H_K47,S_K47,rho_K47,n_K47] = valve(species,n_K49,T_K49,p_K49,Pr);

% state check
state = state_checkNEW(p_K47, T_K47, species, n_K47);
fprintf('%s: %s\n', "K47", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K47", species, p_K47, T_K47, rho_K47, mdot_K49);

%% HotGas-Mixer (K48)
species_K68 = {'H2','O2','H2O','H','O','OH'};
species_K58 = 'H2';
p_K48 = 248.21*1e5;

% --- Build inlet 1 (Heat Exchanger K68) ---
in1.species = species_K68;
in1.mdot    = mdot_K40;
in1.p       = p_K68;
in1.T       = T_K68;
in1.n       = n_K40;

% --- Build inlet 2 (valve K58) ---
in2.species = species_K58;
in2.mdot    = mdot_S70;
in2.p       = p_K58;
in2.T       = T_K58;

% --- Call unified mixer ---
outK48 = mixer(in1, in2, p_K48);

% --- Extract results ---
mdot_K48 = outK48.mdot;
T_K48    = outK48.T;
h_K48    = outK48.h;
rho_K48  = outK48.rho;
n_K48    = outK48.n;

% state check
state = state_checkNEW(p_K48, T_K48, species, n_K48);
fprintf('%s: %s\n', "K48", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "HotGas-Mixer", "K48", species, p_K48, T_K48, rho_K48, mdot_K48);

%% Valve (K42) 
Pr = 1.077;         %Pressure ratio

[p_K42,T_K42,H_K42,S_K42,rho_K42,n_K42] = valve(species,n_K48,T_K48,p_K48,Pr);

% state check
state = state_checkNEW(p_K42, T_K42, species, n_K42);
fprintf('%s: %s\n', "K42", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", "K42", species, p_K42, T_K42, rho_K42, mdot_K48);

%% Main Combustion Chamber (K50)

species_H2 = 'H2'; % Define the species for H2
species_O2 = 'O2'; % Define the species for O2
species1_HGS = {'H2','O2','H2O','H','O','OH'}; % Define the species for the first HGS
species2_HGS = {'H2','O2','H2O','H','O','OH'}; % Define the species for the second HGS
p_K50 = 230.40*1e5;
eta = 0.993;

[species,T_K50,n_K50,OF_K50,mdot_K50,H_K50,S_K50,Rg_K50,rho_K50,Mm_K50] = C_Chamber_Main(mdot_S77,mdot_S18,mdot_K48,mdot_K49,T_K76,T_K17,T_K42,T_K47,p_K76,p_K17,p_K42,p_K47,p_K50,n_K42,n_K47,eta,species_H2,species_O2,species1_HGS,species2_HGS);

% state check
state = state_checkNEW(p_K50, T_K50, species, n_K50);
fprintf('%s: %s\n', "K50", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Main Combustion Chamber ", "K50", species, p_K50, T_K50, rho_K50, mdot_K50);

%% Main Combustion Chamber FAC (K51)
Pr = 0.977;     %Pressure ratio
Ar = 1/2.96;    %Area ratio


%% Adiabatic Nozzle (K54)
p_K54 = 0.19243*1e5;    %Exit pressure
p_ambient = 1e-4;       % Ambient pressure in Pascals
[species,n_K54,T_K54,v_K54,M_K54,A_K54,F_K54,Isp_K54,rho_K54] = nozzle_adiabatic(species,T_K50,n_K50,p_K50,'Shifting','P',p_K54,p_ambient);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Adiabatic Nozzle", "K54", species, p_K54, T_K54, rho_K54, mdot_K50);


%% Corrected Nozzle (K54)
Q = (47.76 + 93.13)*1e6; %heat extracted

[species,n_K54_corr,T_K54_corr,v_K54_corr,M_K54_corr,A_K54_corr,F_K54_corr,Isp_K54_corr,rho_K54_corr] = nozzle_corrected(species,T_K50,n_K50,p_K50,Q,mdot_K50,Mm_K50,'Shifting','P',p_K54,p_ambient);

% state check
state = state_checkNEW(p_K54, T_K54_corr, species, n_K54_corr);
fprintf('%s: %s\n', "K54", state);

% Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Corrected Nozzle", "K54", species, p_K54, T_K54_corr, rho_K54_corr, mdot_K50);

%% Results in a table
results = table(Position', number', Elements', pressure', temperature', density', massflow', ...
    'VariableNames',{'Position','number','Elements','pressure', 'temperature', 'density', 'mass flow'});
disp(results);

disp(['Q (heat exchanger K28) = ' num2str(Q_eff_K28) ' W']);
disp(['Q (heat exchanger K32) = ' num2str(Q_eff_K32) ' W']);
disp(['Q (heat exchanger K67) = ' num2str(Q_eff_K67) ' W']);
disp(['Q (heat exchanger K68) = ' num2str(Q_eff_K68) ' W']);