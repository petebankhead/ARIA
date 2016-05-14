function vessels = make_image_profiles(vessels, im, width, method, bw_mask)
% Compute the profiles perpendicular to the centreline for an array of
% VESSELs, and store these along with the row and column coordinates for
% each pixel in the profiles.
%
% Input:
%   VESSELS - the array of VESSEL objects
%   IM - the image from which the profiles are computed
%   WIDTH - a scalar giving the length of each profile, in pixels
%   METHOD - the method of interpolation used when computing the profiles,
%   as defined in INTERP2 (Default = '*linear')
%   BW_MASK - a logical mask that may be applied to the image prior to
%   computing the profiles.  If IM is logical, then values not in BW_MASK
%   will be set to FALSE, otherwise they will be set to NaN.  BW_MASK must
%   be the same size as IM.
%
% Output:
%   VESSELS - the same as the input VESSELS, but with profile-related
%   properties set.
%
% 
% Required VESSEL properties: IM, CENTRE, ANGLES
%
% Set VESSEL properties: IM_PROFILES, IM_PROFILES_ROWS, IM_PROFILES_COLS
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% This code looks more complicated than strictly necessary because INTERP2
% is relatively slow, and it is much faster to pass all co-ordinates for
% interpolation to it in one go than to use it to calculate image
% profiles for each vessel in turn.



% Use linear interpolation by default
if nargin < 4 || isempty(method)
    method = '*linear';
end

% Don't use a mask by default
if nargin < 5
    bw_mask = [];
elseif ~isequal(size(bw_mask), size(im)) || ~islogical(bw_mask)
    warning('MAKE_IMAGE_PROFILES:MASK_SIZE', 'BW_MASK must be a logical array the same size as IM; no mask will be applied.');
    bw_mask = [];
end

% Test whether image is valid
if isempty(im) || ndims(im) ~= 2
    return;
end

% Get the number of centre points for each vessel segment, then extract all
% the centres and angles into single numeric arrays
% n_rows = cellfun('size', centre, 1);
vessels = vessels(:);
centre = cat(1, vessels.centre);
angles = cat(1, vessels.angles);

% Determine co-ordinates for interpolation
inc = (0:width-1) - (width-1)/2;
angles = single(angles);
inc = single(inc);
im_profiles_rows = bsxfun(@plus, centre(:,1), bsxfun(@times, angles(:,1), inc));
im_profiles_cols = bsxfun(@plus, centre(:,2), bsxfun(@times, angles(:,2), inc));

% Generate image profiles, stacked together as a single image
if islogical(im) && ~isempty(strfind('nearest', method))
    % If image is binary and using nearest-neighbour interpolation, give binary output
    im(~bw_mask) = false;
    all_profiles = interp2(im, im_profiles_cols, im_profiles_rows, method, 0);
else
    if ~isfloat(im)
        % If image isn't already floating point, just use single precision
        im = single(im);
    end
    % Set anything outside the mask to NaN
    im(~bw_mask) = NaN;
    % Compute the profiles
    all_profiles = interp2(im, im_profiles_cols, im_profiles_rows, method);
    
%     % If NaNs should be replaced with the nearest valid value, you could
%     % start with this (though it's not entirely robust if the NaNs aren't
%     % at the edge of the profiles)
%     bw_nans = isnan(all_profiles);
%     if any(bw_nans(:))
%         all_profiles2 = all_profiles;
%         all_profiles(bw_nans) = 0;
%         all_profiles2(bw_nans) = Inf;
%         all_profiles = imreconstruct(all_profiles, all_profiles2, [0 0 0; 1 1 1; 0 0 0]);
%     end
end

% Loop through the vessels and assign the properties
current_ind = 1;
for ii = 1:numel(vessels)
    n_rows = size(vessels(ii).centre, 1);
    rows = current_ind:current_ind + n_rows - 1;
    vessels(ii).im_profiles = all_profiles(rows, :);
    vessels(ii).im_profiles_rows = im_profiles_rows(rows, :);
    vessels(ii).im_profiles_cols = im_profiles_cols(rows, :);
    current_ind = current_ind + n_rows;
end


% % In this old version, adjacent profiles could be averaged in a fast way.
% if smoothing > 1
%     % Do the filtering
%     all_profiles = smooth_image_profiles(all_profiles, n_rows, smoothing);
% end
% 
% 
% function all_profiles = smooth_image_profiles(all_profiles, n_rows, av)
% % Smooth adjacent image profiles, which are all stored stacked togerher in
% % one (possibly very long) 2D matrix.
% %
% % Input:
% %   ALL_PROFILES is a single large matrix, as output from MAKE_IMAGE_PROFILES.
% %   N_ROWS should be a vector that gives the number of rows of ALL_PROFILES
% %   that correspond to profiles across each vessel.
% %   Replication is used to deal with boundaries.
% %   AV should be an integer, preferably an odd number, giving the number of
% %   profiles to average.
% %
% % Output:
% %   ALL_PROFILES is the smoothed form of the input.
% %
% % Copyright © 2011 Peter Bankhead.
% % See the file : Copyright.m for further details.
% 
% % Nothing to do
% if nargin < 3 || isempty(av) || av == 1
%     return;
% end
% 
% % Create a larger matrix that uses replication where appropriate so that
% % a single filtering operation won't merge between vessels
% pad = floor(av/2);
% n_rows = n_rows(:)';
% start_rows = cumsum([1, n_rows(1:end-1)]);
% end_rows = cumsum(n_rows);
% row_inds = [1:size(all_profiles,1), repmat(start_rows, 1, pad), repmat(end_rows, 1, pad)];
% [row_inds, s_inds] = sort(row_inds);
% % Create profiles matrix after replication
% all_profiles2 = all_profiles(row_inds, :);
% % Apply filtering
% all_profiles2 = imfilter(all_profiles2, ones(av,1)/av);
% 
% % Need to get rid of the extra rows, so create an logical vector TRUE in
% % rows that should be kept
% keep_rows = true(size(all_profiles2, 1), 1);
% % Those at the end need to go
% keep_rows([1:pad, end-pad+1:end]) = false;
% % Each group, 2*pad in length, between vessels need to be removed.
% % Work out their locations from the last valid index for each vessel.
% end_rows2 = end_rows(1:end-1) + pad + pad * 2 * (0:numel(end_rows)-2);
% temp = bsxfun(@plus, end_rows2(:), 1:pad*2);
% keep_rows(temp(:)) = false;
% 
% % Using the second output of SORT, get rid of all the extra rows
% % keep_rows = s_inds <= size(all_profiles,1);
% all_profiles = all_profiles2(keep_rows, :);