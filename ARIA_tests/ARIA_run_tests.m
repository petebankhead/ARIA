function ARIA_run_tests(f_name, test_name)
% Run all the tests using ARIA to create the results reported in the paper
% 'Fast retinal vessel detection and measurement using wavelets and edge
% location refinement'.
% 
% Input:
%   F_NAME - (optional) a string giving a file name to which the output
%   should be written.  The file will be tab-delimited, so will look best
%   in a spreadsheet.  If F_NAME is omitted, the output is written to the
%   MATLAB command window.
%   TEST_NAME - (optional) a string giving the name of the test to run
%   ('SEGMENT' for the segmentation test, 'DRIVE' for the DRIVE processing
%   time test or 'REVIEW' for the REVIEW measurement test), or 'ALL' if all
%   available tests should be applied (Default = 'ALL').
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


%% STORE DATE OF TEST FILE
test_date = '9 December 2011';

%% INPUT CHECKING

% Check whether or not we have a file to write, or if the output is to the
% command window
if nargin < 1 || ~ischar(f_name)
    fid = 1;
    do_file = false;
else
    fid = fopen(f_name, 'w');
    do_file = true;
end

% Determine which tests to apply
if nargin < 2 || ~ischar(test_name)
    test_name = 'all';
else
    test_name = lower(test_name);
    if ~any(strcmp({'all', 'review', 'drive', 'segment'}, test_name))
        error('Invalid TEST_NAME given!');
    end
end

% Make sure we have the ARIA files somewhere on the search path, at least
% for this MATLAB session - or give a warning if the functions can't be
% found
if exist('ARIA_setup', 'file')
    ARIA_setup(true);
else
    error(['Cannot find the function ARIA_SETUP.M.  ', ...
           'To fix this, you should find the file with this name in the ARIA base folder, and run it once.  ', ...
           'Alternatively, manually add the ARIA base folder to the MATLAB search path (File -> Set Path...).']);
end


%% ENSURE FILE PATHS

% Make sure we have paths to the required directories containing the image
% databases
if ~strcmp(test_name, 'review')
    dir_drive = get_vessel_database_directory('DRIVE');
    if isempty(dir_drive)
        disp('DRIVE database path not set - aborting tests');
        return
    end
end
if any(strcmp({'review', 'all'}, test_name))
    dir_review = get_vessel_database_directory('REVIEW');
    if isempty(dir_review)
        disp('REVIEW database path not set - aborting tests');
        return
    end
end


%% 'WARM UP' MATLAB - JUST IN CASE

% Run the KPIS test first.  This isn't strictly necessary, although it
% should be fast because the images are so small.
% The purpose of this is to call the full analysis algorithm.  Because the
% first call to any code in MATLAB tends to be slower (thanks to file
% systems / memory management / M file parsing etc.), including the
% results from first runs would lead to potentially misleading benchmarking
% results in which the analysis of the first tested image would appear
% slower than the others for reasons quite independent of the image itself.
%
% (In fact, for *really* accurate times more repetitions of the code being
% profiled may be required to properly overcome these issues, but for slower
% functions this may make the tests last much too long.  Still, ensuring
% the analysis algorithm is called at least once in advance is a reasonable
% start.)
%
% See http://www.mathworks.com/matlabcentral/fileexchange/18510 for more
% detailed information about benchmarking pitfalls, or
% http://blogs.mathworks.com/steve/2008/02/29/timing-code-in-matlab/ for
% some of the main points.
REVIEW_evaluate_diameter_measurements('KPIS');



%% SYSTEM INFORMATION

% Output some information about the test system for reference
fprintf(fid, '\n--------------------------------------------------\n\n');
fprintf(fid, '**--TEST SYSTEM--**\n\n');
fprintf(fid, 'Computer:\t%s\n', computer);
fprintf(fid, 'Version:\t%s\n', version);
fprintf(fid, 'Original test written:\t%s', test_date);
fprintf(fid, '\n--------------------------------------------------\n\n');


%% DRIVE SEGMENTATION TEST

if any(strcmp({'segment', 'all'}, test_name))
    % Apply the IUWT segmentation to the test images of the DRIVE database, and
    % determine the average processing time along with accuracy measurements
    % (determined by comparison with manually segmented images).
    if fid ~= 1
        disp('Running DRIVE segmentation test...');
    end
    
    % Run the segmentation test
    segmentation_algorithm = DRIVE_get_segmentation_algorithm;
    [table, processing_time] = DRIVE_measure_segmentation_accuracy(segmentation_algorithm, true);
    
    % Output the accuracy
    fprintf(fid, '**--DRIVE SEGMENTATION TEST--**\n\n');
    if fid == 1
        write_table_to_command_window(table, [0, 1, 3], [0, 1, 4]);
    else
        write_table_to_file(fid, table);
    end
    
    % Output the segmentation timing
    fprintf(fid, '\nProcessing time for IUWT segmentation of DRIVE image:\n');
    fprintf(fid, '\tMean:\t%.3f seconds\n', mean(processing_time));
    fprintf(fid, '\tStd. dev.:\t%.3f seconds\n', std(processing_time));
    fprintf(fid, '\n--------------------------------------------------\n\n');
end


%% DRIVE PROCESSOR TEST

if any(strcmp({'drive', 'all'}, test_name))
    % Apply the analysis algorithm to the test images of the DRIVE database,
    % and determine the average processing time.
    if fid ~= 1
        disp('Running DRIVE full processing test...');
    end
    
    % Apply the full processing test
    processor = ARIA_generate_test_processor('DRIVE');
    processing_time = DRIVE_measure_processing_time(processor);
    
    % Output the timing
    fprintf(fid, '**--DRIVE FULL PROCESSING TEST--**\n\n');
    fprintf(fid, 'Processing time for DRIVE database images:\n');
    fprintf(fid, '\tMean:\t%.3f seconds\n', mean(processing_time));
    fprintf(fid, '\tStd. dev.:\t%.3f seconds\n', std(processing_time));
    fprintf(fid, '\n--------------------------------------------------\n\n');
end


%% REVIEW DATABASE TEST

if any(strcmp({'review', 'all'}, test_name))
    % Run the REVIEW tests for each image database
    if fid ~= 1
        disp('Running REVIEW vessel measurement test...');
    end

    % Run the processing for all image sets
    % sets = {'KPIS', 'CLRIS', 'HRIS_downsample'};
    sets = {'KPIS', 'CLRIS', 'VDIS', 'HRIS_downsample', 'HRIS'};
    for ii = numel(sets):-1:1
        REVIEW(ii) = REVIEW_evaluate_diameter_measurements(sets{ii});
    end;

    % Generate a table containing the results, and display it
    table = REVIEW_create_results_table(REVIEW);
    fprintf(fid, '**--REVIEW MEASUREMENT TEST--**\n\n');
    if fid == 1
        write_table_to_command_window(table, [0, 2, size(table,1)], [0, 1:3:size(table,2)]);
    else
        write_table_to_file(fid, table);
    end
    
    % Output the processing times
    fprintf(fid, '\n\nProcessing time for REVIEW database images:\n');
    for ii = 1:numel(REVIEW)
        fprintf(fid, '\t%s\t%f seconds\n', REVIEW(ii).image_set, REVIEW(ii).mean_processing_time);
    end
    fprintf(fid, '\n--------------------------------------------------\n\n');
end


%% CLEANUP

% If not outputing everything to the command window, send a notification
% that we are finished
if fid ~= 1
    disp('Testing complete!');
end

% Close any open file
if do_file
    fclose(fid);
end