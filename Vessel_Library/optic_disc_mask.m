function [args, cancelled] = optic_disc_mask(vessel_data, args, prompt)
% Prompt the user to draw a line across the optic disc, and optionally
% apply a mask to remove diameters outside a fixed distance from the disc
% (defined in terms of disc diameters).
%
% Required VESSEL_DATA properties: IM
% Optional VESSEL_DATA properties: VESSEL_LIST
%
% Set VESSEL_DATA properties: OPTIC_DISC_MASK,  OPTIC_DISC_DIAMETER,
% OPTIC_DISC_CENTRE
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Set up default input arguments in case none are available
args_default.min_discs = .5;
args_default.max_discs = 1;
args_default.apply_mask = false;

% Prompt by default in this case
if nargin < 3 || isempty(prompt)
    prompt = true;
end

% Update arguments if possible
if nargin >= 2 && isstruct(args)
    args = update_input_args(args_default, args);
else
    args = args_default;
end

cancelled = true;

% Show message telling the user what to do
h_msg = msgbox(['Draw a line across the diameter of the optic disc.', char(10), ...
    'Click the image once for the first point, double click for the second.', char(10), ...
    '(Click OK to remove this window first)'], ...
    'Optic disc selection', 'modal');
uiwait(h_msg);

% Show image - labels and any previous optic discs will get in the way,
% so at least temporarily disable
old_labels = vessel_data.settings.show_labels;
old_od = vessel_data.settings.show_optic_disc;
vessel_data.settings.show_labels = false;
vessel_data.settings.show_optic_disc = false;
vessel_data.imshow;
vessel_data.settings.show_labels = old_labels;
vessel_data.settings.show_optic_disc = old_od;

% Get handle to figure
h = vessel_data.get_figure;

% Make modal to prevent the user changing anything else
win_style = get(h, 'WindowStyle');
set(h, 'WindowStyle', 'modal');

while true
    % If the figure has been closed, need to cancel
    if ~ishandle(h)
        return;
    end
    % Get line drawn through diameter - it's possible the user will close
    % the window first, in which case should catch the error and close
    try
        [x, y] = getline(h);
        % GETLINE can mess up some settings... so fix those
        set(findobj(h, 'type', 'axes'), ...
                    'ALimMode', 'manual', ...
                    'CLimMode', 'manual', ...
                    'DataAspectRatioMode', 'manual', ...
                    'Drawmode', 'fast', ...
                    'PlotBoxAspectRatioMode', 'manual', ...
                    'TickDirMode', 'manual', ...
                    'XLimMode', 'manual', ...
                    'YLimMode', 'manual', ...
                    'ZLimMode', 'manual', ...
                    'XTickMode', 'manual', ...
                    'YTickMode', 'manual', ...
                    'ZTickMode', 'manual', ...
                    'XTickLabelMode', 'manual', ...
                    'YTickLabelMode', 'manual', ...
                    'ZTickLabelMode', 'manual');
    catch
        return;
    end
    
    % Test whether the line has the correct number of points
    if numel(x) ~= 2
        button = questdlg(['Marking the optic disc diameter requires exactly 2 points.', char(10), ...
            'Click the image once to set the first point, double-click to set the second.'],...
            'Optic disc mask','Try again','Cancel','Try again');
        if strcmp(button, 'Cancel')
            return;
        else
            continue;
        end
    else
        break;
    end
end

% Get optic disc centre on [row, col] form
disc_rc = [sum(y)/2, sum(x)/2];

% Get length of diameter
diam = sqrt(diff(y).^2 + diff(x).^2);

% Show optic disc as circle... which is a rectangle with very, very
% rounded corners
rectangle('Position', [disc_rc(2)-diam/2, disc_rc(1)-diam/2, diam, diam], ...
    'Curvature', [1 1], 'EdgeColor', 'g', 'tag', 'temp_optic_disc');


% To apply a mask, need minimum and maximum diameters
set_mask = false;
if args.apply_mask
    set_mask = true;
    vessel_data.optic_disc_mask = [args.min_discs, args.max_discs];
elseif  prompt
    while true
        answer = inputdlg({'Minimum number of optic disc diameters (must be >= 0)', ...
                    'Maximum number of optic disc diameters (must be larger than minimum)'}, ...
                    'Optic disc diameter mask', ...
                    1, ...
                    {num2str(args_default.min_discs), ...
                     num2str(args_default.max_discs)});
        if isempty(answer)
            break;
        end
        % Convert the input, and store if valid
        a1 = str2double(answer{1});
        a2 = str2double(answer{2});
        if a1 > 0 && a1 < a2
            args.min_discs = a1;
            args.max_discs = a2;
            set_mask = true;
            vessel_data.optic_disc_mask = [args.min_discs, args.max_discs];
            break;
        end
    end
end

% Set optic disc parameters in VESSEL_DATA
vessel_data.optic_disc_centre = disc_rc;
vessel_data.optic_disc_diameter = diam;

% If a mask was set, paint it and ask whether to delete other diameters
args_default.apply_mask = false;
if set_mask && prompt
    % Get minimum and maximum distances from optic disc
    min_dist = (.5 + args.min_discs) * diam;
    max_dist = (.5 + args.max_discs) * diam;

    % Show inner and outer regions
    rectangle('Position', [disc_rc(2)-min_dist, disc_rc(1)-min_dist, min_dist*2, min_dist*2], ...
        'Curvature', [1 1], 'EdgeColor', 'r', 'tag', 'temp_optic_disc');
    rectangle('Position', [disc_rc(2)-max_dist, disc_rc(1)-max_dist, max_dist*2, max_dist*2], ...
        'Curvature', [1 1], 'EdgeColor', 'r', 'tag', 'temp_optic_disc');


    % Confirm whether or not to accept the optic disc as drawn
    button = questdlg('Delete diameters outside the region marked in red?',...
        'Optic disc mask','Yes','No','No');
    
    args_default.apply_mask = strcmp(button, 'Yes');
end


% Change windowstyle back
set(h, 'WindowStyle', win_style);

% Delete the drawn lines
delete(findobj(h, 'tag', 'temp_optic_disc'));

% Do the actual mask application
if args_default.apply_mask
    % Loop through and remove all diameters outside range
    for ii = 1:vessel_data.num_vessels
        % Get vessel
        v = vessel_data.vessel_list(ii);
        % Compute distance of centre line point from optic disc centre
        disc_dist = sqrt(sum(bsxfun(@minus, v.centre, disc_rc).^2, 2));
        % Keep only those within acceptable distance range
        inds_remove = disc_dist < min_dist | disc_dist > max_dist;
        % Remove if not acceptable... easiest way is to set NaN values then
        % call VESSEL_DATA.CLEAN_VESSEL_LIST
        v.centre(inds_remove, :) = NaN;
    end
    vessel_data.clean_vessel_list;
else
    vessel_data.update_image_lines([], true);
end

% Got this far without cancelling
cancelled = false;