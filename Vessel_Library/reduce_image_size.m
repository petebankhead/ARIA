function [args, cancelled] = reduce_image_size(vessel_data, args, prompt)
% Reduce the size of the images in VESSEL_DATA.
% For very large images, this makes it possible to work on a
% smaller, simpler version for faster processing.
% 
% NOTE:- If any other values (e.g. vessels, optic disc) have been set,
%        these will not be modified by this function.  Only the images are
%        changed.  It should therefore be applied prior to detection and
%        analysis.
%
% Required VESSEL_DATA properties: IM
%
% Optional VESSEL_DATA properties: IM_ORIG, BW, BW_MASK
% 
% ARGS contents: IMAGE_LARGE_SIZE - the minimum size an image needs to be
%                before it will be resized at all (since there is no point
%                shrinking a small image, or pestering the user unnecessarily).
%                IMAGE_RESIZE_FACTOR - the scale factor (should be .25, .5, .75
%                or 1)
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

cancelled = false;

%--------------------------------------------------------------------------

% Set default argument values
args_default.image_large_size = [1024, 1024];
args_default.image_resize_factor  = 0.5;

% Update arguments if possible
if nargin >= 2 && isstruct(args)
    args = update_input_args(args, args_default);
else
    args = args_default;
end

% Fix the scale factor if it's something else
valid_factors = [.25, .5, .75, 1];
if ~ismember(args.image_resize_factor, valid_factors)
    dist = abs(args.image_resize_factor(1) - valid_factors);
    [m, m_ind] = min(dist);
    args.image_resize_factor = valid_factors(m_ind);
end

%--------------------------------------------------------------------------

% Maybe there is no image at, or maybe it's not too big... check that first
if isempty(vessel_data.im) || all(size(vessel_data.im) < args.image_large_size)
    return;
end

%--------------------------------------------------------------------------

% Prompt for resize factor if required
if nargin < 3
    prompt = true;
end
if prompt
    
    siz = size(vessel_data.im);
    prompt = ['Image is currently ', num2str(siz(1)), ' x ', num2str(siz(2)), ' px'];
    options = {'No resize', '75%', '50%', '25%'};
    answer = dlg_option_buttons(prompt, options, 'Large image');
    
    switch answer
        case 0
            cancelled = true;
        case 1
            args.image_resize_factor = 1;
        case 2
            args.image_resize_factor = 0.75;
        case 3
            args.image_resize_factor = 0.5;
        case 4
            args.image_resize_factor = 0.25;
    end
end

%--------------------------------------------------------------------------

% Apply the resizing to all available images if required
if ~cancelled && args.image_resize_factor ~= 1
    factor = args.image_resize_factor;
    if ~isempty(vessel_data.im_orig)
        vessel_data.im_orig = imresize(vessel_data.im_orig, factor);
    end
    if ~isempty(vessel_data.im)
        vessel_data.im = imresize(vessel_data.im, factor);
    end
    if ~isempty(vessel_data.bw)
        vessel_data.bw = imresize(vessel_data.bw, factor);
    end
    if ~isempty(vessel_data.bw_mask)
        vessel_data.bw_mask = imresize(vessel_data.bw_mask, factor);
    end
end