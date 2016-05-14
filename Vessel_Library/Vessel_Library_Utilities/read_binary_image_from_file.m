function [bw, file_path, file_name] = read_binary_image_from_file(siz, title, path)
% Read a binary image from a file selected by the user.
% 
% Input:
%   SIZ - a 2 element array giving the size the image should be
%   TITLE - the title to put in the file chooser dialog
%   PATH - the default file path to be used for the file chooser
%
% Output:
%  BW - the binary image that was read
%  FILE_PATH and FILE_NAME - the selected file path and names
%  respectively
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

% No size supplied
if nargin < 1
    siz = [];
end

% No title supplied
if nargin < 2
    title = 'Choose binary image';
end

% No path supplied
if nargin < 3 || isempty(path) || ~ischar(path)
    path = [];
end

% Initialize empty array
bw = [];

% Get file filter for images
load('ARIA_image_file_filter', 'filter');

% Read binary image from file requested from user
% [file_name, file_path] = uigetfile(filter,['Choose segmented file for ', fname], fpath);
[file_name, file_path] = uigetfile(filter, title, path);
if file_name == 0
    return;
% Try to read mask from a MAT file - look for first object contained in the
% file that is the correct size, if possible
else if length(file_name) > 4 && strcmpi(file_name(end-3:end), '.mat')
        S = load(file_name);
        fs = fields(S);
        % No size supplied - just return first object
        if isempty(siz)
            bw = S.(fs{1}) > 0;
        end
        % Size given - look for an object of the correct size
        for ii = 1:numel(fs)
            temp = S.(fs{ii});
            if size(temp) == siz
                bw = temp > 0;
                return;
            end
        end
        return;
    end
end
% Read from file
bw = any(imread(fullfile(file_path, file_name)) > 0, 3);

% Test size
if ~isempty(siz) && ~isequal(size(bw), siz)
    warndlg(...
        ['Incorrect size!', ...
        'Binary image is ', num2str(size(bw,1)), ' x ', num2str(size(bw,2)), ' pixels, but ' ...
        'should be ', num2str(siz(1)), ' x ', num2str(siz(2)), 'pixels.\n'], ...
        title);
    bw = [];
end