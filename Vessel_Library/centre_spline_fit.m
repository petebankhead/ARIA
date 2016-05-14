function [args, cancelled] = centre_spline_fit(vessel_data, args, prompt)
% Compute the centrelines for vessel segments from a binary image, then
% refine these using spline fitting and compute image profiles
% perpendicular to the vessel.  The length of the profiles is based on an
% estimate of the largest potential vessel in the image, as determined from
% the original binary image.
% 
% ARGS contents:
%   SPLINE_PIECE_SPACING - The approximate spacing that should occur
%   between spline pieces (in pixels).  A higher value implies fewer
%   pieces, and therefore a smoother spline fit (Default = 10).
%   CENTRE_SPURS - the length of spurs that should be removed from the
%   thinned vessel centrelines.  Because spurs are offshoots from the
%   centreline, they cause branches - which can lead to vessels being
%   erroneously sub-divided.  On the other hand, some spurs can really be
%   the result of actual vessel branches - and should probably be kept.
%   This parameter is a length (in pixels) that a spur must exceed for it
%   to be kept (Default = 10).
%   CENTRE_MIN_PX - the minimum length of a vessel segment centre
%   line for it to be kept. Must be >= 3 because of need for angles.  The
%   spur removal will only get rid of terminal segments, but very short
%   segments might remain between branches, in which case this parameter
%   becomes relevant (Default = 3).
%   CENTRE_REMOVE_EXTREME - TRUE if segments should be removed if a fast
%   estimate of their maximum diameter (from the binary image) is greater
%   than the number of pixels in their centreline.  Such segments are
%   usually not measureable vessels.  Keeping them can have a
%   disproportionate effect upon processing time, because longer image
%   profiles need to be computed for every vessel just to make sure that
%   enough pixels are included for these extreme segements (Default = TRUE).
% 
% 
% Required VESSEL_DATA properties: IM, BW
% Optional VESSEL_DATA properties: BW_MASK
%
% Set VESSEL_DATA properties: VESSEL_LIST 
%
% Set VESSEL properties: CENTER, ANGLES, IM_PROFILES, IM_PROFILES_ROWS, IM_PROFILES_COLS
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Set up default arguments
args_default.spline_piece_spacing = 10;
args_default.centre_spurs = 10;
args_default.centre_min_px = 10;
args_default.centre_remove_extreme = true;
args_default.centre_clear_branches_dist_transform = true;
cancelled = false;

% Update arguments if possible
if nargin >= 2 && isstruct(args)
    args = update_input_args(args, args_default);
else
    args = args_default;
end

% Prompt if necessary
if prompt
    questions = {sprintf('Minimum number of pixels for a centre line (e.g. 4)\nCentre lines with few pixels are unlikely to give meaningful measurements'), ...
                 sprintf('Length of spurs to remove (e.g. 10)\nMust be >= 1. Removes small offshoots from the binary image, which can cause vessels to be sub-divided'), ...
                 sprintf('Spacing between spline pieces in pixels (e.g. 10)\nMust be >= 5; may use a lower value for small images or tortuous vessels'), ...
                 };
    answers = {num2str(args.centre_min_px), ...
               num2str(args.centre_spurs), ...
               num2str(args.spline_piece_spacing)};
    answers = inputdlg(questions, 'Profile options', 1, answers);
    if isempty(answers)
        cancelled = true;
        return;
    end
    values = str2double(answers);
    if ~isnan(values(1))
        args.centre_min_px = max(round(values(1)), 0);
    end
    if ~isnan(values(2))
        args.centre_spurs = max(round(values(2)), 1);
    end
    if ~isnan(values(3))
        args.spline_piece_spacing = max(round(values(3)), 5);
    end
    % Prompt for using the distance transform to clear branches
    if args.centre_clear_branches_dist_transform
        clear_branches = 'Yes';
    else
        clear_branches = 'No';
    end
    clear_branches = questdlg(sprintf('Remove pixels close to branches?\nThis gives a cleaner result, but should not be selected if measurements close to branches are very important.'), ...
        'Clear branches', 'Yes', 'No', clear_branches);
    args.centre_clear_branches_dist_transform = strcmp(clear_branches, 'Yes');
end


%----------------------------

% Extract images and check they are the correct size
bw = vessel_data.bw;
im = vessel_data.im;
if isempty(bw) || isempty(bw) || ~isequal(size(bw), size(im))
    error('CENTRE_SPLINE_FIT requires binary and original images of the same size (i.e. BW and IM properites in VESSEL_DATA)');
end

%----------------------------

% Get thinned centreline segments
[vessels, dist_max] = thinned_vessel_segments(bw, args.centre_spurs, args.centre_min_px, ...
    args_default.centre_remove_extreme, args.centre_clear_branches_dist_transform);

%----------------------------

% Refine the centreline and compute angles by spline-fitting
vessels = spline_centreline(vessels, args.spline_piece_spacing, true);

%----------------------------

% Compute image profiles, using the distance transform of the segmented
% image to ensure the profile length will be long enough to contain the
% vessel edges
% % If there is no vessel diameter estimate already, could use this (though
% % it tends to over-estimate)
% % d = bwdist(~bw);
% % width = ceil(max(d(:)) * 4);
width = ceil(dist_max * 4);
if mod(width, 2) == 0
    width = width + 1;
end
% Make the image profiles - not using a mask here, since this plays havoc
% with later filtering because the filter smears out NaNs towards the
% vessel and can prevent the detection of perfectly good edges
make_image_profiles(vessels, im, width, '*linear');

%----------------------------

% Make sure the list in VESSEL_DATA is empty, then add the vessels
vessel_data.delete_vessels;
vessel_data.add_vessels(vessels);