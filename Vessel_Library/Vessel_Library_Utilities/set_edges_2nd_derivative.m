function vessels = set_edges_2nd_derivative(vessels, bw, bw_mask, smooth_scale_parallel, smooth_scale_perpendicular, enforce_connectedness)
% Compute the coordinates of vessel edges from image profiles.
% The edges of each vessel are provisionally identified from averaged
% profiles computed along the length of the vessel, based upon the maximum
% gradient magnitude to either size of the centreline and within the
% vincinity of the relevant vessel edges depicted in the binary image in
% which the vessels were first detected.
% 
% Based upon the distance between these estimated edges, an anisotropic
% Gaussian filter is applied.  By working with stacked profiles
% perpendicular to the vessel, the filter can effectively be oriented
% parallel to it.
% An approximate of the 2nd derivative is then computed perpendicular to
% the vessel and its zero-crossings are used to more precisely locate each
% edges, this time guided by the mean edge locations previously identified
% from the maximum gradient.
% 
% 
% Input:
%   VESSELS - an array of VESSEL objects, each containing IM_PROFILES,
%   IM_PROFILES_COLS, IM_PROFILES_ROWS and CENTRE properties.
%   BW - a binary image in which vessels are segmented
%   BW_MASK - (optional) a binary image, the same size as BW, giving the
%   field of view
%   SMOOTH_PARALLEL and SMOOTH_PERPENDICULAR are scaling parameters that
%   multiply the mean width estimate for the vessel under consideration to
%   determine how much smoothing is applied.  SMOOTH_PARALLEL/PERPENDICULAR
%   is multiplied by the width, and the square root of the result gives the
%   sigma for the Gaussian filter.  Although not essential,
%   SMOOTH_SCALE_PERPENDICULAR should be >= SMOOTH_SCALE_PARALLEL (Default
%   SMOOTH_PARALLEL = 1, SMOOTH_SCALE_PERPENDICULAR = 0.1).
%   ENFORCE_CONNECTEDNESS - TRUE if all pixels along the vessel edge should
%   be connected to one another, i.e. within a distance of approximately
%   one pixel from one another, FALSE otherwise.  Setting this to TRUE can
%   improve the results by reducing the risk that the edges of neighbouring
%   structures or the central light reflex are erroneously linked to the
%   vessel, but in some images it might cause even vessels that appear
%   clearly visible to be missed because their edge (as determined by the
%   algorithm) is too variable or fragmented (Default = TRUE).
%
% Output:
%   VESSELS here is the same as the input, but now with SIDE1 and SIDE2
%   properties set.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


if nargin < 4 || isempty(smooth_scale_parallel)
    smooth_scale_parallel = 1;
end
if nargin < 5 || isempty(smooth_scale_perpendicular)
    smooth_scale_perpendicular = 0.1;
end
if nargin < 6 || isempty(enforce_connectedness)
    enforce_connectedness = true;
end


% Generate mask regions
[vessel_regions, mask_regions] = create_vessel_profile_masks(vessels, bw, bw_mask);


% Loop through the vessels
for ii = 1:numel(vessels)
    
    % Create the default (NaN) side coordinates
    vessels(ii).side1 = nan(size(vessels(ii).centre));
    vessels(ii).side2 = vessels(ii).side1;
    
    % Extract the profiles and coordinates
    im_profiles = vessels(ii).im_profiles;
    im_profiles_cols = vessels(ii).im_profiles_cols;
    im_profiles_rows = vessels(ii).im_profiles_rows;
    n_profiles = size(im_profiles, 1);
    
    % Check whether working with a dark or light vessel, and invert the
    % profile to make it 'hill-like' if necessary
    dark_vessels = vessels(ii).dark;
    if dark_vessels
        im_profiles = -im_profiles;
    end
    
    % Identify the central column
    c = ceil(size(im_profiles, 2)/2);
        
    % Estimate the mean vessel width, and ensure it isn't too big for the
    % profile size (although this shouldn't actually ever occur, presuming 
    % the prior steps have ensured the profile was a sensible length)
    bw_vessel_profiles = vessel_regions{ii};
    % Take the median of the sum of the segmented pixels perpendicular to
    % the vessel as the width estimate
    binary_sums = sum(bw_vessel_profiles, 2);
    width_est = median(binary_sums(bw_vessel_profiles(:, c)));
