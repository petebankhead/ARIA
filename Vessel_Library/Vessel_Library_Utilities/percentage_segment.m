function [bw, sorted_pix] = percentage_segment(im, proportion, dark, bw_mask, sorted_pix)
% Threshold an image to find a proportion of the darkest or brightest
% pixels.
%
% Input:
%   IM - the image to threshold.
%   PROPORTION - the proportion of pixels to include.  It should be a value
%   between 0 and 1.
%   DARK - TRUE if the lowest PERCENT pixels will be kept, otherwise
%   the highest will be kept.
%   BW_MASK (optional) - a binary image corresponding to IM that gives the
%   field of view to use.  If absent, the entire image is used.
%   SORTED_PIX - an array containing the pixels to use for computing the
%   threshold.  Sorting large numbers of pixels can be somewhat slow, so
%   this can speed up repeated calls to the function to test different
%   thresholds.
%
% Output:
%   BW - the binary image produced by thresholding
%   SORTED_PIX - the sorted list of pixels from which the threshold was
%   calculated
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Sort pixels in image, if a sorted array is not already available
if nargin < 5 || isempty(sorted_pix)
    if ~isempty(bw_mask)
        sorted_pix = sort(im(bw_mask(:)));
    else
        sorted_pix = sort(im(:));
    end
end

% Convert to a proportion if we appear to have got a percentage
if proportion > 1
    proportion = proportion / 100;
    warning('PERCENTAGE_SEGMENT:THRESHOLD', 'The threshold exceeds 1; it will be divided by 100.');
end

% Invert PERCENT if DARK
if dark
    proportion = 1 - proportion;
end

% Get threshold
[threshold, sorted_pix] = percentage_threshold(sorted_pix, proportion, true);

% Threshold to get darkest or lightest objects
if dark
    bw = im <= threshold;
else
    bw = im > threshold;
end

% Apply mask
if ~isempty(bw_mask)
    bw = bw & bw_mask;
end