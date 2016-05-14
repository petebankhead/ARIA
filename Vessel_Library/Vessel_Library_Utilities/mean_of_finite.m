function m = mean_of_finite(x, dim)
% Compute the mean of all elements in an array X along dimension DIM,
% ignoring any non-finite values (i.e. NaN, Inf, -Inf).
%
% Input:
%   X - the original data
%   DIM - the dimension along which to calculate the mean (default is the
%   first non-singleton dimension)
%
% Output:
%   M - the mean of X along dimension DIM, ignoring non-finite values
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Determine default dimension
if nargin == 1 || isempty(dim)
    dim = find(size(x) ~= 1, 1, 'first');
    if isempty(dim)
        dim = 1;
    end
end
% Determine where the valid values are to be found
valid = isfinite(x);
% Set all invalid values to 0
x(~valid) = 0;
% Compute the mean
m = sum(x, dim) ./ sum(valid, dim);