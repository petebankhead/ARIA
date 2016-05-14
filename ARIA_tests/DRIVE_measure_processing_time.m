function [processing_time, vessel_data] = DRIVE_measure_processing_time(processor, overlay_file_name)
% Apply an ARIA processor to all DRIVE database test images and measure the
% timing.  Optionally store the detected vessel edges as overlays on top of
% the manually-segmented images.
% 
% Input:
%   PROCESSOR - the name of (or path to) the .vessel_processor file
%   that should be applied, or its ARGS structure.
%   OVERLAY_FILE_NAME - (optional) the base file name for vessel edge
%   overlay images, if desired.  If this argument is missing or empty, no
%   such images are saved.  If the argument does not contain a full file
%   path, the images are saved in a subdirectory of the directory
%   containing this M file.
%
% Output:
%   PROCESSING_TIME - a vector containing processing times, in seconds, for
%   each image
%   VESSEL_DATA - an array of vessel data objects (one for each image
%   processed)
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


%% CHECK INPUT

% Check whether to do the overlays or not
do_overlay = nargin >= 2 && ~isempty(overlay_file_name) && ischar(overlay_file_name);

%% DETERMINE DIRECTORIES

% If OVERLAY_FILE_NAME doesn't include a full path, store the resulting
% images in a sub-directory of the one containing this M file
if do_overlay && isempty(fileparts(overlay_file_name))
    dir_output = [fileparts(mfilename('fullpath')), filesep, 'Comparison of ARIA and manual', filesep];
    if ~exist(dir_output, 'dir')
        mkdir(dir_output);
    end
    overlay_file_name = [dir_output, overlay_file_name];
end

% Get the directory for the drive database
dir_DRIVE = get_vessel_database_directory('DRIVE');

% Get the test directory
dir_DRIVE_test = [dir_DRIVE, filesep, 'test', filesep];

% Initialize directory names
dir_im = [dir_DRIVE_test, 'images', filesep];
dir_man1 = [dir_DRIVE_test, '1st_manual', filesep];

% Get the names of the files
fn_im = dir([dir_im, '*.tif']);
fn_man1 = dir([dir_man1, '*.gif']);


%% LOOP THROUGH THE FILES

% Create one Vessel_Settings object to use throughout, and adjust it for the
% desired display
settings = Vessel_Settings;
settings.show_centre_line = false;
settings.show_diameters = false;
settings.show_edges = true;
settings.show_labels = false;
settings.col_edges = [0 0 0];

% Loop through each file - assume correct numbers found, and the order is
% also correct
% (Can go in descending order to avoid preallocation)
for ii = numel(fn_im):-1:1
    
    % Apply the processing
    file_name = [dir_im, fn_im(ii).name];
    [vessel_data(ii), processing_time(ii)] = Vessel_Data_IO.load_from_file(file_name, processor, settings);
    
    % If don't want to show the overlay, just continue
    if ~do_overlay
        continue;
    end
    
    % Read the manually segmented image
    im_manual = 255 - imread([dir_man1, fn_man1(ii).name]);
    
    % Create a version of the manually-segmented image with vessels in red
    im_manual = repmat(im_manual, [1 1 3]);
    im_manual(:, :, 1) = 255;
    
    % Temporarily replace the image in VESSEL_DATA in order to show a
    % version of the manual image with vessel edges on top
    im_temp = vessel_data(ii).im;
    vessel_data(ii).im = im_manual;
    imshow(vessel_data(ii));
    % Update the figure properties
    set(findobj(gca, 'type', 'line'), 'linewidth', 1);
    set(gcf, 'PaperPositionMode', 'auto');
    % Save a the output file
    [dum, f_base_name] = fileparts(fn_im(ii).name);
    saveas(gcf, [overlay_file_name, f_base_name, '.pdf']);
    close(gcf);
    
    % Return the VESSEL_DATA to its original state
    vessel_data(ii).im = im_temp;
end