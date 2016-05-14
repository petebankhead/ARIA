function [table, processing_time, results] = DRIVE_measure_segmentation_accuracy(segmentation_algorithm, use_timeit)
% Test the accuracy and timings of a vessel segmentation algorithm using
% the DRIVE database of retinal images (available from
% http://www.isi.uu.nl/Research/Databases/DRIVE/).  The DRIVE images must
% be available, and in the original directory structure.
%
% Input:
%   SEGMENTATION_ALGORITHM - a handle to a function that implements the
%   segmentation algorithm.  This should take two inputs: the original
%   image, and the binary field of view mask (which may be unused).  It
%   should also output a binary image (2D logical array) containing the
%   detected 'vessel' pixels.
%   USE_TIMEIT - TRUE if the segmentation time should also be computed
%   using Steve Eddins' TIMEIT benchmarking function (Default = FALSE).
%
% Note that using TIMEIT can provide more reliable results for the
% segmentation time, since it applies the function multiple times and
% takes the median of the results.
% However, if the segmentation is very slow then this might be undesirable.
% See http://www.mathworks.com/matlabcentral/fileexchange/18798 for more
% details.
%
% TIMEIT is not distributed along with this code, and so should be
% downloaded and added separately to the MATLAB path.
%
% Output:
%   TABLE - a cell array containing the main information in the RESULTS
%   structure, in a format that can be written to a file or the main
%   display using WRITE_TABLE_TO_FILE or WRITE_TABLE_TO_COMMAND_WINDOW. 
%   PROCESSING_TIME - a vector containing the processing time (in seconds)
%   required to segment each of the DRIVE test images
%   RESULTS - an array in which each entry is a STRUCT with the following
%   fields:    FILE_NAME - the name of the DRIVE database image
%              PROCESSING_TIME - the segmentation time in seconds
%              TRUE_PROPORTION - the proportion of the image (within the
%              field of view mask, FOV) containing vessel pixels
%              TPR - the 'true positive rate' for the algorithm, i.e. the
%              proportion of vessel pixels correctly identified
%              FPR - the 'false positive rate' for the algorithm, i.e. the
%              number of pixels wrongly considered vessels by the
%              algorithm, divided by the number of non-vessel pixesl in the
%              FOV
%              ACCURACY - the proportion of correctly-assigned pixels
%              (vessel or non-vessel) within the FOV
%              TPR_MANUAL - the true positive rate for the second manual
%              observer
%              FPR_MANUAL - the false positive rate for the second manual
%              observer
%              ACCURACY_MANUAL - the accuracy score for the second manual
%              observer
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


%% INPUT CHECKING

% Check there is an algorithm available
if nargin < 1 || ~isa(segmentation_algorithm, 'function_handle')
    error('A valid handle to a segmentation function is required');
end

% By default, don't use TIMEIT
if nargin < 2
    use_timeit = false;
end

% Also don't do the timing in the TIMEIT function is not found
if use_timeit && exist('timeit', 'file') ~= 2
    warning('TEST:CannotTime', ['To compute the segmentation time, the TIMEIT benchmarking function by Steve Eddins is required.\n', ...
        'It can be downloaded from http://www.mathworks.com/matlabcentral/fileexchange/18798']);
    use_timeit = false;
end


%% DETERMINE DIRECTORIES

% Get the directory for the drive database
dir_DRIVE = get_vessel_database_directory('DRIVE');

% Get the test directory
dir_DRIVE_test = [dir_DRIVE, filesep, 'test', filesep];

% Initialize directory names
dir_im = [dir_DRIVE_test, 'images', filesep];
dir_man1 = [dir_DRIVE_test, '1st_manual', filesep];
dir_man2 = [dir_DRIVE_test, '2nd_manual', filesep];
dir_mask = [dir_DRIVE_test, 'mask', filesep];

% Get the names of the files
fn_im = dir([dir_im, '*.tif']);
fn_man1 = dir([dir_man1, '*.gif']);
fn_man2 = dir([dir_man2, filesep, '*.gif']);
fn_mask = dir([dir_mask, filesep, '*.gif']);


%% COMPUTE RESULTS

% Initialize the results structure
results = struct;

% Loop through each file - assume correct numbers found and correct order
for ii = 1:numel(fn_im)
    % Store the file name
    results(ii).file_name = fn_im(ii).name;
    
    % Read the image
    im = imread([dir_im, fn_im(ii).name]);
    
    % Read the manually segmented images and the FOV mask
    bw_man1 = sum(imread([dir_man1, fn_man1(ii).name]), 3) > 0;
    bw_man2 = sum(imread([dir_man2, fn_man2(ii).name]), 3) > 0;
    bw_mask = sum(imread([dir_mask, fn_mask(ii).name]), 3) > 0;
    
    % Apply the segmentation, storing the timing
    tic;
    bw = segmentation_algorithm(im, bw_mask);
    results(ii).processing_time = toc;
        
    % If using Steve Eddins' TIMEIT function, need to apply this again
    if use_timeit
        fun = @() segmentation_algorithm(im, bw_mask);
        results(ii).processing_time = timeit(fun);
    end
    
    % Store the images
    results(ii).bw = bw;
    results(ii).bw_man1 = bw_man1;
    results(ii).bw_man2 = bw_man2;
    results(ii).bw_mask = bw_mask;    
    
    % Create vectors containing only the within-mask pixels for all the
    % segmentation results
    bw_man1 = bw_man1(bw_mask);
    bw_man2 = bw_man2(bw_mask);
    bw = bw(bw_mask);
    
    % Proportion of the image containing 'true' vessel pixels
    results(ii).true_proportion = nnz(bw_man1) / nnz(bw_mask);
    
    % True positive rate for algorithm segmentation - 
    % the number of correctly detected pixels, divided by the total number
    % of vessel pixels
    results(ii).tpr = nnz(bw_man1 & bw) / nnz(bw_man1);

    % False positive rate for algorithm segmentation - 
    % the number of wrongly detected pixels, divided by the total number of
    % non-vessel pixels
    results(ii).fpr = nnz(~bw_man1 & bw) / nnz(~bw_man1);
    
    % Accuracy measure -
    % Number of pixels (vessel or not) where the algorithm and manual
    % segmentation are in agreement
    results(ii).accuracy = nnz(bw_man1 == bw) / nnz(bw_mask);
    
    % Same measurements, made for the second manually-segmented image
    results(ii).tpr_manual = nnz(bw_man1 & bw_man2) / nnz(bw_man1);
    results(ii).fpr_manual = nnz(~bw_man1 & bw_man2) / nnz(~bw_man1);
    results(ii).accuracy_manual = nnz(bw_man1 == bw_man2) / numel(bw_man1);
    
end

% Create the results table
table = generate_results_table(results);

% Extract the processing time array
processing_time = [results.processing_time];


% Create a results table to display the output in a more attractive way.
function table = generate_results_table(results)
% Compute the mean results
mean_tpr = mean([results.tpr]);
mean_fpr = mean([results.fpr]);
mean_accuracy = mean([results.accuracy]);
mean_tpr_manual = mean([results.tpr_manual]);
mean_fpr_manual = mean([results.fpr_manual]);
mean_accuracy_manual = mean([results.accuracy_manual]);

% Create a results table
table = cell(3, 4);
table{1, 1} = 'Method';
table{1, 2} = 'TPR';
table{1, 3} = 'FPR';
table{1, 4} = 'Accuracy';
table{2, 1} = 'Manual';
table{2, 2} = mean_tpr_manual;
table{2, 3} = mean_fpr_manual;
table{2, 4} = mean_accuracy_manual;
table{3, 1} = 'Algorithm';
table{3, 2} = mean_tpr;
table{3, 3} = mean_fpr;
table{3, 4} = mean_accuracy;