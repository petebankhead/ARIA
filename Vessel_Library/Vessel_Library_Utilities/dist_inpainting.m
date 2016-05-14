function [im2, bw2] = dist_inpainting(im, bw, se_erode)
% Fill in regions of an image outside the region corresponding to a binary
% mask by using the closest pixels within the mask, as determined by the
% distance transform BWDIST.
%
% Input:
%   IM - the image
%   BW - the binary mask, a logical array the same size as IM
%   ERODE - a structuring element to erode BW first.  This means
%   pixels slightly further from the mask boundary are used instead,
%   which may be necessary if the mask is inaccurate.
%
% Output:
%   IM2 - the modified image
%   BW2 - the actual mask that was used when identifying the closest
%   pixels, which might have been modified by an erosion
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Perform erosion if desired
if nargin >= 3
    bw2 = imerode(bw, se_erode);
else
    bw2 = bw;
end

% Do inpainting
im2 = im;
if verLessThan('images', '6.4')
    [im_dist, inds] = bwdist(bw2);
else
    [im_dist, inds] = bwdist_old(bw2);
end
im2(~bw) = im(inds(~bw));