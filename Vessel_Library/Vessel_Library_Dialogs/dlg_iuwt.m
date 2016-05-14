function varargout = dlg_iuwt(varargin)
% DLG_IUWT M-file for dlg_iuwt.fig
%      Displays a dialog box allowing the user to interactively choose
%      thresholds for an isotropic undecimated wavelet transform segmentation.
%
% Input:
%   IM - a grayscale image (real matrix)
%   BW_MASK - a binary mask (TRUE in the ROI, FALSE elsewhere)
%   DARK - TRUE if the vessels are darker than their surroundings, otherwise FALSE
%   WAVELET_LEVELS - numeric vector specifying the default wavelet levels to use
%   WAVELET_THRESHOLD - threshold to apply to the wavelet levels, which
%   relates to a proportion of the image, e.g. 0.12 would detect the 12% of
%   pixels crossing the threshold (above or below, depending on DARK)
%   DO_INPAINTING - TRUE if pixels outside the region defined by BW_MASK
%   should be assigned the value of the closest unmasked pixels prior to
%   filtering, otherwise FALSE
%
% OUTPUT:
%   BW - the segmented image
%   DARK, WAVELET_LEVELS, THRESHOLD - the final values chosen by the user
%
% See HELP SEG_IUWT for more details.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Last Modified by GUIDE v2.5 25-Aug-2011 15:52:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dlg_iuwt_OpeningFcn, ...
                   'gui_OutputFcn',  @dlg_iuwt_OutputFcn, ...
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


% --- Executes just before dlg_iuwt is made visible.
function dlg_iuwt_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for dlg_iuwt
handles.output = hObject;
% Store image
im = varargin{1};
% Store mask
handles.bw_mask = varargin{2};
% Apply in-painting if required
if ~isempty(handles.bw_mask) && (nargin > 5  && varargin{6})
    im = dist_inpainting(im, handles.bw_mask);
end
% Detect dark or light objects
set(handles.cb_dark, 'Value', varargin{3});
% Determine from checkboxes what wavelet levels to use
wavelet_checkboxes = findobj('Style', 'checkbox', 'Parent', handles.pnl_wavelet_levels);
[handles.WAVELET_LEVELS, sort_inds] = sort(cell2mat(get(wavelet_checkboxes, 'UserData')));
wavelet_checkboxes = wavelet_checkboxes(sort_inds);
% Set wavelet checkboxes
use_wavelet_levels = intersect(varargin{4}, handles.WAVELET_LEVELS);
for ii = 1:numel(use_wavelet_levels)
    set(findobj(wavelet_checkboxes, 'UserData', use_wavelet_levels(ii)), 'Value', 1);
end
% Compute and store full wavelet transform
handles.w_full = iuwt_vessel_all(im, handles.WAVELET_LEVELS);
% Set percentage threshold
set(handles.edt_percent, 'String', num2str(varargin{5} * 100), 'UserData', varargin{5});
% Update handles structure
guidata(hObject, handles);
% Update images
update_wavelet_image(hObject);
% Update display of wavelet levels and thresholded image
handles = guidata(hObject);
imshow(handles.w, [], 'Parent', handles.ax_wavelet);
set(handles.ax_wavelet, 'CLimMode', 'auto');
imshow(handles.bw, [], 'Parent', handles.ax_thresholded);
% UIWAIT makes dlg_iuwt wait for user response (see UIRESUME)
uiwait(handles.fig_iuwt);


% --- Outputs from this function are returned to the command line.
function varargout = dlg_iuwt_OutputFcn(hObject, eventdata, handles)
if ~isempty(handles)
    varargout{1} = handles.bw;
    varargout{2} = get(handles.cb_dark, 'Value') == 1;
    varargout{3} = get_wavelet_levels(handles);
    varargout{4} = get_threshold_scale(handles);
    delete(handles.fig_iuwt);
else
    for ii = 1:nargout
        varargout{ii} = [];
    end
end



% --- Executes on button press in btn_OK.
function btn_OK_Callback(hObject, eventdata, handles)
uiresume(handles.fig_iuwt);


% Update thresholed image, and image previews
function update_display(hObject)
handles = guidata(hObject);
% Update wavelet image
set(findobj(handles.ax_wavelet, 'type', 'image'), 'CData', handles.w);
% Update thresholded image
set(findobj(handles.ax_thresholded, 'type', 'image'), 'CData', handles.bw);


function levels = get_wavelet_levels(handles)
wavelet_checkboxes = findobj('Style', 'checkbox', 'Value', 1, 'Parent', handles.pnl_wavelet_levels);
selected_levels = get(wavelet_checkboxes, 'UserData');
if iscell(selected_levels)
    levels = sort(cell2mat(selected_levels));
else
    levels = sort(selected_levels);
end



function thresh = get_threshold_scale(handles)
thresh = get(handles.edt_percent, 'UserData');


function dark = get_dark_vessels(handles)
dark = get(handles.cb_dark, 'Value') == 1;


function edt_Callback(hObject, eventdata, handles)
user_entry = str2double(get(hObject,'string'));
if isnan(user_entry)
    set(hObject,'string', '-');
    set(hObject,'UserData', 0);
else
    if user_entry > 100
        user_entry = 100;
        set(hObject,'string', '100');
    elseif user_entry < 0
        user_entry = 0;
        set(hObject,'string', '0');
    end
    set(hObject,'UserData', user_entry / 100);
end
update_thresholded_image(hObject);
update_display(hObject);



% --- Executes during object creation, after setting all properties.
function edt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function update_wavelet_image(hObject)
handles = guidata(hObject);
levels = get_wavelet_levels(handles);
if ~isempty(handles.bw_mask)
    handles.w = sum(handles.w_full(:,:,levels), 3) .* handles.bw_mask;
else
    handles.w = sum(handles.w_full(:,:,levels), 3);
end
% Reset sorted_pix to make sure it will be recalculated
handles.sorted_pix = [];
guidata(hObject, handles);
update_thresholded_image(hObject);



function update_thresholded_image(hObject)
handles = guidata(hObject);
[handles.bw, handles.sorted_pix] = ...
        percentage_segment(handles.w, ...
               get_threshold_scale(handles), ...
               get_dark_vessels(handles), ...
               handles.bw_mask, ...
               handles.sorted_pix);
guidata(hObject, handles);


% --- Executes on button press in cb_dark.
function cb_Callback(hObject, eventdata, handles)
update_thresholded_image(hObject);
update_display(hObject);


% --- Executes on button press any cb_wavelet check boxes
function cb_wavelet_Callback(hObject, eventdata, handles)
update_wavelet_image(hObject);
update_display(hObject);
