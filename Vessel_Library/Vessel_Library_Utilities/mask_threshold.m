function bw = mask_threshold(im, dark_threshold, bright_threshold, largest_region)
% Create a mask for the field of view (FOV) of an image, by including pixels
% above a low (dark) threshold and below a bright (high) threshold.
% Optionally, the largest single region only may be accepted.
%
% Input:
%   IM - the image to threshold
%   DARK_THRESHOLD and BRIGHT_THRESHOLD - pixels with values between these
%   two thresholds will be considered part of the FOV.
%   LARGEST_REGION - TRUE if the largest contiguous region should be
%   counted as the FOV.  FALSE if all regions meeting the threshold
%   criteria should be kept, irrespective of size.
% 
% Output:
%   BW - the binary mask, which will be the same size as IM
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Apply the thresholds
bw = im >= dark_threshold & im <= bright_threshold;
% Determine the single largest region
if largest_region
    bw = get_largest_region(bw);
end

% An old approach, which did something different.
% bw_dark = im < dark_threshold;
% bw_bright = im > bright_threshold;
% % Determine the single largest region
% if largest_region
%     bw_dark = get_largest_region(bw_dark);
%     bw_bright = get_largest_region(bw_bright);
% end
% % Store the binary mask image
% bw = ~(bw_dark | bw_bright);


% Get the largest region only
function bw_largest = get_largest_region(bw)
% Identify connected components
cc = bwconncomp(bw);
% Initialise output
bw_largest = false(size(bw));
% No regions found
if cc.NumObjects < 1
    return
end
% Set pixels in region to 'true'
areas = cellfun('size', cc.PixelIdxList, 1);
[m, m_ind] = max(areas);
bw_largest(cc.PixelIdxList{m_ind}) = true;