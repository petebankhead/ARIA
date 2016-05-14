function shadow_plot(ax, col)
% Add a shadow to an existing plot by replicating all the lines, offsetting
% them to the right, increasing thickness and applying the shadow colour.
%
% Input:
%   AX is an axis handle, otherwise the current axis is used.
%   COL is the colour of the shadow.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

if nargin < 1
    ax = gca;
end

if nargin < 2
    col = [.5 .5 .5];
end

% Find and copy all line objects
h = findobj(ax, 'Type', 'Line');
h2 = copyobj(h, ax);

% Loop through objects and turn into shadows
for ii = 1:numel(h)
    
    % Get XData and offset by 1%
    x_data = get(h(ii), 'XData');
    x_data = x_data + get_range(get(ax, 'XLim')) / 100;
    
    % Increase line width by factor of 4
    w = get(h(ii), 'LineWidth') * 4;
    
    set(h(ii), 'XData', x_data, 'LineWidth', w, 'Color', col);
    
end


function range = get_range(x)
range = max(x(:)) - min(x(:));