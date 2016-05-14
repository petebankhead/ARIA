function [results, images] = REVIEW_evaluate_diameter_measurements(image_set, processor)
% Apply an ARIA vessel processor to a set of images in the REVIEW database
% (see http://reviewdb.lincoln.ac.uk/), and compare the diameter
% measurements with those of manual observers.
% 
% Input:
%   IMAGE_SET - the name of the REVIEW database image set to use, i.e.
%   'CLRIS', 'KPIS', 'VDIS', 'HRIS' (for full-size high-resolution images)
%   or 'HRIS_downsampled' (for high-resolution images downsampled by a
%   factor of 4).
%   PROCESSOR - the name of (or path to) the .vessel_processor file
%   that should be applied, or the ARGS structure of the processor itself.
%   If no PROCESSOR is given, an attempt is made to get one by calling
%   ARIA_GENERATE_TEST_PROCESSOR(IMAGE_SET);
%
% Output:
%   RESULTS - a STRUCT containing the observer centre points and diameters,
%   along with those of the algorithm that match.  Processing times for
%   each image are also given.  To summarize this, use
%   REVIEW_CREATE_RESULTS_TABLE(RESULTS);
%   IMAGES - an array of STRUCT in which each entry contains the
%   VESSEL_DATA objects for each manual obsever, the algorithm, and the
%   algorithm with detections matched to those of the observers.  These can
%   then be viewed, e.g. by typing
%       images(1).algorithm_matched.imshow;
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


%% CHECK INPUT

% Check the image set is ok
if nargin < 1 || ~ischar(image_set)
    error('IMAGE_SET should be a string giving the name of an image set from the REVIEW database')
end

% Try to get a processor if we don't have one already
if nargin < 2 || isempty(processor)
    processor = ARIA_generate_test_processor(image_set);
    if isempty(processor)
        error('A suitable processor could not be found');
    end
end



%% DETERMINE DIRECTORIES

% Get the directory for the drive database
dir_REVIEW = get_vessel_database_directory('REVIEW');

% Some parameters need tailored according to the image set
image_ext = '.bmp';
image_set_name = upper(image_set);
observer_set_ext = '.txt';
scale_value = 1;
switch image_set_name
    case {'HRIS'}
        % If we are processing HRIS images without downsampling, we need to
        % scale the manual centre & side markings (temporarily) for
        % comparison
        scale_value = 4;
    case {'HRIS_DOWNSAMPLE'}
        image_set_name = 'HRIS';
    case {'CLRIS'}
        image_ext = '.jpg';
    case {'KPIS'}
        % There are two files for KPIS observer markings - we want the second
        observer_set_ext = ' 2.txt';
end

% Get the directory containing the images of interest
dir_images = [dir_REVIEW, image_set_name, filesep];
if ~exist(dir_images, 'dir')
    error(['The directory cannot be found: ', dir_images]);
end

% Get the names of the image files - all BMP, except for CLRIS
fn_im = dir([dir_images, '*', image_ext]);

% Get the file name for the observer markings
observer_file_name = [dir_REVIEW, 'Observer Marking for ', image_set_name, observer_set_ext];



%% LOOP THROUGH THE FILES

% Create a settings object to use
settings = Vessel_Settings;
settings.show_labels = false;

% Get the number of images
n_images = numel(fn_im);

% May need a struct to store the vessel_data for each image
images = struct;

% Need arrays to store the diameters
diameters_true = [];
diameters_alg = [];
diameters_observer1 = [];
diameters_observer2 = [];
diameters_observer3 = [];
image_number = [];
centres_true = [];
centres_alg = [];

% Store processing times
processing_time = zeros(n_images, 1);

% Loop through each file - assume correct numbers found and correct order
% (Can go in descending order to avoid preallocation)
for ii = n_images:-1:1
    
    % Apply the automated detection & measurement processing
    file_name = [dir_images, fn_im(ii).name];
    [vd_algorithm, processing_time(ii)] = Vessel_Data_IO.load_from_file(file_name, processor, settings);
    
    % Extract the image number - which is just before the file extension
    ind = find(file_name == '.', 1, 'last') - 1;
    image_num = str2double(file_name(ind));
    
    % Read in the observer markings - scale them by 4 if using full-sized
    % HRIS images
    vl_o1 = REVIEW_create_observer_vessel_list(observer_file_name, image_num, 1, scale_value);
    vl_o2 = REVIEW_create_observer_vessel_list(observer_file_name, image_num, 2, scale_value);
    vl_o3 = REVIEW_create_observer_vessel_list(observer_file_name, image_num, 3, scale_value);
    
    % Compute mean diameters and centre lines for observers (i.e. ground
    % truth values), and put each in a cell array
    n_vessels = numel(vl_o1);
    ground_truth_diameters = cell(n_vessels, 1);
    ground_truth_centres = cell(n_vessels, 1);
    for vv = 1:n_vessels
        ground_truth_diameters{vv} = (vl_o1(vv).diameters + vl_o2(vv).diameters + vl_o3(vv).diameters) / 3;
        ground_truth_centres{vv} = (vl_o1(vv).centre + vl_o2(vv).centre + vl_o3(vv).centre) / 3;
    end
    
    % Match the algorithm and ground truth diameters
    vl_alg = match_detected_diameters(vd_algorithm.vessel_list, ground_truth_centres, ground_truth_diameters);
    
    % Store the diameters and image vessel numbers all together
    diameters_true = cat(1, ground_truth_diameters{:}, diameters_true);
    diameters_alg = cat(1, vl_alg.diameters, diameters_alg);
    diameters_observer1 = cat(1, vl_o1.diameters, diameters_observer1);
    diameters_observer2 = cat(1, vl_o2.diameters, diameters_observer2);
    diameters_observer3 = cat(1, vl_o3.diameters, diameters_observer3);
    image_number = cat(1, zeros(numel(cat(1, ground_truth_diameters{:})), 1) + ii, image_number);
    
    % Store the centres too - they might be interesting
    centres_true = cat(1, ground_truth_centres{:}, centres_true);
    centres_alg = cat(1, vl_alg.centre, centres_alg);
    
    % If required, create Vessel_Data objects to output
    if nargout > 1
        images(ii).observer1 = create_new_vessel_data(vd_algorithm, vl_o1);
        images(ii).observer2 = create_new_vessel_data(vd_algorithm, vl_o2);
        images(ii).observer3 = create_new_vessel_data(vd_algorithm, vl_o3);
        images(ii).algorithm_matched = create_new_vessel_data(vd_algorithm, vl_alg);
        images(ii).algorithm_orig = vd_algorithm;
    end
end

% Store the results - remember that SCALE_VALUE normally won't do anything,
% unless we are dealing with full-sized HRIS images
results = struct;
results.image_set = image_set;
results.algorithm = compute_results(diameters_alg / scale_value, diameters_true / scale_value);
results.true = compute_results(diameters_true / scale_value, diameters_true / scale_value);
results.observer1 = compute_results(diameters_observer1 / scale_value, diameters_true / scale_value);
results.observer2 = compute_results(diameters_observer2 / scale_value, diameters_true / scale_value);
results.observer3 = compute_results(diameters_observer3 / scale_value, diameters_true / scale_value);
results.processing_time = processing_time;
results.mean_processing_time = mean(processing_time);

% Store the image numbers, diameters and centres in case we really want to check
results.image_number = image_number;
results.diameters.algorithm = diameters_alg;
results.diameters.true = diameters_true;
results.diameters.difference = diameters_true - diameters_alg;
results.centres.algorithm = centres_alg;
results.centres.true = centres_true;
results.centres.distance = sum((centres_alg - centres_true).^2, 2);



% Given an array of diameters from an algorithm (with NaNs where no
% measurements were found) and an array or 'true' diameters, compute the
% interesting measurements (mean, standard deviation, mean of difference,
% standard deviation of difference) - ignoring the NaNs
function r = compute_results(d_alg, d_true)
r = struct;
r.success_rate = mean(~isnan(d_alg)) * 100;
r.diameters_mean = nan_mean(d_alg);
r.diameters_std = nan_std(d_alg);
r.difference_mean = nan_mean(d_alg - d_true);
r.difference_std = nan_std(d_alg - d_true);




% Create a Vessel_Data object with the same settings & images as VD_ORIG,
% but with VESSELS as the vessel_list
function vd_observer = create_new_vessel_data(vd_orig, vessels)
vd_observer = Vessel_Data;
vd_observer.im = vd_orig.im;
vd_observer.im_orig = vd_orig.im_orig;
vd_observer.add_vessels(vessels);




function vessels_matched = match_detected_diameters(vessels_orig, true_centres, true_diameters)
% Extract all the centre and side points from the detected (original)
% vessels
centres_detected = cell2mat({vessels_orig.centre}');
side1_detected = cell2mat({vessels_orig.side1}');
side2_detected = cell2mat({vessels_orig.side2}');
im_profiles_detected = cell2mat({vessels_orig.im_profiles}');
% Preallocate the output
vessels_matched = Vessel.empty(numel(true_centres), 0);
for ii = 1:numel(true_centres)
     % Create and initialize the output
     v = Vessel;
     coord_size = [numel(true_centres{ii})/2, 2];
     v.centre = nan(coord_size);
     v.side1 = nan(coord_size);
     v.side2 = nan(coord_size);
     % If no vessels detected, nothing more to do by add the vessel to the
     % output
     if isempty(centres_detected)
         % Add to the output vessel list
         vessels_matched(ii) = v;
         continue
     end
    
     % Compute the distance between true centres and all detected centres
     % The value at row R, column C gives the distance between the ground 
     % truth centre point R from the algorithm centre point C
    centre_distance_matrix = sqrt(bsxfun(@minus, centres_detected(:, 1)', true_centres{ii}(:, 1)).^2 + ...
                              bsxfun(@minus, centres_detected(:, 2)', true_centres{ii}(:, 2)).^2);
    % Keep values in the distance matrix only if the algorithm centre point is
    % closer to the ground truth point than any other
    is_closest = bsxfun(@eq, centre_distance_matrix, min(centre_distance_matrix, [], 1));
    centre_distance_matrix(~is_closest) = inf;
    % Now find the closest detected centre point for each ground truth point -
    % and assume none has been found if the algorithm point is closer to
    % any other ground truth point
    [min_distance, min_alg_ind] = min(centre_distance_matrix, [], 2);
    % In some cases, there might not be a valid detected point - perhaps
    % because the closest detected point is too far away, or else it is
    % closer to another true point anyway (and we don't want to use the
    % same point detected twice, because this will underestimate any error
    % measurement variability).  Apply a search for minimum points in a
    % circle around the true centre that has a radius equal to the vessel
    % diameter.
    detection_found = min_distance <= true_diameters{ii};% / 2;
    % Get the indices of where the detection was found
    detection_index = min_alg_ind(detection_found);
    
    % Copy in the appropriate centre and side points
    v.centre(detection_found, :) = centres_detected(detection_index, :);
    v.side1(detection_found, :) = side1_detected(detection_index, :);
    v.side2(detection_found, :) = side2_detected(detection_index, :);
    v.im_profiles(detection_found, :) = im_profiles_detected(detection_index, :);
    % Add to the output vessel list
    vessels_matched(ii) = v;
end



% Compute means and standard deviations, ignoring NaNs
% (The Statistics Toolbox has NANMEAN and NANSTD for this purpose, which
% take dimensions into consideration too)
function m = nan_mean(x)
m = mean(x(~isnan(x(:))));

function s = nan_std(x)
s = std(x(~isnan(x(:))));