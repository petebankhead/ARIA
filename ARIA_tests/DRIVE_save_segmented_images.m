function [results, segmentation_algorithm] = DRIVE_save_segmented_images(dir_output, segmentation_algorithm)
% Test the segmentation of DRIVE database images, and save the resulting
% binary images in a specified directory.  Alongside the binary images, a
% colourized version is also given, with the following interpretation:
%   - BLACK - correctly identified vessel pixels
%   - WHITE - correctly identified non-vessel pixels
%   - GREEN - undetected vessel pixels (false negatives)
%   - MAGENTA - wrongly-detected non-vessel pixels (false positives)
% 
% Input:
%   DIR_OUTPUT - the path to the directory in which the images should be
%   written.
%   SEGMENTATION_ALGORITHM - a function handle for the segmentation
%   algorithm to use (Optional; Default = the output from
%   DRIVE_get_segmentation_algorithm).
%   If present, the segmentation algorithm function should take two input
%   arguments: the image itself, and then a binary mask for the FOV.
%
% Output:
%   RESULTS - a STRUCT containing the results of the segmentation.  See
%               HELP DRIVE_measure_segmentation_accuracy
%             for more information.
%   SEGMENTATION_ALGORITHM - the function handle to the segmentation used.
%   
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% By default, use the DRIVE segmentation algorithm reported in the ARIA
% paper
if nargin < 2
    segmentation_algorithm = DRIVE_get_segmentation_algorithm;
end

% Make sure the directory exists, and the path ends with a file separator
if exist(dir_output, 'dir') == 0
    mkdir(dir_output);
end
if dir_output(end) ~= filesep
    dir_output = [dir_output, filesep];
end

% Get the actual results of the segmentation
[table, processing_time, results] = DRIVE_measure_segmentation_accuracy(segmentation_algorithm, false);

% Loop through the results, and store the binary images
for ii = 1:numel(results)
    bw = results(ii).bw;
    bw_man1 = results(ii).bw_man1;
    
    % Generate an indexed-colour image for display of the matched vessel
    % and non-vessel pixels, as well as the false positives and negatives
    im_disp = zeros(size(bw), 'uint8');
    im_disp(bw & ~bw_man1) = 1;
    im_disp(~bw & bw_man1) = 2;
    im_disp(bw & bw_man1) = 3;
    
    % Write the binary and indexed colour images
    base_name = results(ii).file_name;
    base_name = [base_name(1:find(base_name == '.', 1, 'last')), 'png'];
    imwrite(bw, [dir_output, 'binary_', base_name])
    imwrite(im_disp, [1 1 1; .8 0 .5; 0 .8 0; 0 0 0], [dir_output, 'label_', base_name])
    
%     % The following code could be used to determine the size of objects
%     % that do and do not contain any vessel pixels.  This would help with
%     % deciding the size of objects to remove, or holes to fill during the
%     % segmentation.
%     temp = imreconstruct(bw & bw_man1, bw);
%     cc = bwconncomp(bw & ~temp);
%     results(ii).n_px_bad = cellfun(@numel, cc.PixelIdxList);
%     cc = bwconncomp(temp);
%     results(ii).n_px_good = cellfun(@numel, cc.PixelIdxList);
end