%     width_est = nnz(bw_vessel_profiles) / sum(bw_vessel_profiles(:, c));
    if width_est > c-1
        width_est = c-1;
    elseif ~isfinite(width_est)
        % If we couldn't get an estimate, we cannot measure the vessel
        % (although this should not happen if the centreline is close to
        % being in the right place of an actual vessel)
        continue
    end
    
    % Get the region mask
    bw_regions = mask_regions{ii};
    
    % Compute a mean profile for the entire vessel, omitting pixels closer
    % to other vessels
    im_profiles_closest = im_profiles;
    im_profiles_closest(~bw_regions) = NaN;
    prof_mean = mean_of_finite(im_profiles_closest, 1);
    
    % Find the maximum gradients to either side of the centre, within a
    % boundary of one estimated diameter to either side.  These are the
    % initial edge estimates for the entire vessel.
    [l_mean_col, r_mean_col] = find_maximum_gradient_columns(prof_mean, width_est);
    
    % Update the vessel width estimate as the distance between the two sides
    width_est = r_mean_col - l_mean_col;
    
    % Make sure we have a width estimate, otherwise we can't do anything more
    if ~isfinite(width_est)
        continue;
    end
        
    % Create 1D Gaussian filters for smoothing parallel and perpendicular to the vessel
    % Sigma values are based on the square root of the scaled width
    % estimates
    gv = gaussian_filt_1d_sigma(sqrt(width_est * smooth_scale_parallel));
    gh = gaussian_filt_1d_sigma(sqrt(width_est * smooth_scale_perpendicular));
    
    % Apply Gaussian smoothing
    im_profiles = imfilter(im_profiles, gv(:) * gh(:)', 'symmetric');
    
    % Update the VESSELS object IM_PROFILES property with the smoothed
    % images - it's easier to make sense of the set diameters when checking
    % later if we have the filtered version to look at
    if dark_vessels
        vessels(ii).im_profiles = -im_profiles;
    else
        vessels(ii).im_profiles = im_profiles;
    end
    
    % Compute 2nd derivative perpendicular to vessel orientation
    im_profiles_2d = compute_discrete_2d_derivative(im_profiles);
    
    % Remove from consideration pixels outside the search region
    im_profiles_2d(~bw_regions) = NaN;
        
    % Find zero crossings - initially assume linear interpolation between
    % all points, then remove those where the crossing would require a
    % distance of more than 1 pixel to be added.
    % Since we have no idea how many zero crossings we will be, use the
    % original matrix and set non-zero-crossings to NaN.
    diffs = diff(im_profiles_2d, [], 2);
    cross_offsets = -im_profiles_2d(:, 1:end-1) ./ diffs;
    cross_offsets(cross_offsets >= 1 | cross_offsets < 0) = NaN;
    cross = bsxfun(@plus, 1:size(im_profiles, 2)-1, cross_offsets);

    % Separate crossings according to whether they are positive -> negative
    % or negative -> positive, i.e. whether they are potentially rising or
    % falling edges, and only allow those on the appropriate size of the
    % centreline
    cross_rising = cross;
    cross_rising(diffs > 0 | cross_rising > c) = NaN;
    cross_falling = cross;
    cross_falling(diffs < 0 | cross_falling < c) = NaN;
    
    
    % Look for the vessel edges, with or without a connectivity test.
    if ~enforce_connectedness
        % Look for the zero-crossings to the left and right of the centreline,
        % using the mean edge columns for guidance.  Use the sign of the
        % second derivative at the estimated column location to determine
        % which direction to search: if the sign is negative, then the
        % estimated column is probably within the vessel, and we want to
        % look away from the centre - otherwise we want to look towards the
        % centre.
        search_left = im_profiles_2d(:, l_mean_col) <= 0;
        col_left = find_closest_crossing(cross_rising, l_mean_col, search_left);
        search_left = im_profiles_2d(:, r_mean_col) >= 0;
        col_right = find_closest_crossing(cross_falling, r_mean_col, search_left);
    else
        % Determine the most connected crossings for the 'rising' phase,
        % i.e. what appears to the longest valid edge in the vicinity of
        % vessel
        cross_rising = find_most_connected_crossings(cross_rising, l_mean_col, max(width_est/3, 1));
        % Probably only one crossing per row, but be sure to accept the
        % crossings closest to the centre just in case
        col_left = max(cross_rising, [], 2);
        % Determine the most crossings for the 'falling' phase
        cross_falling = find_most_connected_crossings(cross_falling, r_mean_col, max(width_est/3, 1));
        col_right = min(cross_falling, [], 2);
    end

    % Compute the side points, and store them
    rows = (1:n_profiles)';
    inds_found = isfinite(col_left) & isfinite(col_right);
    vessels(ii).side1(inds_found, :) = get_side(im_profiles_rows, im_profiles_cols, rows(inds_found), col_left(inds_found));
    vessels(ii).side2(inds_found, :) = get_side(im_profiles_rows, im_profiles_cols, rows(inds_found), col_right(inds_found));
    
    % Alternatively, could use this (but it's a bit slower)
%     vessels(ii).side1(inds_found, :) = [interp2(im_profiles_rows, col_left(inds_found), rows(inds_found), '*linear'), ...
%                                         interp2(im_profiles_cols, col_left(inds_found), rows(inds_found), '*linear')];
%     vessels(ii).side2(inds_found, :) = [interp2(im_profiles_rows, col_right(inds_found), rows(inds_found), '*linear'), ...
%                                         interp2(im_profiles_cols, col_right(inds_found), rows(inds_found), '*linear')];
end


% For a matrix CROSSINGS containing crossing values in (approximately) the
% correct column and NaNs elsewhere, look for the connected components of
% the non-NaN regions in order to identify potential connected edges.
% Exclude those that do not come within REGION_LENGTH pixels of COLUMN at
% any location, then retain only the CROSSINGS that are part of the largest
% remaining potential edge regions for the corresponding row (i.e. set
% everything else to NaN).
% The idea is that long sequences of zero-crossings that are close to one
% another are more likely to be parts of true vessel edges than short or
% isolated zero-crossings.  In the idea case, there would be a single trail
% of zero-crossings to the left and right of centre for each vessel.
function crossings = find_most_connected_crossings(crossings, column, region_length)
% Identify only those transition lines that are near to the estimated
% column
if isscalar(column)
    bw_region = abs(crossings - column) <= region_length;
else
    bw_region = abs(bsxfun(@minus, crossings, column)) <= region_length;
end
% Remove any crossing that is not connected to one that overlaps the search
% region
crossings(~imreconstruct(bw_region, isfinite(crossings))) = NaN;
% If this then leaves us with 0 or 1 crossings per row, we don't need to do
% any more
finite_crossings = isfinite(crossings);
if sum(isfinite(crossings), 2) <= 1
    return
end
% Label each connected trail of crossings
[lab, num] = bwlabel(finite_crossings);
if num == 1
    crossings(lab ~= 1) = NaN;
else
    % Count the number of crossings per trail
    n_labs = histc(lab(:), 1:num);
    lab(lab > 0) = n_labs(lab(lab > 0));
end
% Discard any crossings if they occur on the same row as another crossing
% that is part of a longer trail
bw_region = bsxfun(@eq, lab, max(lab, [], 2));
crossings(~bw_region) = NaN;

% % Alternative (slightly slower) code that does the same:
% % Label connected lines of pixels marking a transition from negative to
% % positive 2nd derivatives
% cc_edges = bwconncomp(isfinite(crossings));
% % Identify only those transition lines that are near to the estimated
% % column, and count the number of connections along the line
% bw_region = abs(bsxfun(@minus, crossings, column)) <= region_length;
% if ~all(sum(bw_region, 2) == 1)
%     link_counts = nan(size(crossings));
%     for jj = 1:cc_edges.NumObjects
%         inds = cc_edges.PixelIdxList{jj};
%         if any(bw_region(inds))
%             link_counts(inds) = numel(inds);
%         end
%     end
%     % Find the crossings that have most connections for each row
%     bw_region = bsxfun(@eq, link_counts, max(link_counts, [], 2));
% end
% crossings(~bw_region) = NaN;




% For each row in CROSSINGS, find the value closest to that of COLUMN that
% is either lower (if SEARCH_PREVIOUS == TRUE) or higher (if
% SEARCH_PREVIOUS == FALSE).
function cross = find_closest_crossing(crossings, column, search_previous)
search_next = ~search_previous;
cross = nan(size(crossings, 1), 1);
if any(search_previous)
    cross(search_previous) = find_previous_crossing(crossings(search_previous, :), column);
end
if any(search_next)
    cross(search_next) = find_next_crossing(crossings(search_next, :), column);
end

% Find the closest (non-NaN) value in CROSSINGS immediately after to a given column.
% COLUMN should be a scalar, or a vector with a length SIZE(CROSSINGS, 1)
function cross_next = find_next_crossing(crossings, column)
crossings(bsxfun(@lt, crossings, column)) = NaN;
cross_next = min(crossings, [], 2);

% Find the closest (non-NaN) value in CROSSINGS immediately prior to a given column.
% COLUMN should be a scalar, or a vector with a length SIZE(CROSSINGS, 1)
function cross_prev = find_previous_crossing(crossings, column)
crossings(bsxfun(@gt, crossings, column)) = NaN;
cross_prev = max(crossings, [], 2);



% Compute the 2nd derivative of profiles in PROF, computed along each row.
% (Actually, this gives negative of the 2nd derivative, to ensure the
% interesting region is positive)
function prof_2d = compute_discrete_2d_derivative(prof)
prof_2d = prof(:, [1, 1:end-1]) + prof(:, [2:end, end]) - 2 * prof;
% (Could have used IMFILTER, but the alternative approach is faster)
% im_profiles_2d = imfilter(im_profiles, [-1 2 -1], 'replicate');



% Find the columns to the left and right of the centre in which the maximum
% gradient magnitude of a profile is to be found.  Because PROF should
% represent a 'hill-like' vessel, the potential edge on the left has the
% largest positive gradient, while the potential edge on the right has
% largest negative gradient.  REGION_LENGTH defines the size of the search
% region around the centre that is used when looking for the gradient
% locations.
function [left_col, right_col] = find_maximum_gradient_columns(prof, region_length)
c = ceil(size(prof, 2) / 2);
region_length = ceil(region_length) + 1;
if region_length >= c
    region_length = c;
end
prof(:, 2:end-1) = prof(:, 3:end) - prof(:, 1:end-2);
prof(:, 1:c-region_length) = NaN;
prof(:, c+region_length:end) = NaN;
[m, left_col] = max(prof(:, 1:c), [], 2);
[m, right_col] = min(prof(:, c:end), [], 2);
right_col = right_col + c - 1;



% A custom linear interpolation method for extracting edge coordinates.  It
% assumes that ROWS gives the rows inside IM_PROFILES_ROWS/COLS, and will be
% valid integer values.  COLS gives the columns in the same matrices, and
% will be within range but potentially non-integer, and so interpolation
% will be used.
function side = get_side(im_profiles_rows, im_profiles_cols, rows, cols)
cols_floor = floor(cols);
cols_diff = cols - floor(cols);
inds_floor = sub2ind2d(size(im_profiles_rows), rows, cols_floor);
inds_floor_plus = inds_floor + size(im_profiles_rows, 1);
side_rows = im_profiles_rows(inds_floor) .* (1 - cols_diff) + im_profiles_rows(inds_floor_plus) .* cols_diff;
side_cols = im_profiles_cols(inds_floor) .* (1 - cols_diff) + im_profiles_cols(inds_floor_plus) .* cols_diff;
side = [side_rows, side_cols];


% A faster conversion of row and column subscripts into linear indexes.
% Does the same as SUB2IND, but without error checking, and only for 2D.
function inds = sub2ind2d(siz, r, c)
inds = r + siz(1) * (c - 1);


% Create a 1D Gaussian filter with sigma SIGMA.
% Coefficients are normalised so that their sum is 1.
function g = gaussian_filt_1d_sigma(sigma)
% For zero or negative sigma, return a filter that does nothing...
if sigma <= 0
    g = 1;
    return
end
% Choose a suitable filter length
len = ceil(sigma * 3) * 2 + 1;
% Find where to evaluate the Gaussian
xx = 0:len-1;
xx = xx - xx(end)/2;
% Evaluate the filter coefficients
g = exp(-xx.^2 / (2 * sigma.^2));
% Normalise the filter
g = g / sum(g(:));