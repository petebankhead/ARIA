classdef Vessel < handle
    % A VESSEL object is a container for all data and functions relating 
    % to a vessel or vessel segment.
    %
    %
    % Copyright © 2011 Peter Bankhead.
    % See the file : Copyright.m for further details.
    
    
    %% Properties
    
    % Important value properties, not modified directly
    properties (GetAccess = protected, SetAccess = protected)
        prop_centre;         % Centre line points
        prop_side1;          % Edge points (first side)
        prop_side2;          % Edge points (second side)
        prop_angles;         % Angles of the vessel, as determined at each centre points (in form of unit vectors giving directions)
        prop_keep_inds;      % Indices of 'good' measurements, i.e. measurements to be output
        
        prop_dark = [];      % TRUE if vessel is dark, i.e. represented by a 'valley' rather than a 'hill'
    end
    
    % Publically available versions of the above
    properties (Dependent = true)
        centre;         % Centre line points
        side1;          % Edge points (first side)
        side2;          % Edge points (second side)
        angles;         % Angles of the vessel, as determined at each centre points
        keep_inds;      % Indices of 'good' measurements, i.e. to be output
        
        dark = [];      % TRUE if vessel is dark, i.e. represented by a 'valley' rather than a 'hill'
    end
    
    % Dependent properties, computed from other (publically accessible) properties
    properties (Dependent = true)
        diameters;   % Euclidian distance between side1 and side2, scaled by SCALE_VALUE
        offset;      % Cummulative sum of euclidean distances *between* centre points, scaled by SCALE_VALUE (i.e. offset of a diameter measured along the centre line)
        
        valid;       % TRUE if this object contains sufficient data for measuring diameters & offsets,
                     % and it has both sides and centre properties containing the same numbers of points
        
        string;               % String representation of the object
        num_diameters;        % Total number of diameters
        im_profiles_positive; % As image profiles, but ensuring that the vessel
                              % is 'positive' (i.e. a 'hill' rather than a 'valley')
                              
        length_straight_line; % The straight-line length connecting the vessel's end points (i.e. the first and last 'included' points; those in between are ignored)
        length_cumulative;    % The cumulative sum of the straight-line lengths between all the vessel's centre line points, from the first to the last 'included' point
        
        settings;    % The VESSEL_SETTINGS object stored in the associated VESSEL_DATA
        
        % Scale properties are obtained from VESSEL_SETTINGS calibration if available
        scale_value; % The scale value (for multiplication)
        scale_unit;  % The unit (e.g. 'pixels', 'µm')
    end
    
    % General properties
    properties
        vessel_data;    % An associated VESSEL_DATA object
                
        im_profiles;      % Image in which each row is the image profile across
                          % corresponding centre points at corresponding angle
        im_profiles_rows; % (Non-integer) row co-ordinate in original image for
                          % each pixel in im_profiles
        im_profiles_cols; % (Non-integer) column co-ordinates
        
        im_profiles_model; % Similar to IM_PROFILES, but diameters may be measured from
                           % the profiles after smoothing or fitting a
                           % model to the data, in which case the profiles
                           % actually used are stored here
    end
    
    % Transient properties - these don't need to be saved
    properties (Transient = true)
        highlight_inds; % Indices of vessels that should be highlighted on plots
    end

        
    
    
    %% GET / SET functions
    
    methods
        
        function val = get.keep_inds(obj)
            if isempty(obj.prop_keep_inds)
                  val = ~isnan(obj.diameters);
