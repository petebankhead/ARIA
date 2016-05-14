function changed = display_colours_dlg(settings)
% Show a dialog for changing the display colours used for vessel diameters,
% edges, labels, optic disc etc.
% 
% Input:
%   SETTINGS - a VESSEL_SETTINGS object.
%
% Output:
%   CHANGED - TRUE if any colour was changed, otherwise FALSE.  This helps
%   decide whether a repaint is necessary after calling this.
% 
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Nothing changed initially
changed = false;

% Default sizes
button_width = 180;
button_height = 30;
colour_width = 30;

% Colour setting options
options = {'Diameters - valid', ...
           'Diameters - excluded', ...
           'Diameters - highlighted', ...
           'Centre lines', ...
           'Labels', ...
           'Vessel edges', ...
           'Optic disc'};
colours = {settings.col_diameters; ...
           settings.col_diameters_ex; ...
           settings.col_highlighted; ...
           settings.col_centre_line; ...
           settings.col_labels; ...
           settings.col_edges; ...
           settings.col_optic_disc};


% Initialise button and panel handle arrays
buttons = zeros(1, numel(options));
panels = zeros(1, numel(options));

% Calculate figure sizes
total_width = button_width + colour_width;
total_height = (numel(buttons) + 1) * button_height;

% Create figure
fig_pos = [0, 0, button_width + colour_width, total_height];
f = dialog('Visible', 'off', 'MenuBar', 'none', ...
           'Position', fig_pos, 'Name', 'Change colours', ...
           'CloseRequestFcn', @cancel_callback);


% Add colour buttons and panels
for ii = 1:numel(buttons)
    buttons(ii) = uicontrol(f, ...
        'Style', 'pushbutton', ...
        'String', options{ii}, ...
        'Position', [5, (numel(buttons)-ii+1)*button_height, button_width-10, button_height], ...
        'UserData', ii, ...
        'Callback', @button_callback);
    panels(ii) = uipanel(f, ...
        'BackgroundColor', colours{ii}, ...
        'Units', 'pixels', ...
        'Position', [button_width, (numel(buttons)-ii+1)*button_height+5, colour_width-5, button_height-10], ...
        'UserData', ii);
end

% Add apply/cancel buttons
button_apply = uicontrol(f, ...
    'Style', 'pushbutton', ...
    'String', 'Apply', ...
    'Position', [5, 0, total_width/2-10, button_height], ...
    'Callback', @apply_callback);
button_cancel = uicontrol(f, ...
    'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Position', [total_width/2+5, 0, total_width/2-10, button_height], ...
    'Callback', @cancel_callback);


% Centre and display figure, then wait for user input
movegui(f, 'center');
set(f, 'Visible', 'on');
uiwait(f);


    function button_callback(hObject, eventdata)
        ind = get(hObject, 'UserData');
        new_col = uisetcolor(colours{ind});
        if ~isequal(colours{ind}, new_col) && ~isequal(new_col, 0)
            changed = true;
            colours{ind} = new_col;
            set(panels(ind), 'BackgroundColor', new_col);
        end
%         close(f);
    end

    function apply_callback(hObject, eventdata)
        % If anything has changed, update the VESSEL_SETTINGS object
        if changed
            settings.col_diameters     = colours{1};
            settings.col_diameters_ex  = colours{2};
            settings.col_highlighted   = colours{3};
            settings.col_centre_line   = colours{4};
            settings.col_labels        = colours{5};
            settings.col_edges         = colours{6};
            settings.col_optic_disc    = colours{7};
        end
        delete(f);
    end

    function cancel_callback(hObject, eventdata)
        changed = false;
        delete(f);
    end
end