function [args, fun] = load_vessel_processor(f_name)
% Load an arguments structure for a saved vessel analysis processor from a
% file.  Also extracts the relevant function name
% to which the arguments should be passed, if available.
% 
% Input:
%   F_NAME - the file name (a string).
% 
% Output:
%   ARGS - the full arguments structure.
%   FUN - the processor function name.
% 
% See also SAVE_VESSEL_PROCESSOR
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Check correct extension is on F_NAME
ext = '.vessel_processor';
if numel(f_name) < numel(ext) || ~strcmp(f_name(end-numel(ext)+1:end), ext)
    f_name = [f_name, ext];
end

% Initalise output
fun = [];
args = [];

% Load function name and arguments from file, if available
if exist(f_name, 'file')
    s = load(f_name, 'args', '-mat');
    if isfield(s, 'args')
        args = s.args;
        if isfield(args, 'processor_function')
            fun = args.processor_function;
        end
    end
end