function table = REVIEW_create_results_table(results)
% Create a cell array summarizing the results of evaluating diameters using
% an ARIA algorithm and one or more image sets from the REVIEW database.
% 
% Input:
%   RESULTS - a STRUCT output from REVIEW_EVALUATE_DIAMETER_MEASUREMENTS.
%   This may also be an array of STRUCT if multiple image sets should be
%   included in the table.
%
% Ouput:
%   TABLE - a cell array containing a summary of the main entries in
%   RESULTS, including column and row headers.
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Check the RESULTS look ok
if ~isstruct(results)
    error('RESULTS should be an array of STRUCT output by REVIEW_TEST_PROCESSOR');
end

% Preallocate the table
table = cell(7, 1 + numel(results) * 3);

% Set up the row headings
table{2, 1} = 'Method';
table{3, 1} = 'Ground truth';
table{4, 1} = 'Observer 1';
table{5, 1} = 'Observer 2';
table{6, 1} = 'Observer 3';
table{7, 1} = 'Algorithm';

% Loop through the results
entries = {'true', 'observer1', 'observer2', 'observer3', 'algorithm'};
for ii = 1:numel(results)
    off = 2 + 3 * (ii - 1);
    % Set up the column headings
    table{1, off+1} = results(ii).image_set;
    table{2, off} = 'Success %';
    table{2, off+1} = 'Mean';
    table{2, off+2} = 'Diff. sd';
    % Add the entries
    for jj = 1:numel(entries)
        table{2+jj, off} = results(ii).(entries{jj}).success_rate;
        table{2+jj, off+1} = results(ii).(entries{jj}).diameters_mean;
        table{2+jj, off+2} = results(ii).(entries{jj}).difference_std;
    end
end