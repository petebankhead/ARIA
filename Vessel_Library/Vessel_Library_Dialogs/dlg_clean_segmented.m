function varargout = dlg_clean_segmented(varargin)
% DLG_CLEAN_SEGMENTED M-file for dlg_clean_segmented.fig
%      Displays a dialog box allowing the user to remove objects or fill
%      holes in a binary image.
%
% Input:
%   BW - a binary image
%   MIN_OBJECT - minimum object area to keep (scalar)
%   MIN_HOLE - minimum hole area to keep unfilled (scalar)
%   BW_MASK - a binary mask (TRUE in the ROI, FALSE elsewhere) or []
%
% Output:
%   BW, MIN_OBJECT and MIN_HOLE, modified according to the choices made by
%   the user.
%
%
% See HELP SEG_IUWT for more details.
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% Last Modified by GUIDE v2.5 05-May-2009 23:49:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dlg_clean_segmented_OpeningFcn, ...
                   'gui_OutputFcn',  @dlg_clean_segmented_OutputFcn, ...
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




% --- Executes just before dlg_clean_segmented is made visible.
function dlg_clean_segmented_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for dlg_clean_segmented
handles.output = hObject;

% Update display fields
handles.bw_orig = varargin{1};
set(handles.edt_delete_objects, 'String', num2str(varargin{2}), 'UserData', varargin{2});
set(handles.edt_fill_holes, 'String', num2str(varargin{3}), 'UserData', varargin{3});
% If there is a mask, the total number of pixels is the area of the ROI,
% otherwise it is the size of BW_ORIG
if numel(varargin) >= 4 && isequal(size(varargin{1}), size(varargin{4}))
    handles.total_px = nnz(varargin{4});
else
    handles.total_px = numel(handles.bw_orig);
end

% Create obj_holes field in 'handles' structure, store it and update display
guidata(hObject, handles);
update_display(hObject);
% UIWAIT makes dlg_clean_segmented wait for user response (see UIRESUME)
uiwait(handles.fig_clean_segmented);




% --- Outputs from this function are returned to the command line.
function varargout = dlg_clean_segmented_OutputFcn(hObject, eventdata, handles) 
if ~isempty(handles)
    % User pressed 'OK'
    varargout{1} = handles.bw;
    varargout{2} = get(handles.edt_delete_objects, 'UserData');
    varargout{3} = get(handles.edt_fill_holes, 'UserData');
    delete(handles.fig_clean_segmented);
else
    % Default output (window closed some other way)
    for ii = 1:nargout
        varargout{ii} = [];
    end
end


% User presses 'OK' to dismiss dialog.
function btn_OK_Callback(hObject, eventdata, handles)
uiresume(handles.fig_clean_segmented);



% Update the displayed image.
function update_display(hObject)
handles = guidata(hObject);
% Remove small objects
min_object_size = get(handles.edt_delete_objects, 'UserData') * handles.total_px / 100;
% Fill small holes
min_hole_size = get(handles.edt_fill_holes, 'UserData') * handles.total_px / 100;
% Create updated binary image
handles.bw = clean_segmented_image(handles.bw_orig, min_object_size, min_hole_size);
% Update segmented axis
ax = findobj(handles.ax_segment, 'type', 'image');
if isempty(ax);
    imshow(handles.bw, [], 'Parent', handles.ax_segment);
else
    set(ax, 'CData', handles.bw);
end
% Update output
guidata(hObject, handles);


% Respond to user changing the object/hole area thresholds.
function edt_Callback(hObject, eventdata, handles)
user_entry = str2double(get(hObject,'string'));
if isnan(user_entry)
    set(hObject,'string', '-');
    set(hObject,'UserData',0);
else
    val = min(max(user_entry, 0), 100);
    set(hObject,'UserData', val);
end
update_display(hObject);



% Make the edit boxes pretty in a platform-dependent manner.
function edt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