%                 val = true(obj.num_diameters, 1);
            else
                val = obj.prop_keep_inds;
            end
        end
        
        
        function val = get.num_diameters(obj)
            if obj.valid
                val = size(obj.side1,1);
            else
                val = 0;
            end
        end
        
        
        
        function set.dark(obj, val)
            if isempty(val) || (islogical(val) && isscalar(val))
                obj.prop_dark = val;
            end
        end
        
        
        % Use own property if available, otherwise use property of
        % Vessel_Data, otherwise empty
        function val = get.dark(obj)
            if ~isempty(obj.prop_dark)
                val = obj.prop_dark;
            elseif ~isempty(obj.vessel_data)
                val = obj.vessel_data.dark_vessels;
            else
                val = [];
            end
        end
                
        
        function val = get.valid(obj)
            val = false;
            if isempty(obj.prop_side1)
                return;
            end
            % Check sides and centre are the right size
            s2 = [size(obj.prop_side1,1), 2];
            if ~isequal(size(obj.prop_side1), size(obj.prop_side2), size(obj.prop_centre), s2)
                return;
            end
            % Now check the properties which don't necessarily need to be
            % set but, if they are set, should at least be right...
            s1 = [size(obj.prop_side1,1), 1];
            if ~isempty(obj.highlight_inds)
                if ~isequal(size(obj.highlight_inds), s1)
                    return;
                end
            end
            if ~isempty(obj.prop_angles)
                if ~isequal(size(obj.prop_angles), s2)
                    return;
                end
            end
            if ~isempty(obj.prop_keep_inds)
                if ~isequal(size(obj.prop_keep_inds), s1)
                    return;
                end
            end
            val = true;
        end
        
        
        
        function val = get.angles(obj)
            val = obj.prop_angles;
        end
        
        
        
        function set.vessel_data(obj, val)
            if isa(val, 'Vessel_Data')
                obj.vessel_data = val;
            end
        end
        
        
        function set.angles(obj, val)
            % Don't allow unless n x 2 or empty
            if isempty(val)
                obj.prop_angles = val;
            else
                val = valid_points_vector(val);
                if ~isempty(val)
                    obj.prop_angles = val;
                end
            end
        end
        
        
        function val = get.side1(obj)
            val = obj.prop_side1;
        end
        
        
        function set.side1(obj, val)
            % Don't allow unless n x 2 or empty
            if isempty(val)
                obj.prop_side1 = val;
            else
                val = valid_points_vector(val);
                if ~isempty(val)
                    obj.prop_side1 = val;
                end
            end
        end
        
        function val = get.side2(obj)
            val = obj.prop_side2;
        end
        
        function set.side2(obj, val)
            % Don't allow unless n x 2 or empty
            if isempty(val)
                obj.prop_side2 = val;
            else
                val = valid_points_vector(val);
                if ~isempty(val)
                    obj.prop_side2 = val;
                end
            end
        end
        
        
        function val = get.centre(obj)
            val = obj.prop_centre;
        end
        
        
        % Tie KEEP_INDS to CENTRE in terms of size
        function set.centre(obj, val)
            % Don't allow unless n x 2 or empty
            if isempty(val)
                obj.prop_centre = [];
                obj.prop_keep_inds = [];
            else
                val = valid_points_vector(val);
                if ~isempty(val)
                    obj.prop_centre = val;
                    obj.prop_keep_inds = true(size(val, 1), 1);
                end
            end
        end
        
        
               
        function val = get.length_cumulative(obj)
            % Cannot determine diameters
            if isempty(obj.centre)
                val = 0;
                return;
            end
            % Find the first and last included indices
            if ~isempty(obj.keep_inds)
                ind1 = find(obj.keep_inds, 1, 'first');
                ind2 = find(obj.keep_inds, 1, 'last');
            else
                ind1 = 1;
                ind2 = size(obj.centre, 1);
            end
            % Compute the difference in offsets along the centre line
            val = obj.offset(ind2) - obj.offset(ind1);
        end
        
        function val = get.length_straight_line(obj)
            % Cannot determine diameters
            if isempty(obj.centre)
                val = 0;
                return;
            end
            % Find the first and last included indices
            if ~isempty(obj.keep_inds)
                ind1 = find(obj.keep_inds, 1, 'first');
                ind2 = find(obj.keep_inds, 1, 'last');
            else
                ind1 = 1;
                ind2 = size(obj.centre, 1);
            end
            % Compute the straight-line length between the first and last
            % centre points
            val = sqrt(sum((obj.centre(ind2,:) - obj.centre(ind1,:)).^2)) * obj.scale_value;
        end
        
        
        function val = get.diameters(obj)
            % Cannot determine diameters
            if ~obj.valid
                val = [];
                return;
            end
            % Measure euclidean distance
            val = root_sum_of_squares(obj.side2 - obj.side1, 2) * obj.scale_value;
        end
        
        
        function val = get.offset(obj)
            if isempty(obj.centre)
                val = [];
                return;
            end
            % Determine cummulative sum of euclidean distances between consecutive centre points
            if size(obj.centre, 1) == 1
                val = 0;
            else
                val = cumsum([0; root_sum_of_squares(diff(obj.centre, [], 1), 2)]) * obj.scale_value;
            end
        end
        
        
        
        function val = get.settings(obj)
            if ~isempty(obj.vessel_data)
                val = obj.vessel_data.settings;
            else
                val = [];
            end
        end
        
        
        
        function val = get.im_profiles_positive(obj)
            % IM is an image consisting of vessel profiles (each profile is a row in
            % the image).
            % The vessels could be positive ('hills') or negative ('valleys').
            % Which is the case depends upon the DARK property.
            
            % No image profiles to return
            if isempty(obj.im_profiles)
                val = [];
                return;
            end
            
            % If dark vessels, invert profiles - otherwise leave
            if obj.dark
                val = max(obj.im_profiles(:)) - obj.im_profiles;
            else
                val = obj.im_profiles;
            end
        end
        
        
        
        
        function val = get.scale_value(obj)
            if ~isempty(obj.settings) && obj.settings.calibrate
                val = obj.settings.calibration_value;                
            else
                val = 1;
            end
        end
        
        function val = get.scale_unit(obj)
            if ~isempty(obj.settings) && obj.settings.calibrate
                val = obj.settings.calibration_unit;
            else
                val = 'px';
            end
        end
        
                
        % Get a reasonable string representation of the object, containing
        % the centre position and diameters.
        function str = get.string(obj)
            n = obj.num_diameters;
            if n == 0
                str = '';
                return;
            end
            keep = repmat(' ', n, 1);
            keep(~obj.keep_inds) = 'X';
            str = [int2str((1:n)'), ...
                repmat(' (', n, 1), int2str(round(obj.centre(:,1))), ...
                repmat(',', n, 1), int2str(round(obj.centre(:,2))), ...
                repmat(')  ', n, 1), num2str(obj.diameters, '%6.2f'), ...
                repmat([' ', obj.scale_unit, '  '], n, 1), keep];
        end
        
        
        function set.highlight_inds(obj, val)
            % Reset by using an empty vector
            obj.highlight_inds = [];
            if isempty(val)
                return;
                % Passed a logical array - use if same size
            elseif islogical(val) && numel(val) == obj.num_diameters
                obj.highlight_inds = val;
                % Numeric vector, if it's valid convert to logical for use
            elseif isnumeric(val) && min(val) >= 1 && max(val) <= obj.num_diameters
                obj.highlight_inds = false(obj.num_diameters, 1);
                obj.highlight_inds(val) = true;
            end
        end
        
        
        
        function set.keep_inds(obj, val)
            % Update values
            if islogical(val) && numel(val) == size(obj.centre, 1)
                obj.prop_keep_inds = val;
            end
        end
        
        
        
        
        %% Display functions
        
        
        % Updates the vessel plot if it is displayed, or if a figure
        % handle is passed, but otherwise does nothing
        function update_plot(obj, h)
            
            % Haven't got a handle, so check if figure with same name exists
            if nargin < 2 || ~ishandle(h)
                name = get_plot_name(obj);
                h = findobj('Name', name);
                if isempty(h)
                    return;
                end
            end
            % Activate for painting
            set(0, 'CurrentFigure', h);
            
            % Determine scale label
            lab = ['(', obj.scale_unit, ')']; 
            % Plot
            cla;
            inds = obj.keep_inds;
            
            
            
            if obj.settings.plot_markers
                marker_style = 's';
            else
                marker_style = 'none';
            end
            if obj.settings.plot_lines
                line_style = '-';
            else
                line_style = 'none';
            end
            
            % Plot the excluded diameters
            x = obj.offset;
            y = obj.diameters;
            x(inds) = nan;
            y(inds) = nan;
            line(x, y,...
                'LineStyle', line_style, 'Marker', marker_style, 'MarkerSize', 2, ...
                'Color', obj.settings.col_diameters_ex, 'MarkerFaceColor', obj.settings.col_diameters_ex);
            
            % Plot the included diameters
            x = obj.offset;
            y = obj.diameters;
            x(~inds) = nan;
            y(~inds) = nan;
            line(x, y,...
                'LineStyle', line_style, 'Marker', marker_style, 'MarkerSize', 2, ...
                'Color', obj.settings.col_diameters, 'MarkerFaceColor', obj.settings.col_diameters);
            
            % Set labels
            xlabel(['Offset ', lab]);
            ylabel(['Diameter ', lab]);
            ylim([0 max(obj.diameters) + 2]);
            
            % Show highlighted lines if required
            if ~isempty(obj.settings) && obj.settings.show_highlighted && any(obj.highlight_inds)
                x = obj.offset;
                y = obj.diameters;
                x(~obj.highlight_inds) = nan;
                y(~obj.highlight_inds) = nan;
                line(x, y, ...
                    'LineStyle', line_style, 'Marker', marker_style, 'MarkerSize', 2, ...
                    'Color', obj.settings.col_highlighted, 'MarkerFaceColor', obj.settings.col_highlighted);
            end            
        end
        
        
        
        
        % Plot the image profile corresponding to the vessel measurement in
        % INDS.  If INDS is a vector, then the mean of all the
        % corresponding profiles is shown instead.  If TICKS is true, then
        % XTICK and YTICK are shown.  See DOCSEARCH AXES PROPERTIES.
        function plot_profiles(obj, inds, ticks)
            % Clear axis for plot
            cla;
            % Nothing to plot
            if isempty(inds) || ~any(inds) || ~obj.valid || isempty(obj.im_profiles_rows) || ...
                        isempty(obj.im_profiles_cols) || isempty(obj.im_profiles)
                return;
            end
            % Check whether plotting only one profile, and edge locations available
            single_plot = nnz(inds) == 1;
            plot_edges = single_plot && ~isempty(obj.side1) && ~isempty(obj.side1);
            prof_model = [];
            if single_plot
                prof = obj.im_profiles(inds,:);
                if ~isempty(obj.im_profiles_model)
                    prof_model = obj.im_profiles_model(inds,:);
                end
                plot_title = 'Profile plot';
            else
                prof = mean(obj.im_profiles(inds,:));
                if ~isempty(obj.im_profiles_model)
                    prof_model = mean(obj.im_profiles_model(inds,:));
                end
                plot_title = 'Averaged profile plot';
            end
            prof_range = max(prof) - min(prof);
            ylims = [min(prof) - prof_range/10, max(prof) + prof_range/10];
            % Plot edges if required
            if plot_edges
                % Get rows and columns for each pixel in profile
                x_rows_cols = cat(1, mean(obj.im_profiles_rows(inds,:), 1), ...
                    mean(obj.im_profiles_cols(inds,:), 1));
                % Decide whether to use rows or columns based on range,
                % because the profile might be completely vertical or
                % horizontal in the image.
                % NOTE: THIS CAN RESULT IN THE PLOT FLIPPING IF VIEWING
                % PLOTS CONSECUTIVELY!!!  This looks quite odd...
                r = max(x_rows_cols, [], 2) - min(x_rows_cols, [], 2);
                if r(1) > r(2)
                    use_ind = 1;
                else
                    use_ind = 2;
                end
                % Figure out line position based upon only one of either
                % the row or column locations of the sides, to simplifiy
                % things
                x = x_rows_cols(use_ind,:);
                sx1 = ones(2,1) * obj.side1(inds,use_ind);
                sx2 = ones(2,1) * obj.side2(inds,use_ind);
                % Just in case need to paint ticks, adjust measurements to
                % have single unit spacing starting from 0
                x_sub = min(x);
                x_scale = numel(x) / max(x - x_sub);
                x = (x - x_sub) * x_scale;
                sx1 = (sx1 - x_sub) * x_scale;
                sx2 = (sx2 - x_sub) * x_scale;
                line(sx1, ylims, 'Color', 'r');
                line(sx2, ylims, 'Color', 'r');
            else
                x = 0:numel(prof)-1;
            end
            % Not got enough points left, don't plot
            if numel(unique(x)) < 2
                cla;
                return;
            end
            % Adjust display limits and do plot
            xlim([min(x), max(x)]);
            ylim(ylims);
            % Plot profile
            line(x, prof, 'Color', 'k', 'Marker', '.', 'MarkerSize', 10);
            % Plot model if available
            if ~isempty(prof_model)
                line(x, prof_model, 'Color', 'r');
            end
            % Remove ticks if desired
            if nargin <= 2 || ~ticks
                set(gca, 'XTick', [], 'YTick', []);
            end
            title(plot_title);
        end
        
        
        
        
        % Processes the painting, and possible creation, of a specified vessel plot
        function plot(obj)
            % First check if figure with same name exists, and create if it doesn't
            name = get_plot_name(obj);
            h = findobj('Name', name);
            if isempty(h)
                h = figure('Name', name, 'NumberTitle','off');
                title(name, 'Interpreter','none');
            else
                % Already exists - bring to front
                figure(h);
            end
            % Do actual painting
            update_plot(obj, h);
        end
        
        
        function name = get_plot_name(obj)
            if ~isa(obj.vessel_data, 'Vessel_Data')
                name = 'Vessel plot';
            else
                name = [obj.vessel_data.file_name, ' vessel plot' ];
            end
        end
        
        
        function name = get_image_name(obj)
            if ~isa(obj.vessel_data, 'Vessel_Data')
                name = 'Vessel image profiles';
            else
                name = [obj.vessel_data.file_name, ' image profiles' ];
            end
        end
        
        
        
        % Show straightened version of vessel
        function imshow(obj)
            % Got nothing to show, just return
            if isempty(obj.im_profiles)
                return;
            end
            % Check if figure with same name exists, and create if it doesn't
            name = get_image_name(obj);
            h = findobj('Name', name);
            if isempty(h)
                figure('Name', name, 'NumberTitle','off');
            else
                % Already exists - bring to front (and update image, just in case)
                figure(h);
            end
            % Show straightened vessel (image profiles)
            imshow(obj.im_profiles, []);
        end
        
        
        
        
        %% Modifying functions
        
        % Remove the terminating NaNs, i.e. locations for which a valid
        % centre or side is not available.  These will be removed from all
        % associated properties, including IM_PROFILES.
        % If DO_ALL is true, then NaNs will be removed even from inside the
        % vessels as well.
        function remove_nans(obj, do_all)
            % Ensure valid or don't do anything
            if ~obj.valid
                return;
            end
            if nargin < 2
                do_all = false;
            end
            % Get indices containing nans
            not_nans = ~any((isnan(obj.prop_side1) | isnan(obj.prop_side2) | isnan(obj.prop_centre)), 2);
            % Check if we've anything to do at all
            if all(not_nans)
                return
            end
            if ~do_all
                % Remove terminal nan rows only
                not_nans = find(not_nans, 1, 'first'):find(not_nans, 1, 'last');
            end
            obj.prop_side1 = obj.prop_side1(not_nans,:);
            obj.prop_side2 = obj.prop_side2(not_nans,:);
            obj.prop_centre = obj.prop_centre(not_nans,:);
            if ~isempty(obj.prop_angles)
                obj.prop_angles = obj.prop_angles(not_nans,:);
            end
            if ~isempty(obj.im_profiles)
                obj.im_profiles = obj.im_profiles(not_nans,:);
            end
            if ~isempty(obj.im_profiles_model)
                obj.im_profiles_model = obj.im_profiles_model(not_nans,:);
            end
            if ~isempty(obj.im_profiles_rows)
                obj.im_profiles_rows = obj.im_profiles_rows(not_nans,:);
            end
            if ~isempty(obj.im_profiles_cols)
                obj.im_profiles_cols = obj.im_profiles_cols(not_nans,:);
            end
            if ~isempty(obj.highlight_inds)
                obj.highlight_inds = obj.highlight_inds(not_nans);
            end
            if ~isempty(obj.prop_keep_inds)
                obj.prop_keep_inds = obj.prop_keep_inds(not_nans);
            end
        end
        
        
        
        % Ensure that any place where a diameter could not be measured has
        % its KEEP_INDS option set to FALSE.
        function exclude_nans(obj)
            for ii = 1:numel(obj)
                % Ensure valid or don't do anything
                if ~obj(ii).valid
                    continue
                end
                % Get indices containing nans
                is_nan = any((isnan(obj(ii).prop_side1) | isnan(obj(ii).prop_side2) | isnan(obj(ii).prop_centre)), 2);
                % Check if we've anything to do at all
                if ~any(is_nan)
                    continue
                end
                obj(ii).keep_inds(is_nan) = false;
            end
        end
        
        
        
        % Copy the diameter measurements, and offsets from the starting
        % point of the vessel, to the system clipboard.
        function copy_to_clipboard(obj)
            % Get offsets and diameters to copy
            lab = ['(', obj.scale_unit, ')'];
            inds = obj.keep_inds;
            offsets = obj.offset(inds);
            offsets = offsets - min(offsets);
            diameters = obj.diameters(inds);
            
            % Convert to formatted string and copy
            num_diameters = length(offsets);
            str = [num2str(offsets), repmat(char(9), num_diameters, 1), ...
                num2str(diameters), repmat(char(10), num_diameters, 1)];
            str = str';
            arraystring = ['Offsets ', lab, char(9), 'Diameters ', lab, char(10), str(:)'];
            clipboard('copy', arraystring);
        end
        
        
        
        % Scale all currently-set values appropriately
        function do_scale(obj, scale_factor)
            if isscalar(scale_factor)
                scale_factor = [scale_factor, scale_factor];
            end
            if isequal(scale_factor, [1 1])
                return;
            end
            if isequal(size(scale_factor), [1 2]) || all(scale_factor > 0)
                if ~isempty(obj.centre)
                    obj.centre = bsxfun(@times, obj.centre, scale_factor);
                end
                if ~isempty(obj.side1)
                    obj.side1 = bsxfun(@times, obj.side1, scale_factor);
                end
                if ~isempty(obj.side2)
                    obj.side2 = bsxfun(@times, obj.side2, scale_factor);
                end
                obj.im_profiles_rows = obj.im_profiles_rows * scale_factor(1);
                obj.im_profiles_cols = obj.im_profiles_cols * scale_factor(2);
            else
                warning('Vessel:do_scale', ...
                    ['Invalid scale factor: ', num2str(scale_factor), ...
                    '. Should be of the form [vectical_scale, horizontal_scale],' ...
                    ' with all positive values.']);
            end
        end
        
        
    end
    
    
    
    
    %% SAVE and LOAD functions
    
    methods (Static)
        function obj = loadobj(obj)
            if isstruct(obj) || isa(obj, 'Vessel')
                % Call default constructor
                new_obj = Vessel;
                % Assign property values from struct
                new_obj.prop_centre      = obj.centre;
                new_obj.prop_side1       = obj.side1;
                new_obj.prop_side2       = obj.side2;
                new_obj.prop_angles      = obj.angles;
                new_obj.prop_keep_inds   = obj.keep_inds;
                new_obj.prop_dark        = obj.prop_dark;
                new_obj.im_profiles       = obj.im_profiles;
                new_obj.im_profiles_rows  = obj.im_profiles_rows;
                new_obj.im_profiles_cols  = obj.im_profiles_cols;
                new_obj.im_profiles_model = obj.im_profiles_model;
                obj = new_obj;
            end
        end
    end
    
    methods
        
        % Create a duplicate Vessel object
        function new_obj = duplicate(obj, new_obj)
            if isa(obj, 'Vessel')
                % Call default constructor if not passed
                if nargin < 2
                    new_obj = Vessel;
                end
                % Assign property values from struct
                new_obj.prop_centre      = obj.prop_centre;
                new_obj.prop_side1       = obj.prop_side1;
                new_obj.prop_side2       = obj.prop_side2;
                new_obj.prop_angles      = obj.prop_angles;
                new_obj.prop_keep_inds   = obj.prop_keep_inds;
                new_obj.prop_dark        = obj.prop_dark;
                new_obj.im_profiles       = obj.im_profiles;
                new_obj.im_profiles_rows  = obj.im_profiles_rows;
                new_obj.im_profiles_cols  = obj.im_profiles_cols;
                new_obj.im_profiles_model = obj.im_profiles_model;
                new_obj.vessel_data      = obj.vessel_data;
            else
                throw(MException('Vessel:dupicate', ...
                    'Not a Vessel object passed to Vessel.duplicate'));
            end
        end
        
        % Create a structure with the required properties for saving
        function s = saveobj(obj)
            s.centre      = obj.prop_centre;
            s.side1       = obj.prop_side1;
            s.side2       = obj.prop_side2;
            s.angles      = obj.prop_angles;
            s.keep_inds   = obj.prop_keep_inds;
            s.prop_dark   = obj.prop_dark;
            s.im_profiles = obj.im_profiles;
            s.im_profiles_rows  = obj.im_profiles_rows;
            s.im_profiles_cols  = obj.im_profiles_cols;
            s.im_profiles_model = obj.im_profiles_model;
        end
    end
    
    
end


% Ensure that a vector is N x 2 (containing pixel locations)
function val = valid_points_vector(v)
% Check the size is valid
siz = size(v);
if numel(siz) ~= 2 || ~any(siz== 2)
    val = [];
    return;
end
% Valid, now just ensure correct orientation
if siz(2) ~= 2
    val = v';
else
    val = v;
end
end