function state = state_checkNEW(p_in, T_in, species, n)

% STATE_CHECK
% Determines thermodynamic regime.
%
% Single species  → NFP-based phase check
% Multiple species → HGS-based regime check (ideal gas validity)
%
% INPUTS:
%   p_in    [Pa]
%   T_in    [K]
%   species char or cell array
%   n       molar vector (required for mixtures)
%
% OUTPUT:
%   state   descriptive string

Pbar = p_in / 1e5;   % [bar]

%% ------------------------------------------------------------------------
% CASE 1 — SINGLE SPECIES (NFP)
% ------------------------------------------------------------------------
if ischar(species) || (iscell(species) && numel(species) == 1)

    if iscell(species)
        species = species{1};
    end

    Pcrit = NFP(species,'pcrit');   % [bar]
    Tcrit = NFP(species,'tcrit');   % [K]

    if isempty(Pcrit) || isempty(Tcrit) || isnan(Pcrit) || isnan(Tcrit)
        state = 'Critical properties unavailable from NFP';
        return;
    end

    if Pbar >= Pcrit
        if T_in >= Tcrit
            state = sprintf('%s is supercritical (T>Tc, P>Pc)', species);
        else
            state = sprintf('%s is compressed liquid (P>Pc, T<Tc)', species);
        end
    else
        tsat = NFP(species,'tsat_p',Pbar);

        if isempty(tsat) || isnan(tsat)
            state = 'Saturation temperature unavailable from NFP';
            return;
        end

        if T_in > tsat
            state = sprintf('%s is gaseous (superheated)', species);
        elseif T_in == tsat
            state = sprintf('%s is two-phase', species);
        else 
            state = sprintf('%s is in liquid form', species);

        end
    end

    return;
end

%% ------------------------------------------------------------------------
% CASE 2 — MULTI-SPECIES MIXTURE (HGS)
% ------------------------------------------------------------------------
if nargin < 4 || isempty(n)
    state = 'Mixture detected but molar vector n not provided';
    return;
end

% Reduced temperature check for ideal-gas validity
% (HGS assumes ideal gas always)
if T_in > 300
    state = 'Gas mixture (HGS): high-temperature ideal-gas regime';
else
    state = 'Gas mixture (HGS): low temperature, validity questionable';
end

end