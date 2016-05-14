function [args, cancelled] = seg_iuwt(vessel_data, args, prompt)
% Segment an image using the Isotropic Undecimated Wavelet Transform (IUWT,
% or 'a trous' transform).
% 
% Required VESSEL_DATA properties: IM
% Optional VESSEL_DATA properties: BW_MASK
% Set VESSEL_DATA properties:      BW
% 
% ARGS contents:
%   IUWT_DARK - TRUE if vessels are darker than their surroundings (e.g.
%   fundus images), FALSE if they are brighter (e.g. fluorescein
%   angiograms; default FALSE).
%   IUWT_INPAINTING - TRUE if pixels outside the FOV should be replaced
%   with the closest pixel values inside before computing the IUWT.  This
%   reduces boundary artifacts.  It is more useful with fluorescein
%   angiograms, since the artifacts here tend to produce bright features
%   that are more easily mistaken for vessels (default FALSE).
%   IUWT_W_LEVELS - a numeric vector containing the wavelet levels that
%   should (default 2-3).
%   IUWT_W_THRESH - threshold defined as a proportion of the pixels in the
%   image or FOV (default 0.2, which will detect ~20% of the pixels).
%   IUWT_PX_REMOVE - the minimum size an object needs to exceed in order to
%   be kept, defined as a proportion of the image or FOV (default 0.05).
%   IUWT_PX_FILL - the minimum size of a 'hole' (i.e. an undetected region
%   entirely surrounded by detected pixels), defined as a proportion of the
%   image or FOV.  Smaller holes will be filled in (default 0.05).
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

%--------------------------------------------------------------------------

% Set up default input arguments in case none are available
args_default.iuwt_dark = true;
args_default.iuwt_inpainting = false;
args_default.iuwt_w_levels  = 2:3;
args_default.iuwt_w_thresh  = 0.2;
args_default.iuwt_px_remove = 0.05;
args_default.iuwt_px_fill   = 0.05;

% Update arguments if possible
if nargin >= 2 && isstruct(args)
    args = update_input_args(args, args_default);
else
    args = args_default;
end

%--------------------------------------------------------------------------

% Set cancelled by default
cancelled = true;

% Prompt by default
if nargin < 3
    prompt = true;
end
if prompt
    % Pass arguments to DLG_IUWT to allow interactive threshold setting
    [bw, args.iuwt_dark, args.iuwt_w_levels, args.iuwt_w_thresh] = dlg_iuwt(...
                vessel_data.im, vessel_data.bw_mask, args.iuwt_dark, ...
                args.iuwt_w_levels, args.iuwt_w_thresh, args.iuwt_inpainting);
    % No binary image - probably cancelled
    if isempty(bw)
        return;
    end
    % Interactive object removal & hole filling
    [bw, args.iuwt_px_remove, args.iuwt_px_fill] = dlg_clean_segmented(bw, args.iuwt_px_remove, args.iuwt_px_fill, vessel_data.bw_mask);
    if isempty(bw)
        return;
    else
        vessel_data.bw = bw;
    end
else
    % Use default values
    % Use distance transform for basic inpainting to improve wavelet transform
    % calculation if using a mask
    if ~isempty(vessel_data.bw_mask) && args.iuwt_inpainting
        im = dist_inpainting(vessel_data.im, vessel_data.bw_mask);
    else
        im = vessel_data.im;
    end
    % Compute IUWT and do segmentation
    w = iuwt_vessels(im, args.iuwt_w_levels);
    vessel_data.bw = percentage_segment(w, args.iuwt_w_thresh, args.iuwt_dark, vessel_data.bw_mask);
    % Get total number of pixels to convert percentages
    if ~isempty(vessel_data.bw_mask)
        scale = nnz(vessel_data.bw_mask) / 100;
    else
        scale = numel(vessel_data.bw) / 100;
    end
    % Remove small objects and fill holes
    vessel_data.bw = clean_segmented_image(vessel_data.bw, args.iuwt_px_remove * scale, args.iuwt_px_fill * scale);
end

% Set DARK property of vessel_data
vessel_data.dark_vessels = args.iuwt_dark;

% Got this far, mustn't have cancelled
cancelled = false;