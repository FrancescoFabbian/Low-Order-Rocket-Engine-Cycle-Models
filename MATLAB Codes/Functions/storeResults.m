function [Position, number, Elements, pressure, temperature, density, massflow] = ...
    storeResults(Position, number, Elements, pressure, temperature, density, massflow, ...
                 pos_name, pos_number, species, p, T, rho, mdot)
% storeResults
%
% Utility function to store thermodynamic results at a given station of the
% rocket engine cycle. The function appends the data to the corresponding
% storage arrays, which can later be used to create tables or plots.
%
% -------------------------------------------------------------------------
% INPUTS:
% Position    : string array
%   Names of the engine stations (e.g. 'Tank', 'Pump', 'Turbine')
%
% number      : numeric array
%   Station numbers (e.g. 50, 45, 16)
%
% Elements    : string array
%   Chemical species present at each station
%
% pressure    : numeric array [Pa]
%   Pressure at each station
%
% temperature : numeric array [K]
%   Temperature at each station
%
% massflow    : numeric array [kg/s]
%   Mass flow rate at each station
%
% pos_name    : string
%   Name of the current station
%
% pos_number  : double
%   Number of the current station
%
% species     : string / char / cell array
%   Species present at the station
%
% p           : double [Pa]
%   Pressure at the station
%
% T           : double [K]
%   Temperature at the station
%
% mdot        : double [kg/s]
%   Mass flow rate at the station
%
% -------------------------------------------------------------------------
% OUTPUTS:
% Updated storage arrays
% -------------------------------------------------------------------------

%% Store position name and number
Position(end+1) = pos_name;
number(end+1)   = pos_number;

%% Ensure species is stored as a string
if ischar(species)
    species_cell = {species};
elseif isstring(species)
    species_cell = cellstr(species);
else
    species_cell = species; % already a cell array
end

Elements(end+1) = string(strjoin(species_cell, ", "));

%% Store thermodynamic quantities
pressure(end+1)    = p;
temperature(end+1) = T;
density(end+1)     = rho;
massflow(end+1)    = mdot;

end
