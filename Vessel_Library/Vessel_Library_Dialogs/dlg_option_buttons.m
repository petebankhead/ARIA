function val = dlg_option_buttons(prompt, options, title_string)
% Show the user a list of buttons, and prompt for one to be selected.
%
% Input:
%   PROMPT - the text prompt to give
%   OPTIONS - a cell array containing the text for each button
%   TITLE_STRING - the title for the dialog
%
% Output:
%   VAL - The index into the cell array of the user-selected option
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% If user doesn't press a button, return 0
val = 0;

% Default sizes
width = 180;
text_height = 20;
button_height = 30;

% Initialise button handle array
buttons = zeros(1, numel(options));

% Create figure
fig_pos = [0, 0, width, button_height*numel(buttons)+text_height];
if nargin >= 3
    f = dialog('Visible', 'off', 'MenuBar', 'none', ...
           'Position', fig_pos, 'Name', title_string);
else
    f = dialog('Visible', 'off', 'MenuBar', 'none', ...
           'Position', fig_pos);
end       

% Create text control
text_pos = [5, numel(buttons)*button_height, width, text_height];
t = uicontrol(f, ...
    'Style', 'text', ...
    'BackgroundColor', get(f, 'Color'), ...
    'Position', text_pos);
[prompt, new_pos] = textwrap(t, {prompt});
set(t, 'String', prompt);

% Resize figure and text control to fit text
fig_pos(4) = button_height * numel(buttons) + new_pos(4);
% Not really sure why width needs to be increased on the Mac... presumably
% this won't last forever, and a Java update somewhere will change it...
if ismac
    fig_pos(3) = fig_pos(3) + 5;
end
set(f, 'Position', fig_pos);
text_pos(4) = new_pos(4);
set(t, 'Position', text_pos);
       
% Add buttons
for ii = 1:numel(buttons)
    buttons(ii) = uicontrol(f, ...
        'Style', 'pushbutton', ...
        'String', options{ii}, ...
        'Position', [5, (numel(buttons)-ii)*button_height, width, button_height], ...
        'UserData', ii, ...
        'Callback', @button_callback);
end

% Centre and display figure, then wait for user input
movegui(f, 'center');
set(f, 'Visible', 'on');
uiwait(f);

% An alternative, perhaps more official MATLAB way...
% listdlg('PromptString', prompt, ...
%     'SelectionMode', 'single', ...
%     'ListString', options);


    function button_callback(hObject, eventdata)
        val = get(hObject, 'UserData');
        close(f);
    end
end