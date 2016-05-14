function [vessels, dist_max] = thinned_vessel_segments(bw, spur_length, min_px, remove_extreme, clear_branches_dist)
% Thin down a binary image, and extract centre line pixels exceeding a
% specified minimum length.  The centre lines are divided into segments, 
% where each segment represents the continuous centre line occurring 
% between end points and/or branches.
%
% Input:
%    BW - the binary image (a 2D logical array) in which 'vessel' pixels
%    are TRUE and all other pixels are FALSE.
%    SPUR_LENGTH - the length of spurs that should be removed from the
%    thinned vessel centre lines.  Because spurs are offshoots from the
%    centre line, they cause branches - which can lead to vessels being
%    erroneously sub-divided.  On the other hand, some spurs can really be
%    the result of actual vessel branches - and should probably be kept.
%    This parameter is a length (in pixels) that a spur must exceed for it
%    to be kept (Default = 10).
%    CENTRE_MIN_PX - the minimum number of pixels in a vessel segment centre
%    line for it to be kept. Should be >= 2 because of need for angles.  The
%    spur removal will only get rid of terminal segments, but very short
%    segments might remain between branches, in which case this parameter
%    becomes relevant (Default = 2).
%    REMOVE_EXTREME - TRUE if centre lines should be removed if they appear
%    to have widths greater than their length.  Coarse estimates of width
%    and length are used, based upon the distance transform and number of
%    pixels in the centre line respectively.  Nevertheless, the risk of
%    removing real, measurable vessels of a reasonable length by using this
%    option are small, while it can reduce the number of spurious
%    detections.
%    CLEAR_BRANCHES_DIST - TRUE if centre lines should be shortened
%    approaching branch points, so that any pixel is removed from the
%    centre line if it is closer to the branch than to the background
%    (i.e. FALSE pixels in BW).  If measurements do not need to be made
%    very close to branches (where they may be less accurate), this can
%    give a cleaner result (Default = TRUE).
%
% Output:
%   VESSELS - an array of VESSEL objects, with the CENTRE property set
%   according to the thinned centreline coordinates.
%   DIST_MAX - the maximum value of the distance transform of the inverted
%   image BW, found along the thinned segments.  This can be used for
%   determining how long to make image profiles, since it is approximately
%   equal to the radius of the widest vessel at its widest point (assuming
%   reasonably accurate segmentation).
% 
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Unfortunately, this is vectorised and not the easiest code to read... 
% it is, however, quite fast.

% Default spur and minimum length
if nargin < 2 || isempty(spur_length)
    spur_length = 10;
end
if nargin < 3 || isempty(min_px)
    min_px = 2;
end
if nargin < 4 || isempty(remove_extreme)
    remove_extreme = false;
end
if nargin < 5 || isempty(clear_branches_dist)
    clear_branches_dist = true;
end

% Determine vessel segment centre lines from an original binary image
[bw_segments, dum, dist_trans] = binary_to_thinned_segments(bw, spur_length, clear_branches_dist);

% % Compute the distance transform of the inverted binary image if needed
% if remove_extreme || nargout > 1
%     dist_trans = bwdist(~bw);
% end

% Get indices for the 'on' pixels of each centre line segment
cc = bwconncomp(bw_segments);

% Create an array of vessels to store centre pixel locations in [row, col] form
vessels(cc.NumObjects) = Vessel;

% We may need to remove some vessels in the end if they have insufficient
% pixels
remove_inds = false(size(vessels));

