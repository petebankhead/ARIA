function ARIA_setup(temporary)
% Add the directory containing this file, and its sub-directories, to the
% MATLAB path.  If another ARIA.m is found somewhere on the MATLAB search
% path (i.e. another version of the software, or the same version stored
% elsewhere), it will be removed from the search path to avoid confusion.
% 
% Input:
%   TEMPORARY - TRUE if the path should not be saved (with a call to
%   SETPATH), but rather only set for the current session (Default =
%   FALSE).
% 
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Get the path of this file
pth = fileparts(mfilename('fullpath'));

% Check other versions of ARIA are somewhere on the search path, and remove
% them if so
arias = which('ARIA', '-all');
if ~isempty(arias)
    for ii = 1:numel(arias)
        arias_pth = fileparts(arias{ii});
        if ~isequal(arias_pth, pth)
            rmpath(genpath(arias_pth));
        end
    end
end

% Add to MATLAB path, along with subdirectories
addpath(genpath(pth));

% Save the path unless we only want this set up temporarily
if nargin < 1 || ~temporary
    savepath;
end