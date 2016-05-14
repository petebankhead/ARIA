classdef Vessel_Settings < hgsetget
%VESSEL_SETTINGS A range of display settings for use with VESSEL_DATA.
    %   These settings are concerned with with, for example, whether to
    %   paint selections or centre lines, or to use calibrated values or
    %   pixels for measurements.
    %
    %
    % Copyright © 2011 Peter Bankhead.
    % See the file : Copyright.m for further details.

    properties        
        % Calibration value and units
        calibrate = false;
        calibration_value = 1;
        calibration_unit  = 'px';

        % Options for image display
        show_centre_line = true;
        show_diameters   = true;
        show_edges       = true;
        show_highlighted = true;
        show_labels      = true;
        show_orig        = false;
        show_optic_disc  = true;
        
        % Options for plot display
        plot_lines       = false;
        plot_markers     = true;
        
        % Diameter spacing used to display, should be an integer >= 1
        % If SHOW_SPACING == 1, will show every computed diameter on top of
        % the image whenever SHOW_DIAMETERS == TRUE, when > 1 will skip
        % some diameters.  Might be useful when the image is quite high
        % resolution, and showing too many diameters gets confusing.
        show_spacing     = 1;
        
        % Default display colours
        col_centre_line  = [0 0 1];
        col_diameters    = [1 0 0]; % Included diameters
        col_diameters_ex = [0 0 1]; % Excluded diameters
        col_edges        = [1 0 0];
        col_highlighted  = [1 1 0];
        col_labels       = [0 0 1];
        col_optic_disc   = [0 .85 0];
        
        % Use double buffering (for showing the image)
        double_buffer  = true;
        
        % Path to last open file
        last_path = cd;
        
        % Prompt user for algorithm parameters where appropriate
        prompt = false;
    end
    
    methods        
        
        % Set methods that perform basic error-checking to only permit
        % valid input
        
        % --------- Spacing of displayed diameters set method ---------
        function obj = set.show_spacing(obj, val)
            if isscalar(val)
                val = round(val);
                if val > 0
                    obj.show_spacing = val;
                end
            end
        end

        
        % --------- Calibration set methods ---------
        function obj = set.calibration_value(obj, val)
            if isnumeric(val)
                obj.calibration_value = val(1);
            end
        end
        
        function obj = set.calibration_unit(obj, val)
            if ischar(val)
                obj.calibration_unit = val;
            end
        end
        
        
        % --------- Path set method ---------
        function obj = set.last_path(obj, val)
            if ischar(val)
                obj.last_path = val;
            end
        end
        
        
        % --------- Logical scalar set methods ---------
        function obj = set.show_centre_line(obj, val)
            if isscalar(val)
                obj.show_centre_line = val ~= 0;
            end
        end
        
        function obj = set.show_diameters(obj, val)
            if isscalar(val)
                obj.show_diameters = val ~= 0;
            end
        end
        
        function obj = set.show_edges(obj, val)
            if isscalar(val)
                obj.show_edges = val ~= 0;
            end
        end
        
        function obj = set.show_highlighted(obj, val)
            if isscalar(val)
                obj.show_highlighted = val ~= 0;
            end
        end
        
        function obj = set.show_labels(obj, val)
            if isscalar(val)
                obj.show_labels = val ~= 0;
            end
        end
        
        function obj = set.show_optic_disc(obj, val)
            if isscalar(val)
                obj.show_optic_disc = val ~= 0;
            end
        end
        
        function obj = set.plot_lines(obj, val)
            if isscalar(val)
                obj.plot_lines = val ~= 0;
            end
        end
        
        function obj = set.plot_markers(obj, val)
            if isscalar(val)
                obj.plot_markers = val ~= 0;
            end
        end
        
        function obj = set.prompt(obj, val)
            if isscalar(val)
                obj.prompt = val ~= 0;
            end
        end
        
        
        % --------- Colour set methods (RGB only) ---------
        function obj = set.col_centre_line(obj, val)
            if isnumeric(val) && numel(val) == 3
                obj.col_centre_line = val(:)';
            end
        end
        
        function obj = set.col_diameters(obj, val)
            if isnumeric(val) && numel(val) == 3
                obj.col_diameters = val(:)';
            end
        end
        
        function obj = set.col_diameters_ex(obj, val)
            if isnumeric(val) && numel(val) == 3
                obj.col_diameters_ex = val(:)';
            end
        end
        
        function obj = set.col_edges(obj, val)
            if isnumeric(val) && numel(val) == 3
                obj.col_edges = val(:)';
            end
        end
        
        function obj = set.col_highlighted(obj, val)
            if isnumeric(val) && numel(val) == 3
                obj.col_highlighted = val(:)';
            end
        end
        
        function obj = set.col_labels(obj, val)
            if isnumeric(val) && numel(val) == 3
                obj.col_labels = val(:)';
            end
        end
        
                
    end
    
    
    
    

    
    % Save and load methods
    methods (Static)
        function obj = loadobj(obj)
            if isstruct(obj)
                % Call default constructor
                new_obj = Vessel_Settings;
                % Assign property values from struct
                new_obj.calibrate         = obj.calibrate;
                new_obj.calibration_value = obj.calibration_value;
                new_obj.calibration_unit  = obj.calibration_unit;
                new_obj.show_centre_line  = obj.show_centre_line;
                new_obj.show_diameters    = obj.show_diameters;
                new_obj.show_edges        = obj.show_edges;
                new_obj.show_highlighted  = obj.show_highlighted;
                new_obj.show_labels       = obj.show_labels;
                new_obj.show_spacing      = obj.show_spacing;
                new_obj.show_orig         = obj.show_orig;
                new_obj.col_centre_line   = obj.col_centre_line;
                new_obj.col_diameters     = obj.col_diameters;
                new_obj.col_diameters_ex  = obj.col_diameters_ex;
                new_obj.col_edges         = obj.col_edges;
                new_obj.col_highlighted   = obj.col_highlighted;
                new_obj.col_labels        = obj.col_labels;
                new_obj.last_path         = obj.last_path;
                new_obj.double_buffer     = obj.double_buffer;
                new_obj.prompt            = obj.prompt;
                obj = new_obj;
            end
        end
    end
    
    methods
        function obj = saveobj(obj)
            % Create and save structure
            s.calibrate         = obj.calibrate;
            s.calibration_value = obj.calibration_value;
            s.calibration_unit  = obj.calibration_unit;
            s.show_centre_line  = obj.show_centre_line;
            s.show_diameters    = obj.show_diameters;
            s.show_edges        = obj.show_edges;
            s.show_highlighted  = obj.show_highlighted;
            s.show_labels       = obj.show_labels;
            s.show_spacing      = obj.show_spacing;
            s.show_orig         = obj.show_orig;
            s.col_centre_line   = obj.col_centre_line;
            s.col_diameters     = obj.col_diameters;
            s.col_diameters_ex  = obj.col_diameters_ex;
            s.col_edges         = obj.col_edges;
            s.col_highlighted   = obj.col_highlighted;
            s.col_labels        = obj.col_labels;
            s.last_path         = obj.last_path;
            s.double_buffer     = obj.double_buffer;
            s.prompt            = obj.prompt;
            obj = s;
        end
    end
    
    
end
