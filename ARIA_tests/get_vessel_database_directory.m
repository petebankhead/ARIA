function dir_database = get_vessel_database_directory(database_name, prompt)
% Get a previously stored directory for DRIVE or REVIEW databases.
% If no directory is found, or it is incorrect, then prompt the user to
% select the right directory.
% 
% This really exists to avoid needing prompts every time one wants to run
% the algorithm tests, or to hard-code them.
%
% Input:
%   DATABASE_NAME - should be a string, either 'DRIVE' or 'REVIEW'
%   PROMPT - TRUE if the user should be prompted to select the directory
%   path, irrespective of whether a previous path is available
%
% Output:
%   DIR_DATABASE - the directory containing the database images, as chosen
%   by the user or previously set.  If available, it will be a string
%   ending with a file separator.  If not, an empty array is returned.
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Check got an input
if nargin < 1
    error('Must specify a database name!  Should be either DRIVE or REVIEW.');
end

% Check a valid database is sought
database_name = upper(database_name);
if ~strcmp(database_name, 'REVIEW') && ~strcmp(database_name, 'DRIVE')
    error('Unknown database name!  Should be either DRIVE or REVIEW.');
end

% Get the directory containing this M file, and use it for caching the
% directories
dir_paths = [fileparts(mfilename('fullpath')), filesep];

% See if a previous directory path has been stored, and load it if so
dir_database = '';
file_name_cache = [dir_paths, 'database_directory_', database_name, '.mat'];
if exist(file_name_cache, 'file')
    load(file_name_cache, 'dir_database');
end

% If no directory is found, or a prompt is desired, prompt for it
if (nargin >= 2 && prompt) || (isempty(dir_database) || ~exist(dir_database, 'dir'))
    dir_database = uigetdir(dir_database, ['Choose the base directory for ', database_name, ' images']);
    % If nothing was selected, return an empty array
    if dir_database == 0
        dir_database = [];
        return;
    end
    % Make sure there is a file separator at the end
    if dir_database(end) ~= filesep
        dir_database = [dir_database, filesep];
    end
    % Store the directory name, or return an empty array if nothing
    % selected
    save(file_name_cache, 'dir_database');
end