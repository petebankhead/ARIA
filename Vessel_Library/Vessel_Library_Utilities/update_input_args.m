function args_out = update_input_args(args, args_default)
% Updates an input arguments structure, putting in default values where
% any are missing.
% 
% INPUT:
%   ARGS - a structure containing fields corresponding to function
%   arguments
%   ARGS_DEFAULT - a separate structure containing default values for the
%   required arguments
%
% OUTPUT:
%   ARGS_OUT - identical to ARGS if ARGS already contains all the
%   required arguments.  Otherwise, the missing values from ARGS_DEFAULT
%   will be added to ARGS_OUT.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% If no ARGS structure, use ARGS_DEFAULT
if ~isstruct(args)
    args_out = args_default;
    return;
end

% Set up output
args_out = args;

% Get field names of original arguments
fields_default = fieldnames(args_default);

% Identify the fields not already there
tf = isfield(args_out, fields_default);

% Add any that need added
if ~all(tf)
    for ii = find(~tf)'
        args_out.(fields_default{ii}) = args_default.(fields_default{ii});
    end
end