function cw_table = write_table_to_command_window(table, draw_rows, draw_cols)
% Print a results table, stored in the form of a cell array, to the command
% window.  The cell array should contain scalars or strings only.
% This function makes cell arrays presentable, at least when one is using a
% monospaced font.  If the cell array contains any numerical data, it is
% converted using NUM2STR.
% 
% Input:
%   TABLE - a cell array containing strings or scalars.
%   DRAW_ROWS - a vector giving the locations where horizontal lines should
%   be added to the table.  These are inserted after the rows
%   TABLE(DRAW_ROWS, :); therefore, 0 should be included to add a row at
%   the top.
%   DRAW_COLS - the locations where vertical lines should be added to the
%   table.  These are added after the entries TABLE(:, DRAW_COLS).  To add
%   the first column, this should include zero.
%   
% Output:
%   CW_TABLE - the character array that can be displayed using the DISP
%   command.  If the output is returned, the function does not display the
%   array itself.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


%% INPUT CHECKING

% By default don't draw any rows or columns - but if any are needed, make
% sure we only have valid row and column vectors
if nargin < 2
    draw_rows = [];
else
    draw_rows = unique(draw_rows(draw_rows >= 0 & draw_rows <= size(table, 1)));
end
if nargin < 3
    draw_cols = [];
else
    draw_cols = unique(draw_cols(draw_cols >= 0 & draw_cols <= size(table, 2)));
end

% Ensure that the table contains only text, and throw an error if we have
% non-scalar numeric data
for ii=1:numel(table)
    val = table{ii};
    if isnumeric(val)
        if ~(isscalar(val) || isempty(val))
            error('Non-scalar numeric data in TABLE is not supported!');
        end
        table{ii} = num2str(val);
    end;
end;


%% CREATE THE TABLE

% Create the first column - which may be a line, or nothing
if ismember(0, draw_cols)
    col_1 = '| ';
else
    col_1 = '';
end
cw_table = repmat(col_1, size(table, 1), 1);

% Loop through columns, making a nice big character array and adding column
% separators where needed
for jj = 1:size(table, 2)
    % Extract the column as a 2D character array - CHAR will pad as needed
    col = char(table{:, jj});
    % Check whether we need a line separator here, or just a space
    if ismember(jj, draw_cols)
        if jj == size(table, 2)
            % Don't need a space after the very last column
            sep = ' |';
        else
            sep = ' | ';
        end
    else
        sep = '  ';
    end
    % Add the column to the table, followed by the appropriate separator
    cw_table = cat(2, cw_table, col, repmat(sep, size(table, 1), 1));
end
% Now add rows where necessary
if ~isempty(draw_rows)
    cw_table2 = char(zeros(size(cw_table) + [numel(draw_rows), 0], 'uint8'));
    row_inds = draw_rows(:)' + (1:numel(draw_rows));
    table_inds = setxor(row_inds, 1:size(cw_table2, 1));
    cw_table2(row_inds, :) = '-';
    cw_table2(table_inds, :) = cw_table;
    cw_table = cw_table2;
end

% Display the result if we are not returning it
if nargout == 0
    disp(cw_table);
end