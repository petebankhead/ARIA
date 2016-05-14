function save_vessel_processor(f_name, args, fun)
% Save a vessel image processing function and its required arguments in a
% file.  The function should take a VESSEL_DATA object, initialized with
% its IMAGE property set, and complete all the remaining analysis steps
% (e.g. mask creation, vessel detection & measurement) until all the
% properties of the VESSEL_DATA are set.
%
% The resulting file is called a 'vessel_processor' (and has this as a 
% somewhat unwieldy file extension).
% 
% Input:
%   F_NAME - the file name for saving (a string).
%   ARGS - a structure containing all the required arguments.
%   FUN  - a string containing the name of the function that should be
%   called to do the processing.
% 
% See also LOAD_VESSEL_PROCESSOR
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Too few arguments, don't do anything
if nargin < 2
    error('Too few arguments to SAVE_VESSEL_PROCESSOR');
end

% Check correct extension is on F_NAME, otherwise append it
ext = '.vessel_processor';
if numel(f_name) < numel(ext) || ~strcmp(f_name(end-numel(ext)+1:end), ext)
    f_name = [f_name, ext];
end

% Check ARGS and FUN
if ~isstruct(args)
    error('Invalid vessel processor arguments - should be a STRUCT');
end

% Add the processor function if it has been given separately
if nargin >= 3 && ~isempty(fun)
    if ~ischar(fun)
        error('Invalid vessel processor function - should be a string');
    else
        args.processor_function = fun;
    end
end

% The path is the same as this mfile
f_path = fileparts(mfilename('fullpath'));

% Save the processor
save(fullfile(f_path, f_name), 'args');