function set_view_spacing(settings)
% Show a dialog making it possible to change the spacing between displayed
% vessel diameters.  If the spacing is 1, all diameters are shown; if it is
% 2 then every second diameter is shown etc.... The rationale is that a
% spacing of 1 can sometimes look too dense, making it difficult to see the
% vessel behind the diameter lines themselves.  This only affects the
% display; the actual frequency of measurements is unchanged.
%
% Input:
%   SETTINGS - a VESSEL_SETTINGS object
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Prompt user for spacing setting
answer = inputdlg(...
            sprintf(['Choose the spacing of diameters to display on the image.\n', ...
             'This affects only the display; the frequency of measurements is unchanged.']), ...
            'Diameter spacing', ...
            1, ...
            {num2str(settings.show_spacing)});
        
% Dialog cancelled
if isempty(answer)
    return;
end

% Convert input to number
space = str2double(answer);

% Store if valid
if ~isfinite(space) || space < 1
    warndlg('Invalid spacing!  Must be a number >= 1');
else
    settings.show_spacing = space;
end