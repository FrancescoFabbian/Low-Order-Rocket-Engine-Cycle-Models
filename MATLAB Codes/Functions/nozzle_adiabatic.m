function [species,ne,Te,varargout] = nozzle_adiabatic(species,Tp,np,Pchamber,Fro_Shift,typeexit,varargin)
% NOZZLE_ADIABATIC  Unified adiabatic nozzle wrapper for HGS nozzle solvers.
%
% This function provides a single interface to two different HGS nozzle models:
%   • HGSnozzle     → full nozzle solution with thrust and Isp (pressure-defined exit)
%   • HGSisentropic → isentropic expansion to a specified Mach number
%
% The nozzle is assumed to be:
%   - Adiabatic (no heat transfer)
%   - Steady-state
%   - One-dimensional
%   - Inviscid (losses neglected)
%
% Chemical composition treatment is controlled by Fro_Shift:
%   • 'Frozen'   → composition fixed during expansion
%   • 'Shifting' → chemical equilibrium enforced along the nozzle
%
% -------------------------------------------------------------------------
% INPUTS:
%   species    : cell array of species names (HGS format)
%   Tp         : chamber (stagnation) temperature [K]
%   np         : molar flow vector at chamber [mol or mol/s]
%   Pchamber   : chamber pressure [Pa]
%   Fro_Shift  : composition model:
%                  'Frozen'   → frozen chemistry
%                  'Shifting' → equilibrium chemistry
%   typeexit   : exit condition specification:
%                  'P' → exit pressure is prescribed
%                  'M' → exit Mach number is prescribed
%
%   varargin   : additional inputs depending on typeexit
%       If typeexit = 'P':
%           varargin{1} = Pexit     : nozzle exit pressure [Pa]
%           varargin{2} = Pambient  : ambient pressure (for thrust calc) [Pa]
%
%       If typeexit = 'M':
%           varargin{1} = Me        : exit Mach number [-]
%
% -------------------------------------------------------------------------
% OUTPUTS:
%   species : species list at nozzle exit
%   ne      : molar flow vector at exit (composition may change if 'Shifting')
%   Te      : exit temperature [K]
%
%   varargout (depends on typeexit):
%
%   typeexit = 'P':
%       varargout{1} = ve   : exit velocity [m/s]
%       varargout{2} = Me   : exit Mach number [-]
%       varargout{3} = Ae   : exit area [m^2]
%       varargout{4} = F    : thrust [N]
%       varargout{5} = Isp  : specific impulse [s]
%
%   typeexit = 'M':
%       varargout{1} = Pe   : exit pressure [Pa]
%       varargout{2} = flag : convergence flag from HGSisentropic
%
% -------------------------------------------------------------------------
% NOTES:
%   • Pressure units are internally converted to bar (HGS convention)
%   • Molar flows are conserved (no mass addition/removal)
%   • Nozzle choking behavior is handled internally by HGS routines
% -------------------------------------------------------------------------

Pchamber_bar=Pchamber/1e5;

switch typeexit
    case 'P'
        if length(varargin) < 2
            error('In pressure mode: inputs must be Pexit, Pambient');
        end

        Pexit=varargin{1}; %[Pa]
        Pambient=varargin{2}; %[Pa]

        Pexit_bar=Pexit/1e5; %[bar]
        Pambient_bar=Pambient/1e5; %[bar]

        [species,ne,Te,ve,Me,Ae,F,Isp] = HGSnozzle(species,np,Tp,Pchamber_bar,Pexit_bar,Pambient_bar,Fro_Shift);

        Rg = HGSprop(species, ne, Te, Pexit_bar, 'Rg');   % [kJ/(kg·K)]
        rho_e = Pexit / (Rg * 1e3 * Te);                  % [kg/m^3]

        %Build output structure
        varargout{1} = ve;      %[m/s]
        varargout{2} = Me;      %[-]
        varargout{3} = Ae;      %[m^2]
        varargout{4} = F;       %[N]
        varargout{5} = Isp;     %[s]
        varargout{6} = rho_e;   % [kg/m^3]

    case 'M'
        if length(varargin) < 1
            error('In Mach mode: inputs must be Me');
        end
        Me = varargin{1}; %[-]

        [Te,species,ne,Pe,flag] = HGSisentropic(species,np,Tp,Pchamber_bar,Fro_Shift,typeexit,Me);
        if flag ~=1
            error('Flag should be 1')
        end

        Rg = HGSprop(species, ne, Te, Pe, 'Rg');   % [kJ/(kg·K)]
        rho_e = Pe*1e5 / (Rg * 1e3 * Te);                  % [kg/m^3]

        % Outputs
        varargout{1} = Pe*1e5;   % [Pa]
        varargout{2} = flag;
        varargout{3} = rho_e;        % [kg/m^3]

end            
