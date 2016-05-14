function alg = DRIVE_get_segmentation_algorithm
% Returns a function handle to the segmentation algorithm reported in the
% ARIA paper for DRIVE database images.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Threshold the darkest 15% of coefficients from wavelet levels 2 & 3 of
% the IUWT of IM.  Then remove objects < 75 pixels and fill holes > 20
% pixels.
alg = @(im, bw_mask) IUWT_segmentation_for_testing(im, 2:3, .15, 75, 20, true);