function [args, cancelled] = edges_max_gradient(vessel_data, args, prompt)
% Identify vessel edges from image profiles based upon local steepness.
% 
% First, compute the profiles perpendicular to each vessel according to
% the centre points and angles already stored in VESSEL_DATA.VESSEL_LIST.
% Then set the vessel edges based upon zero crossings of the 2nd derivative
% perpendicular to the vessel.  Gaussian filtering is used for smoothing,
% where the filter size relates to a provisional vessel diameter estimate.
% The smoothing is applied to the image profiles (rather than the original
% image directly), and separably along the columns (parallel to the vessel)
% and rows (perpendicular to the vessel) of the images profiles.
%
% The sigma value for the Gaussian filtering is determined individually for
% each vessel based upon an estimate of the vessel width made first from
% the segmented image VESSEL_DATA.BW, and then refined from the mean of all
% the profiles computed for that vessel.
%
%
% Required VESSEL_DATA properties: BW, VESSEL_LIST
%
% Optional VESSEL_DATA properties: BW_MASK
%
% Required VESSEL properties: IM_PROFILES, IM_PROFILES_ROWS, IM_PROFILES_COLS
%
% Set VESSEL properties: SIDE1, SIDE2
% 
% ARGS contents:
%   SMOOTH_PARALLEL and SMOOTH_PERPENDICULAR are scaling parameters that
%   multiply the estimate width computed for the vessel under consideration to
%   determine how much smoothing is applied (Default SMOOTH_PARALLEL = 1,
%   SMOOTH _PERPENDICULAR = 0.1).
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Set up default arguments
args_default.smooth_parallel = 1;
args_default.smooth_perpendicular = 0.1;
args_default.enforce_connectivity = true;
cancelled = false;

% Update arguments if possible
if nargin >= 2 && isstruct(args)
    args = update_input_args(args, args_default);
else
    args = args_default;
end

% Prompt if necessary
if prompt
    questions = {sprintf('Smoothing scale for Gaussian smoothing parallel to vessel (e.g. 0.5)\nHigher values can help in noisy images, but result in less sensitivity to vessel width changes\nThis scales the sigma value of the Gaussian filter, which is estimated from the vessel width.'), ...
                 sprintf('Smoothing scale for Gaussian smoothing perpendicular to vessel (e.g. 0.1)\nHigher values can help in noisy images, but will affect absolute measurements.\nTherefore similar values should be used for similar images if the results should be comparable.'), ...
                 };
    answers = {num2str(args.smooth_parallel), ...
               num2str(args.smooth_perpendicular)};
    answers = inputdlg(questions, 'Additional options', 1, answers);
    if isempty(answers)
        cancelled = true;
        return;
    end
    values = str2double(answers);
    if ~isnan(values(1))
        args.smooth_parallel = max(values(1), 0);
    end
    if ~isnan(values(2))
        args.smooth_perpendicular = max(values(2), 0);
    end
    % Prompt for connectivity
    if args.enforce_connectivity
        enforce = 'Yes';
    else
        enforce = 'No';
    end
    enforce = questdlg(sprintf('Apply connectivity constraint for edge location?\nThis can give better results, but may also lead to more vessels being missed.'), ...
        'Edge connectivity', 'Yes', 'No', enforce);
    args.enforce_connectivity = strcmp(enforce, 'Yes');
end


%--------------------------------------------------------------------------

% Extract the properties we need
vessels = vessel_data.vessel_list;
bw = vessel_data.bw;
bw_mask = vessel_data.bw_mask;

%--------------------------------------------------------------------------

% Determine vessel edges
set_edges_2nd_derivative(vessels, bw, bw_mask, args.smooth_parallel, args.smooth_perpendicular, args.enforce_connectivity);

%--------------------------------------------------------------------------

% Add vessels to list, and clean out any vessels where edges couldn't be
% found
vessel_data.clean_vessel_list(1);