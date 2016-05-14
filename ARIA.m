function varargout = ARIA(varargin)
% ARIA Analyse retinal vessel diameters with a Graphical User Interface.
%
%      ARIA makes it possible to measure vessel diameters
%      automatically in a wide range of image types.  Simply type ARIA at
%      the MATLAB command prompt to run it.
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.
%
% Last Modified by GUIDE v2.5 25-Aug-2011 14:19:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ARIA_OpeningFcn, ...
    'gui_OutputFcn',  @ARIA_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CREATION FUNCTIONS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes just before ARIA is made visible.
function ARIA_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ARIA (see VARARGIN)
% Choose default command line output for ARIA
handles.output = hObject;
% Ensure that the required directories are on the MATLAB path
ARIA_setup(true);
% Create Vessel_Data field
handles.vessel_data = [];
% Save handles
guidata(hObject, handles);
% Update handles structure
create_menu(hObject);
% Initialize from preferences file if possible
initialize(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = ARIA_OutputFcn(hObject, eventdata, handles) %#ok<*INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function whiteBG_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
% Hint: listbox and popup menu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function ax_image_CreateFcn(hObject, eventdata, handles)
% Set colour of axis to match main figure colour
col = get(0,'defaultUicontrolBackgroundColor');
set(hObject, 'Color', col, 'XColor', col, 'YColor', col);


% --- Executes during object creation, after setting all properties.
function tbl_vessel_CreateFcn(hObject, eventdata, handles)
% Set colour of axis to match main figure colour - looks better on PC,
% worse on Mac... don't know about Linux or any others
if ispc
    col = get(0,'defaultUicontrolBackgroundColor');
    set(hObject, 'BackgroundColor', col);
end

% --- Executes during object creation, after setting all properties.
function lb_diameters_CreateFcn(hObject, eventdata, handles)
% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% Text formerly looked better a bit bigger on the Mac
% if ismac
set(hObject, 'FontSize', 10);
% end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MENU FUNCTIONS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create menu
function create_menu(hObject)
handles = guidata(hObject);
% Delete previous processors - just in case
delete(findobj('Type', 'uimenu', 'Parent', handles.menu_processors));
% Populate processors menu using functions in the Vessel_Processors package
w = what('Vessel_Processors');
% Check whether multiple directories are found, and if so use the first one
if numel(w) > 1
    warning('ARIA:Vessel_Processor_directory', 'Multiple Vessel_Processors have been found on the MATLAB path - the first will be used.');
    w = w(1);
end
ext = '.vessel_processor';
files = dir([w.path, filesep, '*', ext]);
for ii = 1:numel(files)
    % Get text for menu item
    label = strrep(files(ii).name(1:end-numel(ext)), '_', ' ');
    % Add menu item, check first in list
    if ii == 1
        uimenu(handles.menu_processors, 'Label', label, 'Callback', @set_processor, ...
            'UserData', files(ii).name, 'Tag', 'processor', 'Checked', 'on');
    else
        uimenu(handles.menu_processors, 'Label', label, 'Callback', @set_processor, ...
            'UserData', files(ii).name, 'Tag', 'processor');
    end
end
% Add 'prompt' menu item
uimenu(handles.menu_processors, 'Label', 'Prompt for settings', 'Checked', 'off', ...
    'Separator', 'on', 'Tag', 'prompt',...
    'Callback', @prompt_click);
% Add options to create new processors
uimenu(handles.menu_processors, 'Label', 'Create new processor', 'Checked', 'off', ...
    'Separator', 'on', 'Tag', 'processor_new',...
    'Callback', @processor_new_click);



% Create a new vessel processor
function processor_new_click(hObject, eventData)
w = what('Vessel_Algorithms');
% Check whether multiple directories are found, and if so use the first one
if numel(w) > 1
    warning('ARIA:Vessel_Algorithm_directory', 'Multiple Vessel_Algorithm directories have been found on the MATLAB path - the first will be used.');
    w = w(1);
end
% Determine which algorithm to use
files = dir([w.path, filesep, '*.m']);
if isempty(files)
    errordlg('No .M files could be found in Vessel_Algorithms - cannot create processor!');
    return
elseif numel(files) == 1
    fun_name = files.name;
else
    f_names = {files.name};
    [sel, ok] = listdlg('Name', 'Create processor', 'ListString', f_names, ...
        'PromptString', 'Choose a processing algorithm file', 'SelectionMode', 'single');
    if ~ok
        return
    end
    fun_name = f_names{sel};
end
% Get a name for the processor
processor_name = inputdlg('Choose a name for the processor', 'Create processor', 1);
if isempty(processor_name)
    return
end
% Fix up the name for use
answer = strrep(processor_name, ' ', '_');
if isempty(answer)
    return;
end
processor_name = answer{1};
if isempty(processor_name)
    return;
end
ind = strfind(processor_name, '.vessel_processor');
if isempty(ind) || ind ~= numel(processor_name) - 16
    processor_name = [processor_name, '.vessel_processor'];
end
% Save the processor
save_vessel_processor(processor_name, struct, fun_name(1:end-2));
% Update the processor menu
create_menu(hObject);
% Make sure the new processor is selected
h = findobj('Type', 'uimenu', 'Tag', 'processor', 'UserData', processor_name);
set_processor(h);


% Toggle 'prompt' setting
function prompt_click(hObject, eventData)
handles = guidata(hObject);
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
    handles.settings.prompt = false;
else
    set(hObject, 'Checked', 'on');
    handles.settings.prompt = true;
end


% Set the currently selected processor
function set_processor(hObject, eventData)
h = findobj('Type', 'uimenu', 'Tag', 'processor');
set(h, 'Checked', 'off');
set(hObject, 'Checked', 'on');


% Get the currently selected processor
function processor = get_processor
processor = get(findobj(...
    'Type', 'uimenu', 'Tag', 'processor', 'Checked', 'on'), 'UserData');
% This shouldn't ever happen...
if isempty(processor)
    errordlg('No processor selected!  A processor needs to be checked in the Processors menu.');
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SETTINGS FUNCTIONS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Tests for preferences file and read calibration if available
function initialize(hObject)
handles = guidata(hObject);
fpath = fileparts(mfilename('fullpath'));
handles.prefsfile = fullfile(fpath, 'ARIA_prefs.mat');
% There is a preferences file, try to read it
if exist(handles.prefsfile, 'file')
    % Read values for checkboxes etc.
    try
        load(handles.prefsfile);
        handles.settings = settings;
        % Initialize menu items
        set(findobj('Type', 'uimenu'), 'Checked', 'off');
        for ii = 1:numel(checked_menu_items)
            set(findobj('Type', 'uimenu', 'Label', checked_menu_items{ii}), 'Checked', 'on');
        end
    catch ME
        errordlg('Preference file corrupted or incomplete! Will try to continue...');
        disp(ME);
    end
else
    handles.settings = Vessel_Settings;
end
% Initialize check boxes etc.
set(handles.rb_pixels, 'Value', ~handles.settings.calibrate);
set(handles.rb_calibrate, 'Value', handles.settings.calibrate);
set(handles.cb_centre, 'Value', handles.settings.show_centre_line);
set(handles.cb_diameters, 'Value', handles.settings.show_diameters);
set(handles.cb_edges, 'Value', handles.settings.show_edges);
set(handles.cb_selected, 'Value', handles.settings.show_highlighted);
set(handles.cb_labels, 'Value', handles.settings.show_labels);
set(handles.cb_optic_disc, 'Value', handles.settings.show_optic_disc);
if handles.settings.show_orig
    set(handles.menu_image_orig, 'Checked', 'on');
    set(handles.menu_image_grayscale, 'Checked', 'off');
else
    set(handles.menu_image_orig, 'Checked', 'off');
    set(handles.menu_image_grayscale, 'Checked', 'on');
end
set(handles.menu_plot_both, 'checked', 'off');
set(handles.menu_plot_markers, 'checked', 'off');
set(handles.menu_plot_lines, 'checked', 'off');
if handles.menu_double_buffer
    set(handles.menu_double_buffer, 'checked', 'on');
else
    set(handles.menu_double_buffer, 'checked', 'off');
end
if handles.settings.plot_markers
    if handles.settings.plot_lines
        set(handles.menu_plot_both, 'checked', 'on');
    else
        set(handles.menu_plot_markers, 'checked', 'on');
    end
else
    set(handles.menu_plot_lines, 'checked', 'on');
end
% set(handles.cb_other, 'Value', ~handles.settings.show_orig);
% Initialize prompt menu item checked
if handles.settings.prompt
    set(findobj('Type', 'uimenu', 'Label', 'Prompt for settings'), 'Checked', 'on');
else
    set(findobj('Type', 'uimenu', 'Label', 'Prompt for settings'), 'Checked', 'off');    
end
% If running as a deployed application, won't be able to send anything to
% the workspace
if isdeployed
    set(handles.menu_workspace, 'visible', 'off');
end
% Set the SelectionChangeFcn of the calibration button group
set(handles.bgr_calibrate, 'SelectionChangeFcn', @bgr_calibrate_SelectionChangeFcn);
% Store handles
guidata(hObject, handles);
% Resize table columns to make it look a bit better (hopefully)
resize_table_columns(handles);
% Initialize calibration value
set_calibration(hObject, handles.settings.calibration_value, handles.settings.calibration_value);



% It typically looks better if the table columns fill the whole table, but
% the table size is in characters (system dependent) and column widths in
% pixels (system independent), so appropriate column widths need to be
% determined
function resize_table_columns(handles)
% Get the size of the table in pixels
units = get(handles.tbl_vessel, 'Units');
set(handles.tbl_vessel, 'Units', 'Pixels');
pos = get(handles.tbl_vessel, 'Position');
% Get the column widths (always in pixels, it seems)
col_width = get(handles.tbl_vessel, 'ColumnWidth');
% Maximum width in pixels (approximately - 4 px better on Mac)
max_width = pos(3) - 5;
% Set column 1 to 65%, column 2 to 35%
col_width{1} = round(max_width * .65);
col_width{3} = round(max_width * .1);
col_width{2} = max_width - col_width{1} - col_width{3};
% Set the column width and reset the units of the table (probably not necessary)
set(handles.tbl_vessel, 'ColumnWidth', col_width, 'Units', units);




% Save main preferences
function savePrefs_Callback(hObject, eventdata, handles)
settings = handles.settings;
checked_menu_items = get(findobj('Type', 'uimenu', 'Checked', 'on'), 'Label');
% Put in a cell array if only one checked menu item present, otherwise they
% will be in a cell array anyway
if ischar(checked_menu_items)
    checked_menu_items = {checked_menu_items};
end
save(handles.prefsfile, 'settings', 'checked_menu_items');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% BUTTON CALLBACK FUNCTIONS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in btn_show_image.
function btn_show_image_Callback(hObject, eventdata, handles)
if isempty(handles.vessel_data)
    return;
end
s = warning('off', 'Images:initSize:adjustingMag');
imshow(handles.vessel_data);
warning(s);



% --- Executes on button press in btn_delete_vessel.
function btn_delete_vessel_Callback(hObject, eventdata, handles)
vessel = get_selected_vessel(handles);
% Check there is a vessel to delete
if isempty(vessel)
    warndlg('There is no selected vessel to delete!');
    return;
end
% Get the index of the currently selected vessel
ind_selected = handles.vessel_data.selected_vessel_ind;
% Delete the vessel
handles.vessel_data.delete_vessels(ind_selected);
% Update the drop-down list
update_drop_down_list(handles);
% Update the other data
update_diameters_list(handles);
update_vessel_table(handles);



% --- Executes on button press in btn_show_vessel.
function btn_show_vessel_Callback(hObject, eventdata, handles)
vessel = get_selected_vessel(handles);
if ~isempty(vessel)
    imshow(vessel);
end



% --- Executes on button press in btn_plot_vessel.
function btn_plot_vessel_Callback(hObject, eventdata, handles)
vessel = get_selected_vessel(handles);
if ~isempty(vessel)
    vessel.plot;
end



% --- Executes on button press of btn_include or btn_exclude.
function btnIncludeExclude_Callback(hObject, eventdata, handles)
vessel = get_selected_vessel(handles);
if isempty(vessel)
    return;
end
sel = get(handles.lb_diameters, 'Value');
vessel.keep_inds(sel) = strcmp(get(hObject, 'Tag'), 'btn_include');
handles.vessel_data.update_image_lines;
update_diameters_list(handles, false);
update_vessel_plot(handles);
update_vessel_table(handles);




% --- Executes on button press in btn_calibrate.
function btn_calibrate_Callback(hObject, eventdata, handles)
% Prompt user for calibration value and unit
new_cal_text = inputdlg(...
    {'Input new calibration value',...
    'Input new calibration unit (e.g. mm, um, px...)'}, ...
    'Calibration', 1, ...
    {num2str(handles.settings.calibration_value), ...
    handles.settings.calibration_unit});
% Check whether user pressed 'cancel'
if isempty(new_cal_text)
    return;
end
% Try to parse and apply input
new_cal_value = str2double(new_cal_text{1});
if isempty(new_cal_value) || isnan(new_cal_value) || new_cal_value <= 0
    errordlg('Invalid calibration value! Input must be a positive number.');
    return;
end
new_cal_unit = new_cal_text{2};
set_calibration(hObject, new_cal_value, new_cal_unit);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% OTHER CALLBACK FUNCTIONS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on selection change in lb_diameters.
function lb_diameters_Callback(hObject, eventdata, handles)
update_highlighted_diameters(handles);


% --- Executes on selection change in pop_vessels.
function pop_vessels_Callback(hObject, eventdata, handles)
if isempty(handles.vessel_data)
    return;
end
s = get(handles.pop_vessels, 'String');
if strcmpi(s, 'None')
    handles.vessel_data.selected_vessel_ind = -1;
else
    handles.vessel_data.selected_vessel_ind = get(handles.pop_vessels, 'Value');
    update_diameters_list(handles);
end
update_vessel_table(handles);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% UPDATE FUNCTIONS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Updates the highlighted diameters according to those selected in the list box
function update_highlighted_diameters(handles)
if ~isempty(handles.vessel_data)
    lb_selected = get(handles.lb_diameters, 'Value');
    % Update selection in VESSEL_DATA
    handles.vessel_data.set_highlight_inds(lb_selected);
    % Update profile plot
    vessel = get_selected_vessel(handles);
    if ~isempty(vessel)
        axes(handles.ax_image);
        vessel.plot_profiles(lb_selected);
        % Add shadow to make it less ugly
        shadow_plot(gca, [.55 .55 .55]);
    end
end


% Update the plot for the currently selected vessel, or for all vessels
function update_vessel_plot(handles)
vessel = get_selected_vessel(handles);
if isempty(vessel)
    return;
end
vessel.update_plot;



% Updates drop-down vessel list
function update_drop_down_list(handles, reset_selected)
if isempty(handles.vessel_data)
    set(handles.pop_vessels, 'String', 'None');
    set(handles.pop_vessels, 'Value', 1);
else
    s = int2str((1:length(handles.vessel_data.vessel_list))');
    set(handles.pop_vessels, 'String', cellstr(s));
    set(handles.pop_vessels, 'Value', 1);
    if nargin < 2 || reset_selected
        handles.vessel_data.selected_vessel_ind = 1;
    end
end



% Updates the list of diameters
function update_diameters_list(handles, reset_selected)
% Do reset selection by default
if nargin < 2
    reset_selected = true;
end
% Check whether there is a vessel selected
vessel = get_selected_vessel(handles);
if isempty(vessel)
    update_highlighted_diameters(handles);
    set(handles.lb_diameters, 'ListBoxTop', 1, ...
                              'String', [], ...
                              'Max', 0, ...
                              'Min', 0, ...
                              'Value', 1);
    return;
end
% Get the info string
str = vessel.string;
num_diameters = size(str, 1);
if reset_selected
    set(handles.lb_diameters, 'ListBoxTop', 1, ...
                              'String', str, ...
                              'Max', num_diameters, ...
                              'Min', 0, ...
                              'Value', 1);
else
    set(handles.lb_diameters, 'String', str, ...
                          'Max', num_diameters, ...
                          'Min', 0);
end
% set(handles.lb_diameters, 'Value', 1);
update_highlighted_diameters(handles);



% Update the table containing summary values
function update_vessel_table(handles)
data = get(handles.tbl_vessel, 'Data');
vessel = get_selected_vessel(handles);
if isempty(vessel) || vessel.num_diameters < 1 || ~any(vessel.keep_inds)
    % Clear table
    data(:, 2) = {[]; []; []; []; []; []; []; []};
else
    % Fill in diameter stats
    d = vessel.diameters(vessel.keep_inds);
    data{1,2} = numel(d);
    data{2,2} = mean(d);
    data{3,2} = std(d);
    data{4,2} = min(d);
    data{5,2} = max(d);
    % Calculate length
    ind1 = find(vessel.keep_inds, 1, 'first');
    ind2 = find(vessel.keep_inds, 1, 'last');
    len = vessel.offset(ind2) - vessel.offset(ind1);
    data{6,2} = len;
    % Calculate diameter / length
    data{7,2} = mean(d) / len;
    % Calculate tortuosity
    direct_len = sqrt(sum((vessel.centre(ind2,:) - vessel.centre(ind1,:)).^2)) * vessel.scale_value;
    tort = len / direct_len;
    data{8,2} = tort;
    % Fill in units
    unit = vessel.scale_unit;
    for ii = [2, 3, 4, 5, 6]
        data{ii, 3} = unit;
    end
end
set(handles.tbl_vessel, 'Data', data);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% GET / SET FUNCTIONS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Gets the currently selected VESSEL from HANDLES.VESSEL_DATA is possible
function vessel = get_selected_vessel(handles)
vessel = [];
if ~isempty(handles.vessel_data)
    vessel = handles.vessel_data.selected_vessel;
end



% Update the calibration value
function set_calibration(hObject, new_cal_value, new_cal_unit)
handles = guidata(hObject);
if ~isempty(new_cal_value)
    handles.settings.calibration_value = new_cal_value;
end
if nargin > 2 && ~isempty(new_cal_unit)
    handles.settings.calibration_unit = new_cal_unit;
end
set(handles.txt_calibrate, 'String', ...
    [num2str(handles.settings.calibration_value, 5), ' ', ...
    handles.settings.calibration_unit, ' per pixel']);
% Update painting if necessary
if handles.settings.calibrate
    update_vessel_plot(handles);
end
% Update table
update_vessel_table(handles);
% Update list
update_diameters_list(handles, false);



% --- Executes on button press in cb_diameters.
function cb_diameters_Callback(hObject, eventdata, handles)
handles.settings.show_diameters = get(handles.cb_diameters, 'Value');
if ~isempty(handles.vessel_data)
    handles.vessel_data.update_image_lines;
end


% --- Executes on button press in bgr_calibrate button group.
function bgr_calibrate_SelectionChangeFcn(hObject, eventdata)
handles = guidata(hObject);
handles.settings.calibrate = ~get(handles.rb_pixels, 'Value');
update_vessel_plot(handles);
update_vessel_table(handles);
update_diameters_list(handles, false);


% --- Executes on button press in cb_centre.
function cb_centre_Callback(hObject, eventdata, handles)
handles.settings.show_centre_line = get(handles.cb_centre, 'Value');
if ~isempty(handles.vessel_data)
    handles.vessel_data.update_image_lines;
end


% --- Executes on button press in cb_edges.
function cb_edges_Callback(hObject, eventdata, handles)
handles.settings.show_edges = get(handles.cb_edges, 'Value');
if ~isempty(handles.vessel_data)
    handles.vessel_data.update_image_lines;
end

% --- Executes on button press in cb_selected.
function cb_selected_Callback(hObject, eventdata, handles)
if isempty(handles.vessel_data)
    return;
end
handles.settings.show_highlighted = get(handles.cb_selected, 'Value');
handles.vessel_data.update_image_lines;
update_vessel_plot(handles);



% --- Executes on button press in cb_labels.
function cb_labels_Callback(hObject, eventdata, handles)
handles.settings.show_labels = get(handles.cb_labels, 'Value');
if ~isempty(handles.vessel_data)
    handles.vessel_data.update_image_lines;
end


% --- Executes on button press in cb_optic_disc.
function cb_optic_disc_Callback(hObject, eventdata, handles)
handles.settings.show_optic_disc = get(handles.cb_optic_disc, 'Value');
if ~isempty(handles.vessel_data)
    handles.vessel_data.update_image_lines;
end




% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% Only enable save and export options if there is something to save or
% export
if isempty(handles.vessel_data)
    set(handles.menu_save, 'enable', 'off');
    set(handles.menu_workspace, 'enable', 'off');
else
    set(handles.menu_save, 'enable', 'on');
    set(handles.menu_workspace, 'enable', 'on');
end


% --------------------------------------------------------------------
function menu_open_Callback(hObject, eventdata, handles)
% Get image filter
load('ARIA_image_file_filter', 'filter');
% Prompt user to select file
[fname, fpath] = uigetfile(filter,'Choose a file to open', handles.settings.last_path);
% No file selected
if isequal(fname, 0)
    return;
end
% Store path
handles.settings.last_path = fpath;
% Update text box - keep previous text in case open fails
previous_text = get(handles.txt_file, 'String');
set(handles.txt_file, 'String', 'Opening...');
process_time = NaN;
try
    % Load VESSEL_DATA from file
    [vessel_data, process_time] = Vessel_Data_IO.load_from_file(fullfile(fpath, fname), ...
                                           get_processor, handles.settings);
    % No VESSEL_DATA returned, but also an error wasn't thrown, so assume
    % that the user cancelled gracefully
    if isempty(vessel_data)
        set(handles.txt_file, 'String', previous_text);
        return;
    end
    % It's possible that the calibration has changed
    set_calibration(hObject, vessel_data.settings.calibration_value, ...
                             vessel_data.settings.calibration_unit);
catch ME
    % Opening failed with an error
    disp(ME);
    set(handles.txt_file, 'String', previous_text);
    rethrow(ME);
end
% Got this far... store result
handles.vessel_data = vessel_data;
% Update drop down vessel list
update_drop_down_list(handles);
% % Show thumbnail image
% axes(handles.ax_image);
% cla;
% imshow(handles.vessel_data.im, []);
% Update text box with opened file name - and processing time, if relevant
if ischar(vessel_data.file_name)
    fname = vessel_data.file_name;
end
if ~isnan(process_time)
    fname = sprintf([fname, '\n(', num2str(process_time), ' seconds)']);
end
set(handles.txt_file, 'String', fname);
% Update the list of diameters
update_diameters_list(handles);
% Update the table
update_vessel_table(handles);
% Save the handles structure.
guidata(hObject,handles)




% --------------------------------------------------------------------
function menu_save_Callback(hObject, eventdata, handles)
% Nothing to save
if isempty(handles.vessel_data)
    errordlg('Nothing available to save!');
    return;
end
% Figure out a sensible default save file name ending in .MAT
full_file = fullfile(handles.vessel_data.file_path, handles.vessel_data.file_name);
ind = find(full_file == '.', 1, 'last');
if isempty(ind)
    default_save_name = [full_file, '.mat'];
else
    default_save_name = [full_file(1:ind), 'mat'];
end
% Prompt user to confirm save file name
[fname, fpath] = uiputfile({'*.mat','MAT Files'},'Save MAT file',default_save_name);
% If user didn't cancel, save the file
if ~isequal(fname, 0)
    save_file = fullfile(fpath, fname);
    Vessel_Data_IO.save_to_file(save_file, handles.vessel_data);
end


% --- Executes on button press in btn_include.
function btn_include_Callback(hObject, eventdata, handles)
btnIncludeExclude_Callback(hObject, eventdata, handles);


% --- Executes on button press in btn_exclude.
function btn_exclude_Callback(hObject, eventdata, handles)
btnIncludeExclude_Callback(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menu_spacing_Callback(hObject, eventdata, handles)
last_spacing = handles.settings.show_spacing;
set_view_spacing(handles.settings);
new_spacing = handles.settings.show_spacing;
if (last_spacing ~= new_spacing) && ~isempty(handles.vessel_data)
    handles.vessel_data.update_image_lines;
end


% --------------------------------------------------------------------
function menu_colours_Callback(hObject, eventdata, handles)
changed = display_colours_dlg(handles.settings);
if changed && ~isempty(handles.vessel_data)
    handles.vessel_data.update_image_lines([], true);
    % Update profile plot
    vessel = get_selected_vessel(handles);
    if ~isempty(vessel)
        vessel.update_plot;
    end
end


% --------------------------------------------------------------------
function menu_workspace_Callback(hObject, eventdata, handles)
if isempty(handles.vessel_data)
    errordlg('No data available!', 'Send to workspace');
elseif ~isdeployed
    assignin('base', 'vessel_data', handles.vessel_data);
end



% --------------------------------------------------------------------
function menu_sort_diameter_Callback(hObject, eventdata, handles)
if ~isempty(handles.vessel_data)
    handles.vessel_data.sort_by_diameter;
    update_drop_down_list(handles);
    update_diameters_list(handles);
end


% --------------------------------------------------------------------
function menu_sort_length_Callback(hObject, eventdata, handles)
if ~isempty(handles.vessel_data)
    handles.vessel_data.sort_by_length;
    update_drop_down_list(handles);
    update_diameters_list(handles);
end


% --------------------------------------------------------------------
function menu_vessels_Callback(hObject, eventdata, handles)
% Only allow sorting / deleting if there is something to sort / delete
if isempty(handles.vessel_data)
    set(handles.menu_sort_vessels, 'enable', 'off');
    set(handles.menu_delete, 'enable', 'off');
else
    set(handles.menu_sort_vessels, 'enable', 'on');
    set(handles.menu_delete, 'enable', 'on');
end



% --------------------------------------------------------------------
function menu_image_orig_Callback(hObject, eventdata, handles)
if strcmp(get(handles.menu_image_orig, 'Checked'), 'on')
    return;
end
set(handles.menu_image_orig, 'Checked', 'on');
set(handles.menu_image_grayscale, 'Checked', 'off');
handles.settings.show_orig = true;
if ~isempty(handles.vessel_data) && handles.vessel_data.is_showing
    handles.vessel_data.imshow;
end


% --------------------------------------------------------------------
function menu_image_grayscale_Callback(hObject, eventdata, handles)
if strcmp(get(handles.menu_image_grayscale, 'Checked'), 'on')
    return;
end
set(handles.menu_image_grayscale, 'Checked', 'on');
set(handles.menu_image_orig, 'Checked', 'off');
handles.settings.show_orig = false;
if ~isempty(handles.vessel_data) && handles.vessel_data.is_showing
    handles.vessel_data.imshow;
end


% --------------------------------------------------------------------
function menu_delete_few_Callback(hObject, eventdata, handles)
% Need vessel data to be present
vessel_data = handles.vessel_data;
if isempty(vessel_data)
    return;
end
% Clean segments, prompting user for length
n_vessels = vessel_data.num_vessels;
if n_vessels > 1
    args.min_diameters = min([vessel_data.vessel_list.num_diameters]);
    clean_short_vessels(vessel_data, args, true);
end
% Calculate number removed
n_removed = n_vessels - vessel_data.num_vessels;
if n_removed == 0
    return;
end
% Update lists etc.
update_drop_down_list(handles);
update_diameters_list(handles);
% vessel_data.update_image_lines([], true);
update_vessel_table(handles);
% Display number removed
if n_removed == 1
    msgbox('1 vessel segment removed', 'Remove short vessel segments', 'Modal');
else
    msgbox([num2str(n_removed) ' vessel segments removed'], 'Remove short vessel segments', 'Modal');
end


% --- Executes on button press in btn_select_all.
function btn_select_all_Callback(hObject, eventdata, handles)
% Get the number of strings in the list box, and the indices for each
n_strings = size(get(handles.lb_diameters, 'String'));
string_inds = 1:n_strings;
% Get the current index of the selected strings
selected = get(handles.lb_diameters, 'Value');
% If they don't match, select all
if ~isequal(string_inds, selected)
    set(handles.lb_diameters, 'Value', string_inds);
    update_highlighted_diameters(handles);
end



% --------------------------------------------------------------------
function menu_plot_both_Callback(hObject, eventdata, handles)
if ~strcmp(get(handles.menu_plot_both, 'checked'), 'on')
    set(handles.menu_plot_lines, 'checked', 'off');
    set(handles.menu_plot_markers, 'checked', 'off');
    set(handles.menu_plot_both, 'checked', 'on');
    handles.settings.plot_lines = true;
    handles.settings.plot_markers = true;
    update_vessel_plot(handles);
end


% --------------------------------------------------------------------
function menu_plot_markers_Callback(hObject, eventdata, handles)
if ~strcmp(get(handles.menu_plot_markers, 'checked'), 'on')
    set(handles.menu_plot_lines, 'checked', 'off');
    set(handles.menu_plot_markers, 'checked', 'on');
    set(handles.menu_plot_both, 'checked', 'off');
    handles.settings.plot_lines = false;
    handles.settings.plot_markers = true;
    update_vessel_plot(handles);
end


% --------------------------------------------------------------------
function menu_plot_lines_Callback(hObject, eventdata, handles)
if ~strcmp(get(handles.menu_plot_lines, 'checked'), 'on')
    set(handles.menu_plot_lines, 'checked', 'on');
    set(handles.menu_plot_markers, 'checked', 'off');
    set(handles.menu_plot_both, 'checked', 'off');
    handles.settings.plot_lines = true;
    handles.settings.plot_markers = false;
    update_vessel_plot(handles);
end


% --------------------------------------------------------------------
function menu_copy_Callback(hObject, eventdata, handles)
if isempty(get_selected_vessel(handles))
    status = 'off';
else
    status = 'on';
end
set(handles.menu_copy_diameters, 'enable', status);
set(handles.menu_copy_table, 'enable', status);


% --------------------------------------------------------------------
function menu_copy_diameters_Callback(hObject, eventdata, handles)
vessel = get_selected_vessel(handles);
if ~isempty(vessel)
    vessel.copy_to_clipboard;
end


% --------------------------------------------------------------------
function menu_copy_table_Callback(hObject, eventdata, handles)
vessel = get_selected_vessel(handles);
if ~isempty(vessel)
    % Get table data and make string to copy
    data = get(handles.tbl_vessel, 'Data');
    str = '';
    for ii=1:size(data,1)
        str = [str, data{ii,1}, char(9), num2str(data{ii,2}), char(9), data{ii,3}, char(10)];
    end
    clipboard('copy', str);
end


% --------------------------------------------------------------------
function menu_retina_Callback(hObject, eventdata, handles)
if isempty(handles.vessel_data)
    set(handles.menu_optic_disc_set, 'enable', 'off');
else
    set(handles.menu_optic_disc_set, 'enable', 'on');
end



% --------------------------------------------------------------------
function menu_optic_disc_set_Callback(hObject, eventdata, handles)
if ~isempty(handles.vessel_data)
    % Get total number of diameters currently present
    tot_diameters = handles.vessel_data.total_diameters;
    % Do processing
%     set(handles.
    [args, cancelled] = optic_disc_mask(handles.vessel_data);
    % Compare total number of diameters now present... only need to update
    % tables and lists if different
    if ~cancelled && tot_diameters ~= handles.vessel_data.total_diameters
        % Update the drop-down list
        update_drop_down_list(handles);
        % Update the other data
        update_diameters_list(handles);
        update_vessel_table(handles);
    end
end


% --- Executes when user attempts to close fig_Vessel_Analyser.
function fig_Vessel_Analyser_CloseRequestFcn(hObject, eventdata, handles)
% Hint: delete(hObject) closes the figure
delete(hObject);


% --------------------------------------------------------------------
function menu_double_buffer_Callback(hObject, eventdata, handles)
if strcmp(get(handles.menu_image_orig, 'Checked'), 'on')
    return;
end
if handles.settings.double_buffer
    handles.settings.double_buffer = false;
    set(handles.menu_double_buffer, 'Checked', 'off');
else
    handles.settings.double_buffer = true;
    set(handles.menu_double_buffer, 'Checked', 'on');    
end
if ~isempty(handles.vessel_data) && handles.vessel_data.is_showing
    handles.vessel_data.imshow;
end
