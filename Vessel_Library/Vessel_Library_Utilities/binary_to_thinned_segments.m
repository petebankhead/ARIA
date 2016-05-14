function [bw_segments, bw_branches, dist] = binary_to_thinned_segments(bw, spur_length, clear_branches_dist)
% Computes a binary image containing thinned centrelines from a segmented
% binary image containing vessels.  Branch points and short spurs are
% removed during the thinning.
% 
% Input:
%   BW - the original segmented image.
%   SPUR_LENGTH - the length of spurs that should be removed.
%   CLEAR_BRANCHES_DIST - TRUE if centre lines should be shortened
%   approaching branch points, so that any pixel is removed from the
%   centre line if it is closer to the branch than to the background
%   (i.e. FALSE pixels in BW).  If measurements do not need to be made
%   very close to branches (where they may be less accurate), this can
%   give a cleaner result (Default = TRUE).
%
% Output:
%   BW_SEGMENTS - another binary image (the same size as BW) containing
%   only the central pixels corresponding to segments of vessels
%   between branches.
%   BW_BRANCHES - the detected branch points that were removed from the
%   originally thinned image when generating BW_SEGMENTS.
%   DIST - the distance transform BWDIST(~BW).  If CLEAR_BRANCHES_DIST
%   is TRUE, then this is required - and given as an additional output
%   argument since it has other uses, and it can be time consuming to
%   recompute for very large images.  Even if CLEAR_BRANCHES_DIST is FALSE,
%   DIST is given if it is needed.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Set up default if needed
if nargin < 3 || isempty(clear_branches_dist)
    clear_branches_dist = true;
end

% Thin the binary image
bw_thin = bwmorph(bw, 'thin', Inf);

% Find the branch and end points based upon a count of 'on' neighbours
neighbour_count = imfilter(uint8(bw_thin), ones(3));
bw_branches = neighbour_count > 3 & bw_thin;
bw_ends = neighbour_count <= 2 & bw_thin;

% Remove the branches to get the segments
bw_segments = bw_thin & ~bw_branches;

% Find the terminal segments - i.e. those containing end points
bw_terminal = imreconstruct(bw_ends, bw_segments);

% Remove the terminal segments if they are too short
bw_thin(bw_terminal & ~bwareaopen(bw_terminal, spur_length)) = false;

% We might still have some single pixel spurs, so remove these
bw_thin = bwmorph(bw_thin, 'spur');

% Also need to apply a thinning, since we can have 8-connected pixels that
% are nonetheless not branch points
bw_thin = bwmorph(bw_thin, 'thin', Inf);

% Remove the branches again to get the final segment
neighbour_count = imfilter(uint8(bw_thin), ones(3));
bw_branches = neighbour_count > 3 & bw_thin;
bw_segments = bw_thin & ~bw_branches;

% If necessary, remove more pixels at the branches(depending upon how edges
% are set, these locations can be very problematic).
% Use the distance transform to identify centreline pixels are closer to
% the branch than to the background - and then get rid of these.
if clear_branches_dist
    dist = bwdist(~bw);
    bw(bw_branches) = false;
    dist2 = bwdist(~bw);
    bw_segments = bw_thin & (dist == dist2);
elseif nargout >= 3
    dist = bwdist(~bw);
end

%------------------------------------

% The first version of the code looked more like this:
% % Default number of spur iterations
% if nargin < 3 || isempty(spur_iterations)
%     spur_iterations = 5;
% end
% 
% % Thin the segmented image to reduce vessels to a single (centre) line
% bw_thin = bwmorph(bw, 'thin', Inf);
% 
% % Remove some short spurs, which are little offsets that can arise through
% % the thinning.
% % NOTE: BWMORPH could be used, but is quite slow
% % bw_thin = bwmorph(bw_thin, 'spur', 4);
% % Alternative spur removal by shaving off end points -
% % not magnificently refined, but much faster than BWMORPH (for now)
% bw_thin2 = bw_thin;
% for ii = 1:spur_iterations
%     % Count the number of 'on' neighbours for each pixel, and remove if it
%     % is too few (i.e. we have an end point)
%     im_neighbours = imfilter(uint8(bw_thin2), ones(3));
%     bw_thin2 = bw_thin2 & im_neighbours >= 3;
% end
% 
% % Now apply some more thinning - the spur removal can result in some
% % 4-connected
% bw_thin = bwmorph(bw_thin2, 'spur', 1);
% bw_thin = bwmorph(bw_thin, 'thin', Inf);
% 
% 
% % Remove the branches - use a filter to count the number of 'on' neighbours
% % for each pixel (including itself), and remove if this is more than 3
% bw_branches = imfilter(uint8(bw_thin), ones(3)) > 3 & bw_thin;
% bw_segments = bw_thin & ~bw_branches;