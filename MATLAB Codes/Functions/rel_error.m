function varargout = rel_error(T_computed, P_computed, rho_computed, T_real, p_real, rho_real, varargin)
%REL_ERROR  Computes relative errors between computed and reference values.
%
% Mandatory inputs:
%   T_computed   [K]      Computed temperature
%   P_computed   [Pa]     Computed pressure
%   rho_computed [kg/m^3] Computed density
%   T_real       [K]      Reference temperature
%   p_real       [Pa]     Reference pressure
%   rho_real     [kg/m^3] Reference density
%
% Optional inputs (pass both, or none):
%   Q_eff   [W]   Computed/effective heat transfer rate
%   Q_real  [W]   Reference/real heat transfer rate
%
% Outputs:
%   If called with 3 outputs:
%       [error_T, error_p, error_rho]
%   If called with 4 outputs and optional Q provided:
%       [error_T, error_p, error_rho, error_Q]
%
% Relative error definition:
%   error_X = (X_computed - X_real) / X_real

% --- Always compute the base errors
error_T   = (T_computed   - T_real)   ./ T_real;
error_p   = (P_computed   - p_real)   ./ p_real;
error_rho = (rho_computed - rho_real) ./ rho_real;

% --- Optional Q error
if ~isempty(varargin)
    if numel(varargin) ~= 2
        error('If you provide optional inputs, you must pass both Q_eff and Q_real.');
    end
    Q_eff  = varargin{1};
    Q_real = varargin{2};
    error_Q = (Q_eff - Q_real) ./ Q_real;
end

% --- Manage outputs based on how many are requested
switch nargout
    case 1
        % Return a struct if user requests a single output
        out.error_T   = error_T;
        out.error_p   = error_p;
        out.error_rho = error_rho;
        if exist('error_Q','var')
            out.error_Q = error_Q;
        end
        varargout{1} = out;

    case 3
        varargout{1} = error_T;
        varargout{2} = error_p;
        varargout{3} = error_rho;

    case 4
        if ~exist('error_Q','var')
            error('To get error_Q you must pass Q_eff and Q_real as optional inputs.');
        end
        varargout{1} = error_T;
        varargout{2} = error_p;
        varargout{3} = error_rho;
        varargout{4} = error_Q;

    otherwise
        error('Invalid number of outputs. Use 1 (struct), 3, or 4 outputs.');
end

end
