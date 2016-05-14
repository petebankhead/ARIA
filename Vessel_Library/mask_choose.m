function [args, cancelled] = mask_choose(vessel_data, args, prompt)
% Prompt the user to choose a field of view (FOV) mask for the image,
% either by creating it interactively or reading it from a file.
%
% Required VESSEL_DATA properties: IM
%
% Optional VESSEL_DATA properties: IM_ORIG
%
% Set VESSEL_DATA properties: BW_MASK
% 
% ARGS contents: MASK_OPTION - the type of mask to use, should be
%                'read_file' (if the mask is read from a saved file),
%                'create' (for interactive thresholding) or 'none' (for no
%                mask)
%                MASK_ERODE - TRUE if an erosion operation should be
%                applied to the mask.  This reduces its size by at least 2
%                pixels, or around 2.5% of the total FOV diameter for large
%                images.  This is usually a good idea, because the sharp
%                transition that often occurs at the boundary of the FOV 
%                can lead to erroneous detections.
%                MASK_DARK_THRESHOLD and MASK_BRIGHT_THRESHOLD - pixels
%                with values between these two thresholds will be
%                considered part of the FOV.
%                MASK_LARGEST_REGION - TRUE if the largest contiguous
%                region should be counted as the FOV.  FALSE if all
%                regions meeting the threshold criteria should be kept,
%                irrespective of size.
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Set CANCELLED
cancelled = true;

% Set up default input arguments in case none are available
args_default.mask_option = 'none';
args_default.mask_erode = true;
args_default.mask_dark_threshold = 0;
args_default.mask_bright_threshold = 1;
args_default.mask_largest_region = true;

% Update arguments if possible
if nargin >= 2 && isstruct(args)
    args = update_input_args(args, args_default);
else
    args = args_default;
end

prompt_string = ...
    ['Create a mask to exclude parts of the image from processing.', ...
    'This may improve accuracy.'];

list_options = {...
    'Read from file', ...
    'Create interactively', ...
    'No mask', ...
    };

% Ask user whether to use mask or not
if vessel_data.settings.prompt
    mask_option_number = dlg_option_buttons(prompt_string, list_options);
    % Update the ARGS structure or cancel
    switch mask_option_number
        case 0
            % Cancelled
            return;
        case 1
            args.mask_option = 'read_file';
        case 2
            args.mask_option = 'create';
        case 3
            args.mask_option = 'none';
    end
end


% Sort out the mask
cancelled = true;
switch args.mask_option
    case 'none'
        cancelled = false;
        return;
    case 'read_file'
        % Use last path if possible
        try
            path = vessel_data.settings.last_path;
        catch
            path = [];
        end
        % Read from file
        vessel_data.bw_mask = read_binary_image_from_file(size(vessel_data.im), ...
                                'Read mask (binary image)', path);
        % No mask read - must have cancelled
        if isempty(vessel_data.bw_mask)
            return;
        end
    case 'create'
        % Use first (red) plane of a colour image if available - usually contains
        % poor contrast for vessel detection, but good contrast for mask detection
        if ~isempty(vessel_data.im_orig)
            im = vessel_data.im_orig(:,:,1);
        else
            im = vessel_data.im;
        end
        if prompt
            % Pass arguments to DLG_MASK_PERCENT, a dialog showing options
            [bw_mask, args.mask_dark_threshold, args.mask_bright_threshold, args.mask_largest_region] = ...
                dlg_mask_percent(im, args.mask_dark_threshold, args.mask_bright_threshold, args.mask_largest_region);
        else
            bw_mask = mask_threshold(im, args.mask_dark_threshold, args.mask_bright_threshold, args.mask_largest_region);
        end
        % If we now have a mask, set it in the VESSEL_DATA object,
        % otherwise just return
        if isequal(size(bw_mask), size(im))
            vessel_data.bw_mask = bw_mask;
        else
            return;
        end
    otherwise
        disp(args.mask_option);
        error('MASK_CHOOSE: Invalid MASK_OPTION argument (should be read_file, create or none).');
end


% Can check with the user whether to erode the mask - this is generally a
% good idea
if nargin < 3
    prompt = true;
end
if prompt
    button = questdlg(sprintf('Shrink the mask (recommended)?\n This reduces the FOV slightly, but can improve detection at the boundary.'), ...
                      'Shrink mask', ...
                      'Yes', 'No', 'Yes');
    if strcmp(button, 'Yes')
        args.mask_erode = true;
    else
        args.mask_erode = false;
    end
end

% Erode mask by approximately 2.5% of diameter, or minimum of 5 px square
if args.mask_erode
    d1 = max(sum(vessel_data.bw_mask));
    d2 = max(sum(vessel_data.bw_mask, 2));
    d = max(d1, d2);
    siz = max(5, round(d * .025));
    vessel_data.bw_mask = imerode(vessel_data.bw_mask, ones(siz));
end

% Check again whether mask is completely empty
if ~any(vessel_data.bw_mask)
    vessel_data.bw_mask = [];
end

% Got this far without cancelling...
cancelled = false;