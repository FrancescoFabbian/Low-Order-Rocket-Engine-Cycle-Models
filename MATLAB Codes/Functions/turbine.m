function [T_out, p_out, h_out, s_out, rho_out] = turbine(species, W, eta, mdot, p_in, T_in, varargin)

% Unified turbine model:
%   - NFP is used for SINGLE-SPECIES real-fluid calculations
%   - HGS is used for MULTI-SPECIES gas mixtures (frozen composition)
%
% SELECTION RULE:
%   - If molar vector n is provided → HGS
%   - If not → NFP
%
% -------------------------------------------------------------------------
% INPUTS (common):
%   species : string (NFP) or cell array (HGS)
%   W       : turbine power extracted [W]
%   eta     : isentropic efficiency [-]
%   mdot    : mass flow rate [kg/s]
%   p_in    : inlet pressure [Pa]
%   T_in    : inlet temperature [K]
%
% OPTIONAL INPUT:
%   n       : molar composition vector [mol] → triggers HGS
%
% OUTPUTS:
%   T_out   : outlet temperature [K]
%   p_out   : outlet pressure [Pa]
%   h_out   : outlet specific enthalpy [kJ/kg]
%   s_out   : outlet specific entropy [kJ/(kg·K)]
%   rho_out : outlet density [kg/m^3] (NFP only)
% -------------------------------------------------------------------------

%% ===================== MODE SELECTION =====================
useHGS = (nargin == 7);   % n provided → mixture

%% ======================= HGS BRANCH =======================
if useHGS

    n = varargin{1};   % molar composition vector
    % TURBINEHGS  Frozen-composition turbine model using HGS.
    %
    % The turbine is modeled as:
    %   - Adiabatic
    %   - Frozen chemical composition (molar amounts n constant)
    %   - Power-extracting device with isentropic efficiency eta
    %
    % Thermodynamic properties are evaluated using HGS, which returns EXTENSIVE
    % quantities (total enthalpy and entropy of the mixture).
    %
    % INPUTS:
    %   species : cell array of species names
    %   n       : molar amounts of each species [mol] (frozen)
    %   W       : shaft power extracted [W]
    %   eta     : isentropic efficiency [-]
    %   mdot    : mass flow rate [kg/s]
    %   p_in    : inlet pressure [Pa]
    %   T_in    : inlet temperature [K]
    %
    % OUTPUTS:
    %   T_out   : outlet temperature [K]
    %   p_out   : outlet pressure [Pa]
    %   H_out   : outlet total enthalpy [kJ]
    %   S_out   : outlet total entropy [kJ/K]
    %   mdot    : mass flow rate (unchanged)
    %% Inlet pressure conversion
    pbar_in = p_in / 1e5;   % [bar]
    
    %% Inlet thermodynamic state (EXTENSIVE)
    H_in = HGSprop(species, n, T_in, pbar_in, 'H');   % [kJ]
    S_in = HGSprop(species, n, T_in, pbar_in, 'S');   % [kJ/K]
    
    %% Real outlet enthalpy from turbine power balance
    %   W = H_in_dot - H_out_dot  →  H_out = H_in - W
    H_out = H_in - W/1000;   % [kJ]
    
    %% Isentropic reference enthalpy
    H_out_s = H_in - (H_in - H_out)/eta;   % [kJ]
    S_out_s = S_in;                         % isentropic condition
    
    %% Solve for isentropic outlet state (T_out_s, p_out_s)
    % Unknowns:
    %   x(1) = T_out_s [K]
    %   x(2) = p_out_s [bar]
    f_isentropic = @(x) [
        HGSprop(species, n, x(1), x(2), 'H') - H_out_s;
        HGSprop(species, n, x(1), x(2), 'S') - S_out_s
    ];
    
    % Physically consistent initial guess (expansion)
    x0 = [0.8*T_in, 0.3*pbar_in];
    
    x_sol = fsolve(f_isentropic, x0);
    
    T_out_s    = x_sol(1);   % [K]
    pbar_out_s = x_sol(2);   % [bar]
    
    %% Real outlet pressure (assumed equal to isentropic pressure)
    pbar_out = pbar_out_s;
    p_out    = pbar_out * 1e5;   % [Pa]
    
    %% Real outlet temperature from enthalpy condition
    f_Tout = @(T) HGSprop(species, n, T, pbar_out, 'H') - H_out;
    T_out  = fzero(f_Tout, T_out_s);
    
    % -------- Convert to specific properties --------
    Mm = HGSprop(species, n, T_out, pbar_out, 'Mm');  % [g/mol]
    M  = sum(n)*Mm/1000;                              % [kg]

    h_out = H_out / M;
    s_out = HGSprop(species, n, T_out, pbar_out, 'S') / M;

    Rg = HGSprop(species, n, T_out, pbar_out, 'Rg');   % [kJ/(kg·K)]
    rho_out = p_out / (Rg * 1e3 * T_out);                  % [kg/m^3]

    return
