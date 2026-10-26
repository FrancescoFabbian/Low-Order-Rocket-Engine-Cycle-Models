function [species,ne,Te,varargout] = nozzle_corrected(species,Tp,np,Pchamber,Q,mdot,Mm,Fro_Shift,typeexit,varargin)
% NOZZLE_CORRECTED  Nozzle expansion with corrected stagnation conditions.
%
% This function computes the nozzle exit state starting from a combustion
% chamber stagnation condition, accounting for a prescribed heat extraction
% (or loss) upstream of the nozzle.
%
% The total stagnation enthalpy is first corrected by subtracting the heat
% term Q. A corresponding corrected stagnation temperature is then obtained
% by inverting the HGS enthalpy relation at constant pressure.
%
% The nozzle expansion is finally evaluated using HGS, assuming either
% frozen or shifting chemistry and a prescribed exit condition.
%
% -------------------------------------------------------------------------
% INPUTS:
%   species    {cell}   Species list at chamber inlet
%   Tp         [K]      Chamber stagnation temperature
%   np         [mol/s]  Molar flow vector at chamber inlet
%   Pchamber   [Pa]     Chamber pressure
%   Q          [W]      Heat extracted from the flow (positive if removed)
%   Fro_Shift  {char}   Chemistry model: 'Frozen' or 'Shifting'
%   typeexit   {char}   Exit condition:
%                       'P' → exit pressure prescribed
%                       'M' → exit Mach number prescribed
%
%   varargin:
%     typeexit = 'P' → {Pexit [Pa], Pambient [Pa]}
%     typeexit = 'M' → {Me [-]}
%
% -------------------------------------------------------------------------
% OUTPUTS:
%   species    {cell}   Species list at nozzle exit
%   ne         [mol/s]  Exit molar flow vector
%   Te         [K]      Exit temperature
%
%   varargout:
%     typeexit = 'P' → {ve [m/s], Me [-], Ae [m^2], F [N], Isp [s]}
%     typeexit = 'M' → {Pe [Pa], flag}
% -------------------------------------------------------------------------

%% Pressure conversion (Pa → bar for HGS)
Pchamber_bar = Pchamber/1e5;

%% Chamber stagnation enthalpy (extensive, HGS convention)
H = HGSprop(species,np,Tp,Pchamber_bar,'H');   % [kJ/s]

%% Enthalpy correction due to heat extraction
% Q is provided in W and converted to kJ/s for consistency with HGS
% Hcorr = H - Q/1000;                            % [kJ/s]
delta_h0=-(Q/1000)/mdot; %[kJ/kg]
m_basis = sum(np) * (Mm/1000);  % [kg] if Mm_60 is g/mol
DeltaH_expected = delta_h0 * m_basis;     % [kJ]
Hcorr = H + DeltaH_expected;

%% Compute corrected stagnation temperature
% The corrected temperature is obtained by inverting the enthalpy relation
f = @(Tcorr) HGSprop(species,np,Tcorr,Pchamber_bar,'H') - Hcorr;
Tcorr = fzero(f, [200 6000]);

%% Nozzle expansion
switch typeexit

    case 'P'
        %--------------------------------------------------------------
        % Exit pressure prescribed
        %--------------------------------------------------------------
        if length(varargin) < 2
            error('In pressure mode: inputs must be Pexit, Pambient');
        end

        Pexit    = varargin{1};    % [Pa]
        Pambient = varargin{2};    % [Pa]

        Pexit_bar    = Pexit/1e5;      % [bar]
        Pambient_bar = Pambient/1e5;   % [bar]

        % Nozzle expansion with corrected stagnation temperature
        [species,ne,Te,ve,Me,Ae,F,Isp] = ...
            HGSnozzle(species,np,Tcorr,Pchamber_bar,...
                      Pexit_bar,Pambient_bar,Fro_Shift);

        Rg = HGSprop(species, ne, Te, Pexit_bar, 'Rg');   % [kJ/(kg·K)]
        rho_e = Pexit / (Rg * 1e3 * Te);                  % [kg/m^3]

        % Output assignment
        varargout{1} = ve;    % [m/s]
        varargout{2} = Me;    % [-]
        varargout{3} = Ae;    % [m^2]
        varargout{4} = F;     % [N]
        varargout{5} = Isp;   % [s]
        varargout{6} = rho_e;   % [kg/m^3]

    case 'M'
        %--------------------------------------------------------------
        % Exit Mach number prescribed
        %--------------------------------------------------------------
        if length(varargin) < 1
            error('In Mach mode: input must be Me');
        end

        Me = varargin{1};   % [-]

        % Isentropic expansion to prescribed Mach number
        [Te,species,ne,Pe,flag] = ...
            HGSisentropic(species,np,Tcorr,Pchamber_bar,...
                          Fro_Shift,typeexit,Me);

        if flag ~= 1
            error('HGSisentropic did not converge');
        end

        Rg = HGSprop(species, ne, Te, Pe, 'Rg');   % [kJ/(kg·K)]
        rho_e = Pe*1e5 / (Rg * 1e3 * Te);                  % [kg/m^3]
        
        % Outputs
        varargout{1} = Pe*1e5;   % [Pa]
        varargout{2} = flag;
        varargout{3} = rho_e;        % [kg/m^3]

end
