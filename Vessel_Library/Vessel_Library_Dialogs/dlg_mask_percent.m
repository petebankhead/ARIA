function varargout = dlg_mask_percent(varargin)
% DLG_MASK_PERCENT M-file for dlg_mask_percent.fig
% Displays a dialog box allowing the user to interactively choose
% thresholds to create a field of view (FOV) mask.
%
% Input:
%   IM - an image
%   DARK_THRESHOLD - default low threshold, i.e. darker pixels excluded
%   BRIGHT_THRESHOLD - default high threshold, i.e. brighter pixels excluded
%   LARGEST_REGION - TRUE ie the single largest region should be used,
%   rather than all pixels within the thresholds.
%
% Output:
%   BW - the binary image
%   DARK_THRESHOLD, BRIGHT_THRESHOLD and LARGEST_REGION - the actual values
%   that were finally chosen when creating BW
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Last Modified by GUIDE v2.5 07-Jun-2009 16:11:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dlg_mask_percent_OpeningFcn, ...
                   'gui_OutputFcn',  @dlg_mask_percent_OutputFcn, ...
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


% --- Executes just before dlg_mask_percent is made visible.
function dlg_mask_percent_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dlg_mask_percent (see VARARGIN)

% Choose default command line output for dlg_mask_percent
handles.output = hObject;

% Get image from input
im = varargin{1};

% Store image
handles.im = im;

% Will need a version of the image that is UINT8 and colour for display
handles.im_uint8 = im2uint8(im);

% Show image histogram
% axes(handles.ax_hist);
[handles.counts, handles.pixels] = imhist(im);
stem(handles.ax_hist, handles.pixels, handles.counts, 'Marker', 'None');
handles.cum_counts = cumsum(handles.counts);

% Set up default input arguments in case none are available
if nargin < 2
    handles.dark_threshold = 0;
else
    handles.dark_threshold = varargin{2};    
end
if nargin < 3
    handles.bright_threshold = max(im(:));
else
    handles.bright_threshold = varargin{3};    
end
if nargin < 4
    handles.largest_region = false;
else
    handles.largest_region = varargin{4};    
end

% Update sliders
ss = [.01, .1];
minVal = 0;
if isa(im, 'uint8')
    maxVal = 255;
elseif isa(im, 'uint16')
    maxVal = 65535;
else
    maxVal = min(max(im(:)), handles.bright_threshold);
    minVal = max(0, min(im(:)));
end
set(handles.sld_dark, 'Min', minVal, 'Max', maxVal, 'SliderStep', ss, 'Value', handles.dark_threshold);
set(handles.sld_bright, 'Min', minVal, 'Max', maxVal, 'SliderStep', ss, 'Value', handles.bright_threshold);

% Update checkbox
set(handles.cb_region, 'Value', handles.largest_region);
% set(handles.ax_hist, 'YScale', 'log');

% Update handles structure
guidata(hObject, handles);

% Update thresholds and display
update_thresholds(hObject);

% UIWAIT makes dlg_mask_percent wait for user response (see UIRESUME)
uiwait(handles.fig_mask);




function update_thresholds(hObject)
% Update the thresholds, read from the sliders, and the display if necessary
handles = guidata(hObject);
dark_threshold = get(handles.sld_dark, 'Value');
bright_threshold = get(handles.sld_bright, 'Value');
largest_region = get(handles.cb_region, 'Value');

set(handles.txt_dark, 'String', ['Mask out pixels < ', num2str(dark_threshold)]);
set(handles.txt_bright, 'String', ['Mask out pixels > ', num2str(bright_threshold)]);

% Store the binary mask image
handles.bw = mask_threshold(handles.im, dark_threshold, bright_threshold, largest_region);
guidata(hObject, handles);
drawnow;
if dark_threshold ~= get(handles.sld_dark, 'Value') || bright_threshold ~= get(handles.sld_bright, 'Value') || largest_region ~= get(handles.cb_region, 'Value')
    update_thresholds(hObject);
else
    update_mask_display(handles);
end



% Update the overlay image showing the mask
function update_mask_display(handles)
% Create an image for display - use mask to decide red channel
im_red = handles.im_uint8;
im_red(~handles.bw) = 255;
im_green_blue = handles.im_uint8;
im_green_blue(~handles.bw) = 0;
im_disp = cat(3, im_red, im_green_blue, im_green_blue);

% Get handle to image
ax_image = findobj(handles.ax_image, 'type', 'image');
% If none found, need to create a new image to display
if isempty(ax_image)
    imshow(im_disp, 'Parent', handles.ax_image);
else
    set(ax_image, 'CData', im_disp);
end



% --- Outputs from this function are returned to the command line.
function varargout = dlg_mask_percent_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
if ~isempty(handles)
    % First output argument is the binary mask
    varargout{1} = handles.bw;
    % Update the output arguments
    if nargout >= 2
        varargout{2} = get(handles.sld_dark, 'Value');
    end
    if nargout >= 3
        varargout{3} = get(handles.sld_bright, 'Value');
    end
    if nargout >= 4
        varargout{4} = get(handles.cb_region, 'Value');
    end
    delete(handles.fig_mask);
else
    for ii = nargout:-1:1
        varargout{ii} = [];
    end
%     varargout{1} = [];
end


% --- Executes on slider movement.
function update_thresholds_Callback(hObject, eventdata, handles)
update_thresholds(hObject);


% --- Executes on button press in btn_ok.
function btn_ok_Callback(hObject, eventdata, handles)
% hObject    handle to btn_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.fig_mask);



% --- Executes during object creation, after setting all properties.
function sld_bright_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
