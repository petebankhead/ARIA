function [args, cancelled] = clean_short_vessels(vessel_data, args, prompt)
% Remove short vessel segments, and those for which valid measurements were
% not found.
%
% Required VESSEL_DATA properties: IM, VESSEL_LIST
%
% Required VESSEL properties: CENTRE, SIDE1, SIDE2
% 
% ARGS contents:
%   MIN_DIAMETERS - integer scalar giving the minimum number of diameters 
%   that must be in a vessel segment, otherwise it will be removed.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

%--------------------------------------------------------------------------

% Set up default input arguments in case none are available
args_default.min_diameters  = 1;

% Update arguments if possible
if nargin >= 2 && isstruct(args)
    args = update_input_args(args_default, args);
else
    args = args_default;
end

% Prompt user for input if necessary
cancelled = false;
if nargin < 3
    prompt = true;
end
if prompt
    % Ask for minimum vessel length
    answer = inputdlg(...
        'Minimum number of diameters per segment?  Must be an integer >= 1.',...
        'Remove short vessels', 1, {num2str(args.min_diameters)});
    if isempty(answer)
        cancelled = true;
        return;
    end
    input_val = round(str2double(answer));
    if ~isnan(input_val) && input_val > 0
        args.min_diameters = input_val;
    else
        warndlg(['Invalid input - last value of ', num2str(args.min_diameters),' will be used']);
    end
end

%--------------------------------------------------------------------------


% Apply cleaning to vessel list
% Apply even if args.min_diameters <= 1, because some vessels might have no
% valid diameters and should be removed
vessel_data.clean_vessel_list(args.min_diameters);