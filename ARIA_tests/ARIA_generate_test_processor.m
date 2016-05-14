function args = ARIA_generate_test_processor(name)
% Generate a vessel processor used with the results published in 'Fast
% retinal vessel detection and measurement using wavelets and edge location
% refinement', and return its ARGS structure.
%
% Input:
%   NAME - the name of the processor to generate.  This must a string
%   giving one of the following:
%       - 'DRIVE' - for the DRIVE database images
%       - 'CLRIS' - for the Central Light Reflex Image Set (REVIEW)
%       - 'VDIS' - for the Vascular Disease Image Set (REVIEW)
%       - 'KPIS' - for the Kick Point Image Set (REVIEW)
%        'HRIS' - for the High Resolution Image Set (REVIEW)
%       - 'HRIS_downsample' - for the High Resolution Image Set,
%       downsampling the image by a factor of 4 (REVIEW)
%
% Output:
%   ARGS - the arguments structure associated with the processor.  It could
%   be saved for use in ARIA later using the command
%       save_vessel_processor('processor_name', args);
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% The default arguments for all processors
args = struct;
args.image_large_size = [1024 1024];
args.image_resize_factor = 1;
args.mask_option = 'create';
args.mask_erode = true;
args.iuwt_dark = true;
args.iuwt_inpainting = false;
args.iuwt_w_levels = 2:3;
args.iuwt_w_thresh = 0.20;
args.iuwt_px_remove = 0.05;
args.iuwt_px_fill = 0.05;
args.spline_piece_spacing = 10;
args.processor_function = 'aria_algorithm_general';
args.mask_dark_threshold = 30;
args.mask_bright_threshold = 255;
args.mask_largest_region = true;
args.centre_spurs = 10;
args.centre_min_px = 10;
args.centre_remove_extreme = true;
args.centre_clear_branches_dist_transform = false;
args.smooth_parallel = 2;
args.smooth_perpendicular = 0.1;
args.enforce_connectivity = true;

% Adjust properties as required
switch lower(name)
    case 'drive'
        args.iuwt_w_levels = 2:3;
        args.mask_dark_threshold = 10;
    case 'vdis'
        args.iuwt_w_levels = 3:4;
    case 'clris'
        args.iuwt_w_levels = 3:4;
    case 'hris'
        args.iuwt_w_levels = 3:5;
    case 'hris_downsample'
        args.iuwt_w_levels = 2;
        args.image_resize_factor = 0.25;
    case 'kpis'
        args.iuwt_w_levels = 2;
    otherwise
        error('Unknown processor name');
end