% Put the pixel locations in order, from one end to the other
for ii = cc.NumObjects:-1:1
    % Extract the indices of the pixels
    px_inds = cc.PixelIdxList{ii};
    
    % If there are too few pixels, or the distance transform indicates we
    % have a short segment inside 
    if numel(px_inds) < min_px || (remove_extreme && max(dist_trans(px_inds)) * 2 > numel(px_inds))
        remove_inds(ii) = true;
        continue;
    end
    
    % Get the row and column of each pixel
    row = rem(px_inds-1, size(bw,1)) + 1;
    col = (px_inds - row) / size(bw,1) + 1;
    % ALTERNATIVE (slightly slower) to the above
    %  [row, col] = ind2sub(size(bw), cc.PixelIdxList{ii});

    % If only 1 or 2 pixels are present, these can't possibly be out of order
    % (although this only matters if the minimum pixels part is overridden)
    if numel(cc.PixelIdxList{ii}) <= 2
        vessels(ii).centre = [row, col];
        continue;
    end
    
    % Calculate the distance of each pixel from one another -
    % DIST is a symmetric logical matrix, where TRUE indicates that two
    % pixel locations (identified by the row and column) in the matrix
    % are within 1 pixel distance of one another
    dist = (abs(bsxfun(@minus, row, row')) <= 1) & (abs(bsxfun(@minus, col, col')) <= 1);
    % ALTERNATIVE (slightly slower)
    %  dist = (bsxfun(@minus, row, row').^2 + bsxfun(@minus, col, col').^2) <= 2;
    
    % Here, things become a bit confusing.  We temporarily don't care where
    % the pixel locations are (this is stored in the ROW and COL arrays),
    % but we DO care about which are beside one another - which is encoded
    % in the DIST array.  To make sense of this, consider the TRUE values
    %   [y, x] = FIND(DIST);
    % Then the pixel identified by ROW(y), COL(y) is next to the pixel
    % identified by ROW(x), COL(x).
    
    % If DIST is tridiagonal (tested by all TRUE on first diagonal),
    % the pixels are already in order - that is, pixels next to one another
    % are always within one pixel of each other.
    if all(diag(dist, 1))
        vessels(ii).centre = [row, col];
        continue;
    end
    
    % If we reached this point, it means we need to reorder the pixels.
    % First, find the adjacent pixels - because DIST is symmetric,
    % and TRUE along main diagonal doesn't mean anything very useful (as it
    % only indicates that a pixel is extremely close to itself), to find
    % out which pixels are adjacent we only need where the TRUE entries in 
    % the upper (or lower) part of the matrix are to be found.
    link = [];
    [link(:,1), link(:,2)] = find(triu(dist, 1));
    
    % We are now working with indices to ROW and COL, and want to find
    % where entries belong beside one another.  LINK gives us that
    % information, by giving pairs of linked indices.
    % Now get the number of occurrences of each index.
    locs = 1:max(link(:));
    n = histc(link(:), locs);
    
    % The indices that only occur once must be the end points.
    % Based upon the previous code, there should be precisely two - but if
    % we were very unlucky we might have happened upon a loop, in which
    % case we remove the segment.
    loc_inds = n == 1;
    if nnz(loc_inds) ~= 2
        remove_inds(ii) = true;
        continue;
    end
    
    % LOCS is really a vector of indices into ROW and COL.
    % We now know what its first and last values should be, based upon the
    % end points we have.
    locs([1,end]) = locs(loc_inds);
    
    % Starting at the initial end point, follow the links to the other one.
    % End points have only one link.  Every other pixel has two.  But by
    % removing the links we have already visited, we are only looking for a
    % single link on each iteration.
    for jj = 2:numel(locs)-1
        % Get the row in LINKS containing the last index found (which
        % might be in the first or second column)
        rem_row = any(link == locs(jj-1), 2);
        rem_links = link(rem_row, :);
        % Get the linked index (which is the entry in REM_LINKS that is not
        % the index we already have)
        locs(jj)  = rem_links(rem_links ~= locs(jj-1));
        % Remove the row from LINK in preparation for the next iteration
        link = link(~rem_row, :);
    end
    % Go back now to the original ROW and COL arrays to get the pixel
    % segment centre line locations in order, and store these in the cell array
    vessels(ii).centre = [row(locs), col(locs)];
end

% Remove any vessels where there were not enough pixels
if any(remove_inds)
    vessels(remove_inds) = [];
end

% Find the maximum remaining centreline value in the distance transform, if
% required
if nargout > 1
    cc.PixelIdxList(remove_inds) = [];
    inds_all = cat(1, cc.PixelIdxList{:});
    if isempty(inds_all)
        dist_max = 0;
    else
        dist_max = max(dist_trans(inds_all));
    end
end