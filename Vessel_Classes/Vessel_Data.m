classdef Vessel_Data < hgsetget
    % VESSEL_DATA A container for all relevant data required to analyse
    % blood vessels in a 2D image.
    %   Holds display settings, images (raw, binary and mask), a vessel
    %   list, image file name and an index to a selected vessel in the
    %   list.
    %
    %
    % Copyright © 2011 Peter Bankhead.
    % See the file : Copyright.m for further details.
    
    
    % NOTE: For a while I set DoubleBuffering to OFF in IMSHOW.  This
    % caused fickering when I tried running the software recently (R2010a, 
    % Windows 64-bit), so DoubleBuffering is turned on again.  This might
    % be a problem on slower computers (I don't recall why I turned it off
    % originally...), so may need to be adjusted.
    
    
    %% Properties
    
    properties
        settings;  % Vessel_Settings object
        
        im_orig;   % Original image - may be colour, integer or real
        im;        % Grayscale image (main image for processing), should be real
        bw_mask;   % Mask image
        bw;        % Segmented image
        
        dark_vessels = true; % TRUE if vessel is dark, 
                             % i.e. represented by a 'valley' rather than a 'hill'
                             % Individual Vessels in a list have their own
                             % dark property, which override this one if set
        
        file_name; % Name of currently-open file
        file_path; % Path of currently-open file
        
        args;      % Structure containing the arguments used when processing the image originally, or else empty
    end
    
    properties (Dependent = true)
        selected_vessel_ind = -1; % Index in vessel_list of a vessel (just one)
        selected_vessel;   % Vessel corresponding to selected_vessel_ind
        calibration_value; % Calibration_value from Vessel_Settings
        num_vessels;       % Total number of vessels in list
        total_diameters;   % Total number of diameters in all vessels
    end
    
    properties (SetAccess = protected)
        vessel_list;       % Array of Vessel objects
    end
    
    properties
        optic_disc_centre   = []; % 2 element array, giving [row, col] of optic disc centre
        optic_disc_diameter = []; % scalar giving the optic disc diameter
        optic_disc_mask     = []; % 2 element array giving the number of diameters used for masking,
                                  % must obey optic_disc_mask(1) < optic_disc_mask(2)
    end
    
    % Store a unique (for this MATLAB session) ID in order to identify
    % whether a displayed figure is showing this Vessel_Data
    properties (SetAccess = private, Hidden = true, Transient = true)
        id_val = 0;
        % Store selected_vessel_ind in a separate variable
        val_selected_vessel_ind = -1;
    end
    properties (Dependent = true)
        id;
    end
    
    
    
    
    
    %% Constructor
    
    methods
        
        % Constructor
        function obj = Vessel_Data(settings)
            if nargin == 0
                obj.settings = Vessel_Settings;
                return;
            end
            if ~isa(settings, 'Vessel_Settings')
                throw(MException('Vessel_Data:Settings', ...
                    'Invalid settings passed to Vessel_Data constructor'));
            end
            obj.settings = settings;
        end
        
    end
    
    
    %% Display functions
    
    methods
        
                
        % Update image painting if the appropriate figure exists, otherwise
        % do nothing.  May be called when, for example, diameters are
        % changed by the calling function does not know whether a repaint
        % is required or not.
        % If the figure handle is known, it can be passed as H.
        % Can force a repaint, even if lines are already present, by
        % setting REPAINT_ALL to TRUE.
        % NOTE: This function only paints the lines, but does not show the
        % image itself (which is assumed to already be visible).
        function update_image_lines(obj, h, repaint_all)
            
            % Search for figure with the right name for this image
            if nargin < 2 || isempty(h) || ~ishandle(h)
                h = get_figure(obj);
                % If there is no figure, don't do anything
                if isempty(h)
                    return;
                end;
            end;
            % Make figure active
            set(0, 'CurrentFigure', h);
                        
            % Identify the lines and labels already present on the image
            lines = findobj(h, 'type', 'line');
            labels = findobj(h, 'type', 'text');
            rects = findobj(h, 'type', 'rectangle');
            
            % Don't repaint all by default
            if nargin < 3
                repaint_all = false;
            elseif repaint_all
                % Delete previous lines and labels if there
                delete(lines);
                delete(labels);
                delete(rects);
                lines = [];
                labels = [];
                rects = [];
            end
            
            % Check whether any vessels at all
            if obj.num_vessels == 0
                return;
            end

            
            % Only paint new lines if none already present
            if isempty(lines)
                % Paint optic disc, if it's available
                if ~isempty(obj.optic_disc_centre) && ~isempty(obj.optic_disc_diameter)
                    % Show optic disc as circle... which is a rectangle with very, very
                    % rounded corners
                    disc_rc = obj.optic_disc_centre;
                    diam = obj.optic_disc_diameter;
                    rectangle('Position', [disc_rc(2)-diam/2, disc_rc(1)-diam/2, diam, diam], ...
                        'Curvature', [1 1], 'EdgeColor', obj.settings.col_optic_disc, 'visible', 'off', 'tag', 'optic_disc');
                    
                    % If inner and outer mask regions are set, show them too
                    if ~isempty(obj.optic_disc_mask)
                        min_dist = (.5 + obj.optic_disc_mask(1)) * diam;
                        max_dist = (.5 + obj.optic_disc_mask(2)) * diam;
                        
                        % Show inner and outer regions
                        rectangle('Position', [disc_rc(2)-min_dist, disc_rc(1)-min_dist, min_dist*2, min_dist*2], ...
                            'Curvature', [1 1], 'EdgeColor', obj.settings.col_optic_disc, 'visible', 'off', 'tag', 'optic_disc');
                        rectangle('Position', [disc_rc(2)-max_dist, disc_rc(1)-max_dist, max_dist*2, max_dist*2], ...
                            'Curvature', [1 1], 'EdgeColor', obj.settings.col_optic_disc, 'visible', 'off', 'tag', 'optic_disc');
                    end
                end
                                
                % Somewhat convoluted but improves painting speed by rather
                % a lot (perhaps 5-10 times), and also improves toggling
                % visible / invisible speed.
                % Because centre lines and vessel edges will either all be
                % shown or none at all, each can be plotted as a single
                % 'line' object rather than separate objects for each
                % vessel.  To do so, they need to be converted into single
                % vectors, with NaN values where points should not be
                % connected (i.e. between vessels).
                % Paint centre lines
                fun = @(x) cat(1, x, [nan, nan]);
                temp = cellfun(fun, {obj.vessel_list.centre}, 'UniformOutput', false);
                cent = cell2mat(temp');
                line(cent(:,2), cent(:,1), 'Color', obj.settings.col_centre_line, 'linewidth', 1, ...
                    'visible', 'off', 'tag', 'vessel_centre');
                
                % Paint vessel edges lines
                temp = cellfun(fun, {obj.vessel_list.side1}, 'UniformOutput', false);
                side1 = cell2mat(temp');
                temp = cellfun(fun, {obj.vessel_list.side2}, 'UniformOutput', false);
                side2 = cell2mat(temp');
                line([side1(:,2) side2(:,2)], [side1(:,1) side2(:,1)], 'Color', obj.settings.col_edges, 'linewidth', 1, ...
                    'visible', 'off', 'tag', 'vessel_edge');
                
                % Loop through vessels to paint labels
                for ind = 1:numel(obj.vessel_list)
                    % Paint vessel numbers
                    c = obj.vessel_list(ind).centre(round(end/2),:) - [2,2];
                    text(c(2), c(1), num2str(ind), 'Margin', .1, 'Color', [1 1 1], 'BackgroundColor', obj.settings.col_labels, ...
                        'Interpreter', 'none', ...
                        'visible', 'off', 'tag', 'vessel_label', 'userdata', ind);
                end
                
                % Now get references to the lines and labels
                lines = findobj(h, 'type', 'line');
                rects = findobj(h, 'type', 'rectangle');
                labels = findobj(h, 'type', 'text');
            end
            
            % Adjust visibility for each option
            hand = findobj(rects, 'tag', 'optic_disc');
            if obj.settings.show_optic_disc
                set(hand, 'visible', 'on');
            else
                set(hand, 'visible', 'off');
            end
            hand = findobj(lines, 'tag', 'vessel_centre');
            if obj.settings.show_centre_line
                set(hand, 'visible', 'on');
            else
                set(hand, 'visible', 'off');
            end
            hand = findobj(labels, 'tag', 'vessel_label');
            if obj.settings.show_labels
                set(hand, 'visible', 'on');
            else
                set(hand, 'visible', 'off');
            end
            hand = findobj(lines, 'tag', 'vessel_edge');
            if obj.settings.show_edges
                set(hand, 'visible', 'on');
            else
                set(hand, 'visible', 'off');
            end
            
            % Get handle to selected vessel
            v = obj.selected_vessel;
            
            % Adjust visibility for currently selected diameters
            hand = findobj(lines, 'tag', 'vessel_diameter');
            if ~isempty(v)
                % Check whether currently selected diameters have been
                % painted, or if other ones have
                if ~isempty(hand)
                    % Assume that can't have more than one set of diameters
                    % showing, so only need to check first
                    ud = get(hand(1), 'userdata');
                    if obj.selected_vessel_ind ~= ud(1)
                        delete(hand);
                        hand = [];
                    end
                end
                % If haven't got any diameters painted, paint them now
                if isempty(hand) || repaint_all
                    ind = obj.selected_vessel_ind;
                    % Using a loop, sadly, but that way I can set the user
                    % data properly... just in case FINDOBJ returns the
                    % handles in an unexpected order ever
                    hand = zeros(size(v.side1,1), 1);
                    for ii = 1:size(v.side1,1)
                        hand(ii) = line([v.side1(ii,2)'; v.side2(ii,2)'], [v.side1(ii,1)'; v.side2(ii,1)'], ...
                            'color', obj.settings.col_diameters, 'linewidth', 1, ...
                            'visible', 'off', 'tag', 'vessel_diameter', 'userdata', [ind, ii]);
                    end
                end
                % Need to sort diameters
                ud = get(hand, 'userdata');
                if iscell(ud)
                    ud = cell2mat(ud);
                end
                [dum, sort_inds] = sort(ud(:,2));
                hand = hand(sort_inds);
                
                % If painting, colours and display spacing might not be right, so fix those
                % Need to sort handles first
                if obj.settings.show_diameters
                    % Set colours
                    k_inds = v.keep_inds;
                    if isempty(k_inds)
                        set(hand, 'color', obj.settings.col_diameters);
                    else
                        set(hand(~k_inds), 'color', obj.settings.col_diameters_ex);
                        set(hand(k_inds), 'color', obj.settings.col_diameters);
                    end

                    % Apply display resolution, unless set to 1
                    if obj.settings.show_spacing == 1
                        set(hand, 'visible', 'on');
                    else
                        set(hand, 'visible', 'off');
                        resolution_mask = false(v.num_diameters, 1);
                        res_inds = 1:obj.settings.show_spacing:numel(resolution_mask);
                        offset = floor((numel(resolution_mask) - res_inds(end)) / 2);
                        resolution_mask(res_inds + offset) = true;
                        set(hand(resolution_mask), 'visible', 'on');
                    end
                else
                    % Don't need to plot diameters, so hide any that are there
                    set(hand, 'visible', 'off');
                end
                
                % Always show selected if available and desired
                if obj.settings.show_highlighted && ~isempty(v.highlight_inds)
                    sel_inds = obj.selected_vessel.highlight_inds;
                    set(hand(sel_inds), 'color', obj.settings.col_highlighted, 'visible', 'on');
                end
            else
                % Don't need to plot diameters, so hide any that are there
                set(hand, 'visible', 'off');
            end
        end
        
        
        
        
        % Search for a figure showing the Vessel_Data
        % If none available, one will be created - but set to invisible
        function [h, created] = get_figure(obj, create)
            created = false;
            % Search for figure
            h = findobj('tag', obj.id);
            % If CREATE and no figure currently exists
            if nargin >= 2 && create && isempty(h)
                % If got a file name, use for figure name
                if isempty(obj.file_name)
                    h = figure('tag', obj.id);
                else
                    h = figure('Name', obj.file_name, 'NumberTitle','off', 'tag', obj.id, 'visible', 'off');
                end
                created = true;
            end
        end
        
        
        
        % TRUE if the vessel data is shown on a figure, FALSE otherwise
        function val = is_showing(obj)
            val = ~isempty(get_figure(obj, false));
        end
        
        
        
        % Show raw image including vessels painted on top
        function imshow(obj)
            % Search for figure, and create it if necessary
            [h, created] = get_figure(obj, true);
            % Get image to show
            if ~isempty(obj.settings) && obj.settings.show_orig && ~isempty(obj.im_orig)
                im2 = obj.im_orig;
            else
                im2 = obj.im;
            end
            % Can't show if no image there...
            if isempty(im2)
                return;
            end
            % Show image
            ax = findobj(obj.get_figure, 'type', 'axes');
            if isempty(ax) || created
                % Show image
                if isempty(ax)
                    figure(h);
                    imshow(im2, [], 'border', 'tight');
                else
                    imshow(im2, [], 'border', 'tight', 'parent', ax);
                end
                % Set axes properties to improve performance
                set(ax, 'ALimMode', 'manual', ...
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
            else
                % If figure was already showing, would be a bit faster just
                % to update the CDATA, but then the colour map can be
                % wrong.. not sure how best to fix this, so just do
                % IMSHOW for now
                imshow(im2, [], 'border', 'tight', 'parent', ax);
%                 set(findobj(ax, 'type', 'image'), 'CData', im2, 'CDataMapping', 'scaled');
            end
            set(h, 'NextPlot', 'new');
            % Set double buffering in parent figure as required
            if ~isempty(obj.settings)
                if (obj.settings.double_buffer)
                    set(h, 'DoubleBuffer', 'on');
                else
                    set(h, 'DoubleBuffer', 'off');
                end
            end

            % Update painted lines
            update_image_lines(obj, h);
            % Make visible if newly created
            set(h, 'visible', 'on');
        end
        
        
        
        % Sets the HIGHLIGHT_INDS of the currently selected vessel
        % Won't work if VAL is in the wrong format (checked by VESSEL
        % object - see code there for details)
        function set_highlight_inds(obj, val)
            if ~isempty(obj.selected_vessel)
                obj.selected_vessel.highlight_inds = val;
                update_image_lines(obj);
                obj.selected_vessel.update_plot;
            end
        end
                
    end
    
    
    
    %% VESSEL_LIST functions
    
    methods
        
        % Remove NaNs from vessels and remove vessels with < MIN_DIAMETERS
        % valid diameter measurements
        function clean_vessel_list(obj, min_diameters)
            for ii = 1:obj.num_vessels
                obj.vessel_list(ii).remove_nans;
            end
            if nargin == 1
                min_diameters = [];
            end
            obj.remove_short_vessels(min_diameters);
        end
        
        
        % Add vessels to vessel list
        function add_vessels(obj, v)
            for ii = 1:numel(v)
                v(ii).vessel_data = obj;
            end
            if isempty(obj.vessel_list)
                obj.vessel_list = v;
            else
                obj.vessel_list = [obj.vessel_list, v(:)'];
            end
            %             obj.vessel_list = [obj.vessel_list v];
        end
        
        
        % Remove vessels specified by INDS (no error checking)
        % If INDS is empty or not supplied, deletes all vessels
        function delete_vessels(obj, inds)
            if nargin == 1 || isempty(inds)
                obj.vessel_list = [];
            else
                obj.vessel_list(inds) = [];
            end
            % Update the image if displayed
            obj.update_image_lines([], true);
        end
        
        
        % Keep only vessels in list specified by INDS (no error checking)
        function trim_vessels(obj, inds)
            obj.vessel_list = obj.vessel_list(inds);
        end
        
        
        % Remove vessels with <= MIN_DIAMETERS valid diameter measurements
        function remove_short_vessels(obj, min_diameters)
            if isempty(obj.vessel_list)
                return;
            end
            if nargin == 1 || isempty(min_diameters)
                min_diameters = 0;
            end
            inds_remove = [obj.vessel_list.num_diameters] <= min_diameters;
            obj.delete_vessels(inds_remove);
        end
        
        
        
        % Sort the vessel list so that longest is first
        function sort_by_length(obj)
            n = obj.num_vessels;
            if n <= 1
                return;
            end
            len = zeros(n, 1);
            for ii = 1:n
                len(ii) = obj.vessel_list(ii).offset(end);
            end
            % Get selected vessel to reselect after sorting
            sel_ind = obj.val_selected_vessel_ind;
            % Temporarily deselect any vessel
            obj.val_selected_vessel_ind = -1;
            % There's a chance vessels already sorted, then don't need to
            % repaint
            [dum, inds] = sort(len,'descend');
            if ~issorted(inds)
                obj.vessel_list = obj.vessel_list(inds);
                % Reset selected vessel
                if sel_ind > 0
                    obj.val_selected_vessel_ind = find(inds == sel_ind);
                end
                % Do repaint
                update_image_lines(obj, [], true);
            end
        end
        
        
        
        % Sort the vessel list by average diameter, so widest is first
        function sort_by_diameter(obj)
            n = obj.num_vessels;
            if n <= 1
                return;
            end
            d = zeros(n, 1);
            for ii = 1:n
                d(ii) = mean(obj.vessel_list(ii).diameters);
            end
            % Get selected vessel to reselect after sorting
            sel_ind = obj.val_selected_vessel_ind;
            % Temporarily deselect any vessel
            obj.val_selected_vessel_ind = -1;
            % There's a chance vessels already sorted, then don't need to
            % repaint
            [dum, inds] = sort(d,'descend');
            if ~issorted(inds)
                obj.vessel_list = obj.vessel_list(inds);
                % Reset selected vessel
                if sel_ind > 0
                    obj.val_selected_vessel_ind = find(inds == sel_ind);
                end
                % Do repaint
                update_image_lines(obj, [], true);
            end
        end
        
    end
    
    
    
    
    %% GET and SET methods
    methods
        
       function val = get.id(obj)
            persistent counter;
            if obj.id_val <= 0
                if isempty(counter)
                    counter = 1;
                else
                    counter = counter + 1;
                end
                obj.id_val = counter;
            end
            val = ['vessel_data:', num2str(obj.id_val)];
        end
        
        
        % Ensure ARGS is a STRUCT or empty
        function set.args(obj, val)
            if isstruct(val) || isempty(val)
                obj.args = val;
            end
        end
        
        function val = get.selected_vessel(obj)
            ind = obj.selected_vessel_ind;
            if ind > 0 && ind <= numel(obj.vessel_list)
                val = obj.vessel_list(ind);
            else
                val = [];
            end
        end
        
        
        function val = get.calibration_value(obj)
            val = obj.settings.calibration_value;
        end
        
        
        function val = get.num_vessels(obj)
            val = numel(obj.vessel_list);
        end
        
        
        function val = get.total_diameters(obj)
            if obj.num_vessels <= 0
                val = 0;
            else
                val = sum([obj.vessel_list.num_diameters]);
            end
        end
        
        
        function val = get.selected_vessel_ind(obj)
            val = obj.val_selected_vessel_ind;
        end
        
        
        function set.selected_vessel_ind(obj, val)
            % Check different from currently selected
            % If no, don't do anything.  If yes, remove HIGHLIGHT_INDS from
            % currently selected vessel
            prev_ind = obj.selected_vessel_ind;
            if val == prev_ind
                return;
            end
            % Deal with previously selected vessel if necessary
            if prev_ind > 0 && prev_ind <= obj.num_vessels
                prev_vessel = obj.vessel_list(prev_ind);
                prev_vessel.highlight_inds = [];
                prev_vessel.update_plot;
            end
            % Deal with newly selected vessel if necessary
            if val > 0 && val <= obj.num_vessels
                obj.val_selected_vessel_ind = val;
                new_vessel = obj.vessel_list(val);
                new_vessel.highlight_inds = [];
                new_vessel.update_plot;
            else
                obj.val_selected_vessel_ind = -1;
            end
            % Update image if displayed
            update_image_lines(obj);
        end
    end
    
    
    
    
    %% PROTECTED functions
    
    methods (Access = protected)
        % Resizes all currently set fields.  Images are tested first to see
        % if they require the resize.
        % This is called whenever the IM property is set to an image of a
        % different size.
        function do_resize(obj, old_size, new_size)
            % Don't do anything if sizes are the same
            if isequal(old_size, new_size)
                return;
            end
            % Resize images
            if ~isempty(obj.im) && ~isequal(obj.im, new_size)
                obj.im = imresize(obj.im, new_size);
            end
            if ~isempty(obj.bw_mask) && ~isequal(obj.bw_mask, new_size)
                obj.bw_mask = imresize(obj.bw_mask, new_size);
            end
            if ~isempty(obj.bw) && ~isequal(obj.bw, new_size)
                obj.bw = imresize(obj.bw, new_size);
            end
            % Resize vessels
            scale_factor = new_size ./ old_size;
            for ii = 1:obj.num_vessels
                obj.vessel_list(ii).do_scale(scale_factor);
            end
        end
        
    end
    
    
    
    
    %% Optic disc functions
    
    methods
        
        function set.optic_disc_centre(obj, val)
            if numel(val) == 2
                obj.optic_disc_centre = val(:)';
            end
        end
        

        function set.optic_disc_diameter(obj, val)
            if isscalar(val) && val > 0
                obj.optic_disc_diameter = val;
            end
        end
        
        function set.optic_disc_mask(obj, val)
            if numel(val) == 2 && val(1) < val(2)
                obj.optic_disc_mask = val(:)';
            end
        end
        
    end
    
    
    
    
    %% LOAD, SAVE and DUPLICATE functions
    
    % Save and load methods
    methods (Static)
        function obj = loadobj(obj)
            if isstruct(obj) || isa(obj, 'Vessel_Data')
                % Call default constructor
                new_obj = Vessel_Data;
                % Assign property values
                new_obj.settings    = obj.settings;
                new_obj.im_orig     = obj.im_orig;
                new_obj.im          = obj.im;
                new_obj.bw_mask     = obj.bw_mask;
                new_obj.bw          = obj.bw;
                new_obj.selected_vessel_ind = obj.selected_vessel_ind;
                new_obj.dark_vessels = obj.dark_vessels;
                new_obj.file_name   = obj.file_name;
                new_obj.file_path   = obj.file_path;
                new_obj.vessel_list = obj.vessel_list;
                new_obj.optic_disc_centre   = obj.optic_disc_centre;
                new_obj.optic_disc_diameter = obj.optic_disc_diameter;
                new_obj.optic_disc_mask     = obj.optic_disc_mask;
                new_obj.args        = obj.args;
                % Individually set Vessel_Data properties of vessel_list
                for ii = 1:numel(obj.vessel_list)
                    new_obj.vessel_list(ii).vessel_data = new_obj;
                end
                % Return new object
                obj = new_obj;
            end
        end
    end
    
    methods
        
        % Create a duplicate Vessel_Data object
        function new_obj = duplicate(obj)
            if isa(obj, 'Vessel_Data')
                % Call default constructor
                new_obj = Vessel_Data;
                % Assign property values
                new_obj.settings     = obj.settings;
                new_obj.im_orig      = obj.im_orig;
                new_obj.im           = obj.im;
                new_obj.bw_mask      = obj.bw_mask;
                new_obj.bw           = obj.bw;
                new_obj.selected_vessel_ind = obj.selected_vessel_ind;
                new_obj.dark_vessels = obj.dark_vessels;
                new_obj.file_name    = obj.file_name;
                new_obj.file_path    = obj.file_path;
                new_obj.optic_disc_centre   = obj.optic_disc_centre;
                new_obj.optic_disc_diameter = obj.optic_disc_diameter;
                new_obj.optic_disc_mask     = obj.optic_disc_mask;
                new_obj.args         = obj.args;
                % Need to individually copy vessel list
                new_obj.vessel_list = Vessel.empty(numel(obj.vessel_list), 0);
                for ii = numel(obj.vessel_list):-1:1
                    if ii == numel(obj.vessel_list)
                        new_obj.vessel_list(ii) = obj.vessel_list(ii).duplicate;
                    else
                        obj.vessel_list(ii).duplicate(new_obj.vessel_list(ii));
                    end
                end
            else
                throw(MException('Vessel_Data:dupicate', ...
                    'Not a Vessel_Data object passed to Vessel_Data.duplicate'));
            end
        end
        
        
        function obj = saveobj(obj)
            % Create and save structure
            s.settings     = obj.settings;
            s.im_orig      = obj.im_orig;
            s.im           = obj.im;
            s.bw_mask      = obj.bw_mask;
            s.bw           = obj.bw;
            s.selected_vessel_ind = obj.selected_vessel_ind;
            s.dark_vessels = obj.dark_vessels;
            s.file_name    = obj.file_name;
            s.file_path    = obj.file_path;
            s.vessel_list  = obj.vessel_list;
            s.optic_disc_centre   = obj.optic_disc_centre;
            s.optic_disc_diameter = obj.optic_disc_diameter;
            s.optic_disc_mask     = obj.optic_disc_mask;
            s.args         = obj.args;
            obj = s;
        end
    end
    
end