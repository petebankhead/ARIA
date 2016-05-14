function [threshold, data_sorted] = percentage_threshold(data, proportion, sorted)
% Determine a threshold so that (approx) proportion of data is above the 
% threshold.
% 
% Input:
%   DATA - the data from which the threshold should be computed
%   PROPORTION - the proportion of the data that should exceed the
%   threshold.  If > 1, it will first be divided by 100.
%   SORTED - TRUE if the data has already been sorted, FALSE otherwise
%
% Output:
%   THRESHOLD - either +Inf, -Inf or an actual value present in DATA.
%   DATA_SORTED - a sorted version of the data, that might be used later to
%   determine a different threshold.
%
% SEE ALSO PERCENTAGE_SEGMENT.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Need to make data a vector
if ~isvector(data)
    data = data(:);
end

% If not told whether data is sorted, need to check
if nargin < 3
    sorted = issorted(data);
end

% Sort data if necessary
if ~sorted
    data_sorted = sort(data);
else
    data_sorted = data;
end

% Calculate threshold value
if proportion > 1
    proportion = proportion / 100;
end
proportion = 1-proportion;
thresh_ind = round(proportion * numel(data_sorted));
if thresh_ind > numel(data_sorted)
    threshold = Inf;
elseif thresh_ind < 1
    threshold = -Inf;
else
    threshold = data_sorted(thresh_ind);
end