end

%% ======================= NFP BRANCH =======================

% -------- Pressure conversion --------
pbar_in = p_in/1e5;

% Checking NFP validity
[isValid, ~] = checkNFPRange(species, p_in, T_in);

if isValid
    % -------- Inlet state --------
    h_in = NFP(species,'h_pt',pbar_in,T_in);   % [kJ/kg]
    s_in = NFP(species,'s_pt',pbar_in,T_in);   % [kJ/(kg·K)]
    
    % -------- Real turbine enthalpy drop --------
    h_out = h_in - W/(1000*mdot);
    
    % -------- Isentropic reference enthalpy --------
    h_out_s = h_in - (h_in - h_out)/eta;
    s_out_s = s_in;

    % Solve (h(p,T), s(p,T)) simultaneously
    fun = @(x) [
        NFP(species,'h_pt',x(1),x(2)) - h_out_s
        NFP(species,'s_pt',x(1),x(2)) - s_out_s
    ];
    
    x0 = [2, 200];   % [p_bar, T]
    x_sol = fsolve(fun, x0);
    
    pbar_out_s = x_sol(1);

    % -------- Final outlet state --------
    pbar_out = pbar_out_s;
    p_out    = pbar_out * 1e5;
    
    T_out   = NFP(species,'t_hp',h_out,pbar_out);
    s_out   = NFP(species,'s_pt',pbar_out,T_out);
    rho_out = NFP(species,'r_pt',pbar_out,T_out);

    else
    disp('We cannot use NFP');
end
end


%% for reference: furter tries to obtain outlet pressure for turbineNFP
    %% 1 try
    %trying to find p_out_s and T_out_s
    % f_Touts_s = NFP(species,'t_ps',p,s_out_s);
    % f_Touts_h = NFP(species,'t_hp',h_out_s,p);


    % f_pout_s = @(p) NFP(species,'t_ps',p,s_out_s)-NFP(species,'t_hp',h_out_s,p);
    % pbar_out_s = fzero (f_pout_s,[7.36*1e-2, 7*1e2]);
    % disp(size(pbar_out_s))

    %% 3try
    % Decision variables:
    % x(1) = p_bar  (pressure in bar)
    % x(2) = T      (temperature in K)
    % 
    % objfun = @(x) ( NFP('H2','h_pt', x(1), x(2)) - h_out_s )^2 + ...
    %                ( NFP('H2','s_pt', x(1), x(2)) - s_out_s )^2;
    % 
    % % Bounds (VERY IMPORTANT!)
    % % Physical limits for H2 turbine expansion
    % pmin = 1e-4;    % 0.0001 bar   (avoid REFPROP failures)
    % pmax = 800;     % 800 bar       (cryogenic range)
    % Tmin = 10;      % 10 K          (near LH2 boiling)
    % Tmax = 6000;    % 6000 K        (combustion range)
    % 
    % lb = [pmin, Tmin];
    % ub = [pmax, Tmax];
    % 
    % % Initial guess (critical for stability)
    % % You can use typical LH2 turbine values; this guess is robust:
    % x0 = [10, 100];   % p=10 bar, T=100 K
    % 
    % options = optimoptions('fmincon', ...
    %     'Display','iter-detailed', ...  % or 'none' for quiet output
    %     'Algorithm','interior-point', ...
    %     'MaxFunctionEvaluations', 2e4, ...
    %     'MaxIterations', 1e3);
    % 
    % [x_sol,~,exitflag] = fmincon(objfun, x0, [], [], [], [], lb, ub, [], options);

    % % Extract solution
    % p2_bar = x_sol(1);
    % T2s    = x_sol(2);

    % Convert pressure if needed:
    % p2 = p2_bar * 1e5;   % [Pa]



    % for a much simpler calculation: p_out is assumed to be the same as
    % p_out_s (let's see if we can go with this assumption)