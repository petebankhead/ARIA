function el = root_sum_of_squares(x, dim)
% Calculate the square root of the sum of squares of an array along a 
% specified dimension (DIM = 2 by default).
% 
% For an array that is the difference between two coordinate arrays, this
% can be used to get the Euclidean distance between the two original
% coordinates.
%
% Input:
%   X - the data array
%   DIM - the desired dimension along which to compute
%
% Output:
%   EL - the root sum of squares
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

if nargin < 2
    dim = 2;
end
el = realsqrt(sum(x.^2, dim));