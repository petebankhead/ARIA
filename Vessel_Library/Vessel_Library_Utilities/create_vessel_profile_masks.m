function [vessel_regions, mask_regions] = ...
            create_vessel_profile_masks(vessels, bw, bw_mask)
% Determine binary masks for the profiles of vessels, which can be used as
% estimates for the vessel edges (VESSEL_REGIONS) or to define search
% regions for vessel edges (MASK_REGIONS).
% 
% Input:
%   VESSELS - an array of VESSEL objects with CENTRE, IM_PROFILES_COLS and
%   IM_PROFILES_ROWS properties set
%   BW - a binary image showing vessels
%   BW_MASK - (optional) a binary image, the same size as BW, containing
%   the field of view.  If this is empty, the entire image is taken as the
%   field of view.
% 
% Output:
%   VESSEL_REGIONS - a cell array of length LENGTH(VESSELS) in which
%   VESSEL_REGIONS{I} gives a binary mask corresponding to
%   VESSELS(I).IM_PROFILES in which a pixel is TRUE if it is part of the
%   vessel in BW.
%   MASK_REGIONS - a cell array similar to VESSEL_REGIONS, except a pixel
%   is TRUE if it is closer to the vessel under consideration than to any
%   other one.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Check the input
if nargin < 3
    bw_mask = [];
elseif ~isempty(bw_mask) && ~isequal(size(bw_mask), size(bw))
    warning('CREATE_VESSEL_MASK_REGIONS:MASK_SIZE', 'BW and BW_MASK must be the same size - BW_MASK will be ignored');
    bw_mask = [];
end

% Compute the profiles from the binary image.
% INTERP2 could be used, but is slower and nothing fancy is needed since we
% are only interested in nearest-neighbour interpolation
% First, extract the rows and columns as single, large arrays, and apply
% rounding
rows = round(cat(1, vessels.im_profiles_rows));
cols = round(cat(1, vessels.im_profiles_cols));
% Convert coordinates to linear indices - don't worry about validity yet
inds_coords = (cols - 1) * size(bw, 1) + rows;
% Check range and determine the valid coordinates
valid_coords = rows >= 1 & cols >= 1 & rows <= size(bw, 1) & cols <= size(bw, 2);
% Coordinates that are valid also need to be within the mask
if ~isempty(bw_mask)
    valid_coords(valid_coords(:)) = bw_mask(inds_coords(valid_coords(:)));
end
% Create the profiles; invalid coordinates are set to FALSE
bw_vessel_profiles_all = false(size(inds_coords));
bw_vessel_profiles_all(valid_coords(:)) = bw(inds_coords(valid_coords(:)));

% The actual vessel we want in the profile is the binary object overlapping
% the centreline.  This would be a natural task for IMRECONSTRUCT, but the
% helper function below is much faster in this case.
bw_vessel_profiles = get_centreline_object(bw_vessel_profiles_all);
% The IMRECONSTRUCT version:
% c = ceil(size(bw_vessel_profiles_all, 2) / 2);
% bw_vessel_profiles_markers = false(size(bw_vessel_profiles_all));
% bw_vessel_profiles_markers(:, c) = bw_vessel_profiles_all(:, c);
% bw_vessel_profiles = imreconstruct(bw_vessel_profiles_markers, bw_vessel_profiles_all, [0 0 0; 1 1 1; 0 0 0]);

% The vessel regions are the valid coordinates, with additional binary
% objects present in the profiles removed
bw_region_profiles = bw_vessel_profiles == bw_vessel_profiles_all;
bw_region_profiles(~valid_coords) = false;

% Put the masks into cell arrays
n_profiles = cellfun(@numel, {vessels.centre}) / 2;
mask_regions = mat2cell(bw_region_profiles, n_profiles, size(bw_region_profiles, 2));
vessel_regions = mat2cell(bw_vessel_profiles, n_profiles, size(bw_region_profiles, 2));



% For a binary image, just return the object that overlaps with the central
% column.  The method uses something like a 'cumulative AND', breaking
% early if it can.
function bw = get_centreline_object(bw)
c = ceil(size(bw, 2) / 2);
% Apply forwards to the right-of-centre
col_centre = bw(:, c);
for ii = c+1:size(bw, 2)
    col_centre = col_centre & bw(:, ii);
    if ~any(col_centre)
        bw(:, ii:end) = false;
        break
    end
    bw(:, ii) = col_centre;
end
% Apply backwards to the left-of-centre
col_centre = bw(:, c);
for ii = c-1:-1:1
    col_centre = col_centre & bw(:, ii);
    if ~any(col_centre)
        bw(:, 1:ii) = false;
        break
    end
    bw(:, ii) = col_centre;
end