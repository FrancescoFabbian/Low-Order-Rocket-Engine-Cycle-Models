clear; close all; clc;

%% storage arrays - gives out a table in the end and easier to plot
Position = strings(0,1);
number = [];
Elements = strings(0,1);
pressure = [];
temperature = [];
density = [];
massflow = [];

%% LH2 Analysis
species = 'H2';

% tank data (50)
mdot_50 = 93.677;       %[kg/s]
p_50 = 0.3*1e6;         %[Pa]
T_50 = 21;              %[K]
rho_50 = 70.22;         %[kg/m3]       
pbar_50 = p_50/1e5;     % [bar]

% state check
state = state_checkNEW(p_50, T_50, species);
fprintf('%d: %s\n', 50, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Tank", 50, species, p_50, T_50, rho_50, mdot_50);

%% Pump (10)
W_10 = 15443000;   % [Watt]
eta_10 = 0.7;

[T_10, p_10, rho_10, h_10, s_10] = pumpNFP(species, W_10, eta_10, mdot_50, p_50, T_50);

% state check
state = state_checkNEW(p_10, T_10, species);
fprintf('%d: %s\n', 10, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", 10, species, p_10, T_10, rho_10, mdot_50);

% relative error computation
p_10_real = 8.749*1e6;            %[Pa]
T_10_real = 29.44;                %[K]
rho_10_real  = 71.751;        %[kg/m3]

[error_T_10, error_p_10, error_rho_10] = rel_error(T_10, p_10, rho_10, T_10_real, p_10_real, rho_10_real);

%% pump (12)
mdot_12 = mdot_50 - 77.283;     %[kg/s]
W_12 = 1010000;                 %[Watt]
eta_12 = 0.75;

[T_12, p_12, rho_12, h_12, s_12] = pumpNFP(species, W_12, eta_12, mdot_12, p_10_real, T_10_real);

% state check
state = state_checkNEW(p_12, T_12, species);
fprintf('%d: %s\n', 12, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", 12, species, p_12, T_12, rho_12, mdot_12);

% relative error computation
p_12_real = 12.109*1e6;            %[Pa]
T_12_real = 32.375;                %[K]
rho_12_real  = 72.483;        %[kg/m3]

[error_T_12, error_p_12, error_rho_12] = rel_error(T_12, p_12, rho_12, T_12_real, p_12_real, rho_12_real);

%% Heat exchanger
%species = 'H2';
p_42 = 12109000;    %[Pa]
T_42 = 32.375;      %[K]
p_23 = 8749000;     %[Pa]
T_23 = 506.219;     %[K]
mdot = 16.394;      %[m/s]
pr = p_42/p_23;     % pressure ratio for function input

[~,~,~,~,Q_heat_exchanger] = Heat_Exchanger(species,p_42,T_42,T_23,mdot,pr);   %[W]

% state check
state = state_checkNEW(p_23, T_23, species);
fprintf('%d: %s\n', 23, state);

%% skipping 31, 33
%% Valve 44
mdot_44 = 8.06;         %[kg/s]
p_44 = 8.311*1e6;       %[Pa]
T_44 = 506.452;         %[K]
rho_44 = 3.855;         %[kg/m3] 

% state check
state = state_checkNEW(p_44, T_44, species);
fprintf('%d: %s\n', 44, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", 44, species, p_44, T_44, rho_44, mdot_44);

%% turbine (15)
W_15 = 16620000;                 %[Watt]
eta_15 = 0.45;

[T_15, p_15, h_15, s_15,rho_15] = turbine(species, W_15, eta_15, mdot_44, p_44, T_44);

% state check
state = state_checkNEW(p_15, T_15, species);
fprintf('%d: %s\n', 15, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Turbine", 15, species, p_15, T_15, rho_15, mdot_44);

% relative error computation
p_15_real = 0.3*1e6;            %[Pa]
T_15_real = 369.677;                %[K]
rho_15_real  = 0.196;        %[kg/m3]

[error_T_15, error_p_15, error_rho_15] = rel_error(T_15, p_15, rho_15, T_15_real, p_15_real, rho_15_real);

%% Secondary Nozzle (68)
% mdot_15, p_15, T_15
pa = 101325;                %[Pa] ambient pressure sea level - are we reaching that?
F_68 = 12099;               %[N] Thrust at sea level
Isp_68 = 153.064;           %[sec] Isp at sea level
eta_68 = 0.98;              % engine efficency
epsilon_68 = 1.657;         % area ratio
M_68 = 1.975;               % exit mach number of the nozzle
d_68 = 0.324415;            %[m] exit diameter
V_68 = 2160.55;             %[m/s] exit velocity

[A_68,p_68,T_68, rho_68] = Secondary_Nozzle_PGR(species,V_68,epsilon_68,M_68,d_68,F_68,mdot_44,pa);

% state check
state = state_checkNEW(p_68, T_68, species);
fprintf('%d: %s\n', 68, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Secondary Nozzle", 68, species, p_68, T_68, rho_68, mdot_44);

% relative error computation
p_68_real = 0.04*1e6;            %[Pa]
T_68_real = 214.83;                %[K]
rho_68_real  = NaN;        %[kg/m3]

[error_T_68, error_p_68, error_rho_68] = rel_error(T_68, p_68, rho_68, T_68_real, p_68_real, rho_68_real);

%% skipping 31, 33
%% Valve 45
mdot_45 = 10.704 - mdot_44;         %[kg/s]
p_45 = 8.311*1e6;                   %[Pa]
T_45 = 506.452;                     %[K]
rho_45 = 3.855;                     %[kg/m3]

% state check
state = state_checkNEW(p_45, T_45, species);
fprintf('%d: %s\n', 45, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", 45, species, p_45, T_45, rho_45, mdot_45);
%% turbine (16)
W_16 = 4358000;                 %[Watt]
eta_16 = 0.45;
mdot_wrong = 2.114;             %[kg/s]

[T_16, p_16, h_16, s_16, rho_16] = turbine(species, W_16, eta_16, mdot_wrong, p_45, T_45);


% state check
state = state_checkNEW(p_16, T_16, species);
fprintf('%d: %s\n', 16, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Turbine", 16, species, p_16, T_16, rho_16, mdot_wrong);

% relative error computation
p_16_real = 0.3*1e6;            %[Pa]
T_16_real = 369.677;                %[K]
rho_16_real  = 0.196;        %[kg/m3]

[error_T_16, error_p_16, error_rho_16] = rel_error(T_16, p_16, rho_16, T_16_real, p_16_real, rho_16_real);

%% Secondary Nozzle (66)
F_66 = 4129;                %[N] Thrust at sea level
Isp_66 = 158.933;           %[sec] Isp at sea level
eta_66 = 0.98;              % engine efficency
epsilon_66 = 1.651;         % area ratio
M_66 = 1.973;               % exit mach number of the nozzle
d_66 = 0.189048;            %[m] exit diameter
V_66 = 2240.18;             %[m/s] exit velocity

[A_66,p_66,T_66, rho_66] = Secondary_Nozzle_PGR(species,V_66,epsilon_66,M_66,d_66,F_66,mdot_45,pa);

% state check
state = state_checkNEW(p_66, T_66, species);
fprintf('%d: %s\n', 66, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Secondary Nozzle", 66, species, p_66, T_66, rho_66, mdot_45);

% relative error computation
p_66_real = 0.04*1e6;            %[Pa]
T_66_real = 230.15;                %[K]
rho_66_real  = NaN;        %[kg/m3]

[error_T_66, error_p_66, error_rho_66] = rel_error(T_66, p_66, rho_66, T_66_real, p_66_real, rho_66_real);

%% Mixer
% input
% turbine feed (31)
mdot_31 = 5.684;            %[m/sec]
p_31 = 8.749*1e6;           %[Pa]
T_31 = 506.219;             %[K]
rho_31 = 4.053;             %[kg/m^3]

% state check
state = state_checkNEW(p_31, T_31, species);
fprintf('%d: %s\n', 31, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Turbine Feed", 31, species, p_31, T_31, rho_31, mdot_31);

% valve (40)
mdot_40 = 77.283;           %[kg/s]
p_40 = p_10;                %[Pa]
T_40 = T_10;                %[K]
rho_40 = rho_10;            %[kg/m^3]

% state check
state = state_checkNEW(p_40, T_40, species);
fprintf('%d: %s\n', 40, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Valve", 40, species, p_40, T_40, rho_40, mdot_40);

% mixer (53)
p_53 = 8.312*1e6;           %[Pa]

% --- Build inlet 1 (turbine feed 31) ---
in1.species = species;
in1.mdot    = mdot_31;
in1.p       = p_31;
in1.T       = T_31;

% --- Build inlet 2 (valve 40) ---
in2.species = species;
in2.mdot    = mdot_40;
in2.p       = p_40;
in2.T       = T_40;

% --- Call unified mixer ---
out53 = mixer(in1, in2, p_53);

% --- Extract results ---
mdot_53 = out53.mdot;
T_53    = out53.T;
h_53    = out53.h;
rho_53  = out53.rho;

% state check
state = state_checkNEW(p_53, T_53, species);
fprintf('%d: %s\n', 53, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Mixer", 53, species, p_53, T_53, rho_53, mdot_53);

% relative error computation
p_53_real = 8.312*1e6;            %[Pa]
T_53_real = 62.955;                %[K]
rho_53_real  = 35.235;        %[kg/m3]

[error_T_53, error_p_53, error_rho_53] = rel_error(T_53, p_53, rho_53, T_53_real, p_53_real, rho_53_real);

%% LOX analysis
species = 'O2';

% tank data (51)
mdot_51 = 456.323;       %[kg/s]
p_51 = 0.5*1e6;         %[Pa]
T_51 = 90;              %[K]
rho_51 = 1143.036;         %[kg/m3]       maybe we should find a way to double check the density (also do we need it?)
pbar_51 = p_51/1e5;     % [bar]

% state check
state = state_checkNEW(p_51, T_51, species);
fprintf('%d: %s\n', 51, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Tank", 51, species, p_51, T_51, rho_51, mdot_51);

%% Pump (11)
W_11 = 4315000;   % [Watt]
eta_11 = 0.76;

[T_11, p_11, rho_11, h_11, s_11] = pumpNFP(species, W_11, eta_11, mdot_51, p_51, T_51);


% state check
state = state_checkNEW(p_11, T_11, species);
fprintf('%d: %s\n', 11, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Pump", 11, species, p_11, T_11, rho_11, mdot_51);

% relative error computation
p_11_real = 8.749*1e6;            %[Pa]
T_11_real = 92.983;                %[K]
rho_11_real  = 1146.46;        %[kg/m3]

[error_T_11, error_p_11, error_rho_11] = rel_error(T_11, p_11, rho_11, T_11_real, p_11_real, rho_11_real);

%% Combustion chamber
% chamber pressure
p_60=6.649*1e6;                 %[Pa]
species = {'H2','O2','H2O','H','O','OH'};

[T_60,n_60,OF,mdot_60,H_60,S_60,Rg_60,rho_60,Mm_60] = C_Chamber(mdot_53,mdot_51,T_53_real,T_11_real,p_53,p_11_real,p_60,species);

% state check
state = state_checkNEW(p_60, T_60, species, n_60);
fprintf('%d: %s\n', 60, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Combustion Chamber", 60, species, p_60, T_60, rho_60, mdot_60);

% relative error computation
p_60_real = 6.649*1e6;            %[Pa]
T_60_real = 3321.91;                %[K]
rho_60_real  = 3.069;        %[kg/m3]

[error_T_60, error_p_60, error_rho_60] = rel_error(T_60, p_60, rho_60, T_60_real, p_60_real, rho_60_real);

%% Main Nozzle (Adiabatic)
p_64=0.06*1e6;          %[Pa]
p_ambient=101325;       %[Pa]
R_60 = 5.5;
%n_60new =

[species,n_64,T_64,v_64,M_64,A_64,F_64,Isp_64,rho_64] = nozzle_adiabatic(species,T_60_real,n_60,p_60,'Shifting','P',p_64,p_ambient);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Main Nozzle (Adiabatic)", 64, species, p_64, T_64, rho_64, mdot_60);

% relative error computation
p_64_real = 0.06*1e6;            %[Pa]
T_64_real = 1579;                %[K]
rho_64_real  = NaN;        %[kg/m3]

[error_T_64, error_p_64, error_rho_64] = rel_error(T_64, p_64, rho_64, T_64_real, p_64_real, rho_64_real);

%% Main Nozzle (Corrected with heat losses)
p_64=0.06*1e6;
p_ambient=101325;

[species,ncorr_64,Tcorr_64,vcorr_64,Mcorr_64,Acorr_64,Fcorr_64,Ispcorr_64,rhocorr_64] = nozzle_corrected(species,T_60_real,n_60,p_60,Q_heat_exchanger,mdot_60,Mm_60,'Shifting','P',p_64,p_ambient);

% state check
state = state_checkNEW(p_64, Tcorr_64, species, ncorr_64);
fprintf('%d: %s\n', 64, state);

%Store Results
[Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 "Main Nozzle (Corrected)", 64, species, p_64, Tcorr_64, rhocorr_64, mdot_60);

[error_Tcorr_64, error_pcorr_64, error_rhocorr_64] = rel_error(Tcorr_64, p_64, rhocorr_64, T_64_real, p_64_real, rho_64_real);

%% Results in a table
results = table(Position', number', Elements', pressure', temperature', density', massflow', ...
    'VariableNames',{'Position','number','Elements','pressure', 'temperature', 'density', 'mass flow'});
disp(results);

disp(['Q (heat exchanger) = ' num2str(Q_heat_exchanger) ' W']);