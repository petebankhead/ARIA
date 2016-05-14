function [vessel_data, args, cancelled] = aria_algorithm_general(vessel_data, args, prompt)
% General vessel detection and analysis algorithm based on IUWT
% segmentation and gradient-based edge localization.
%
% Input:
%   VESSEL_DATA - a VESSEL_DATA object containing an image to process.
%   ARGS - a STRUCT containing any required input arguments
%   PROMPT - TRUE if the user should be prompted for required arguments
%   where possible, FALSE if the default (or previously saved values)
%   should be used instead.
%
% Output:
%   VESSEL_DATA - the same as the input, now with additional properties set
%   ARGS - the STRUCT containing the actual arguments that were used, which
%   may or may not be the same as the input ARGS
%   CANCELLED - TRUE if the user somehow cancelled the processing before it
%   was complete.
%
%
% Required VESSEL_DATA property: IM
%
% Optional VESSEL_DATA property: BW_MASK
%
% Set VESSEL_DATA properties: BW_MASK (possibly), BW, VESSEL_LIST
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Check for arguments
if nargin < 2 || ~isstruct(args) || isempty(args)
    args = struct;
end

% Find out whether to prompt for user input
if nargin < 3 || ~islogical(prompt)
    prompt = vessel_data.settings.prompt;
end

% See whether the image is large, and should be reduced for
% faster segmentation
[args, cancelled] = reduce_image_size(vessel_data, args, prompt);
if cancelled
    return;
end

% If there isn't a mask there already, choose whether to apply one
if isempty(vessel_data.bw_mask)
    [args, cancelled] = mask_choose(vessel_data, args, prompt);
    if cancelled
        return;
    end
end

% Segment the image using the isotropic undecimated wavelet transform
[args, cancelled] = seg_iuwt(vessel_data, args, prompt);
if cancelled
    return;
end

% Compute centre lines and profiles by spline-fitting
[args, cancelled] = centre_spline_fit(vessel_data, args, prompt);
if cancelled
    return;
end

% Do the rest of the processing, and detect vessel edges using a gradient
% method
[args, cancelled] = edges_max_gradient(vessel_data, args, prompt);
if cancelled
    return;
end

% Make sure NaNs are 'excluded' from summary measurements
vessel_data.vessel_list.exclude_nans;

% Store the arguments so that they are still available if the VESSEL_DATA
% object is saved later
vessel_data.args = args;