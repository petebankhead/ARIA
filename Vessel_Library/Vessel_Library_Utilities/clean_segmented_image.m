function bw_clean = clean_segmented_image(bw, min_object_size, min_hole_size)
% Clean a binary image by removing small objects and filling small holes.
%
% Input: BW - the binary image
%        MIN_OBJECT_SIZE - the minimum size of an object to be kept (in
%        pixels).
%        MIN_HOLE_SIZE - the minimum size of a 'hole' (a region surrounded
%        by detected pixels); smaller holes will be filled in.
%
% Output: BW_CLEAN - the modified binary image
%         OBJ_HOLES - a structure containing the size and location of
%         objects and holes, which can be used to speed up later calls to
%         this function (assuming BW is unchanged).
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Remove small objects, if necessary
if min_object_size > 0
    cc_objects = bwconncomp(bw);
    area_objects = cellfun('size', cc_objects.PixelIdxList, 1);
    bw_clean = false(size(bw));
    inds = area_objects >= min_object_size;
    bw_clean(cell2mat(cc_objects.PixelIdxList(inds)')) = true;
else
    bw_clean = bw;
end

% Fill in holes, if necessary
if min_hole_size > 0
    cc_holes = bwconncomp(~bw_clean);
    area_holes = cellfun('size', cc_holes.PixelIdxList, 1);
    inds = area_holes < min_hole_size;
    bw_clean(cell2mat(cc_holes.PixelIdxList(inds)')) = true;
end


% Alternative code...
% % Remove small objects, if necessary
% if min_object_size > 0
%     bw_clean = bwareaopen(bw, ceil(min_object_size));
% else
%     bw_clean = bw;
% end
% 
% % Fill in holes, if necessary
% if min_hole_size > 0
%     bw_clean = ~bwareaopen(~bw_clean, floor(min_hole_size));
% end