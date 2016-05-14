function write_table_to_file(file, table, delimiter)
% Print a results table, stored in the form of a cell array, to a file.
% The cell array should have at most 2 dimensions, and contain scalars or
% strings only.  The file will be tab-delimited, or using the delimiter
% given as input.
% 
% Input:
%   FILE - either a string denoting a file name (any existing file will be
%   overwritten), or a file id to an existing file opened by FOPEN.  If
%   this is missing, the output will be given to the command window.
%   TABLE - a cell array
%   DELIMITER - (optional) the delimiter to use when separating columns.
%   Setting this to ' & ' or '\t&\t' makes it easier to copy the results
%   into a LaTeX table.  (Default = '\t')
%   
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


%% INPUT CHECKING

close_file = false;
if nargin >= 1 && ischar(file)
    fid = fopen(file, 'w');
    close_file = true;
elseif nargin >= 1 && isnumeric(file) && ~isempty(fopen(file))
    fid = file;
else
    % Write to command window by default
    fid = 1;
end
if ~iscell(table) || ndims(table) > 2
    error('TABLE must be a 2D cell array.');
end
if nargin < 3 || isempty(delimieter)
    % Use a tab delimiter by default
    delimiter = '\t';
elseif ~ischar(delimiter)
    error('DELIMITER should be a character or string');
end


%% WRITE THE TABLE

% Loop through the entries in the table
for ii = 1:size(table, 1)
    for jj = 1:size(table, 2)
        % Write the entry to the table (converting to text if necessary)
        val = table{ii, jj};
        if isnumeric(val)
            val = num2str(val);
        end
        fprintf(fid, val);
        % Only add a delimiter if not at the end of the row
        if jj < size(table, 2)
            fprintf(fid, delimiter);
        end
    end
    fprintf(fid, '\n');
end


%% EXTRA CLEANUP
if close_file
    fclose(fid);
end