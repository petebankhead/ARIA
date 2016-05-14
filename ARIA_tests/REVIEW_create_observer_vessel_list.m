function vessels = REVIEW_create_observer_vessel_list(file_name, image_num, observer_num, scale_sides)
% Create an array of VESSEL objects corresponding to the manually-marked
% edge points given with the REVIEW image database for a single manual
% observer and image.
% 
% Input:
%   FILE_NAME - the name of the text file containing the observer edge 
%   point coordinates
%   IMAGE_NUM - the number of the image within the image set
%   OBSERVER_NUM - the number of the manual observer whose results should
%   be read (1, 2 or 3)
%   SCALE_SIDES - (optional) a scalar giving a numeric value by which the
%   edge points read from the file should be scaled.  This might be useful
%   if you want to scale up the HRIS points to the original image
%   resolution, in which case SCALE_SIDES should be equal to 4.  Otherwise
%   a value of 1 is probably correct.
%
% Ouput:
%   VESSELS - an array of VESSEL objects containing the edge points
%   manually marked by the observer.
%
% 
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% Don't scale the sides by default
if nargin < 4 || isempty(scale_sides)
    scale_sides = 1;
end

% Import the observer data data
txt_observers = importdata(file_name);

% Note the format of the text file containing the data.
% The first two rows are
%                           O1				O2				O3			
%   Ser     Image	Segment	Rpx	Rpy	Lpx	Lpy	Rpx	Rpy	Lpx	Lpy	Rpx	Rpy	Lpx	Lpy
% 
% The 'Image' column gives the image number, 'Segment' gives the segment
% number, then the other columns to the right give the x and y coordinates
% for each side and for each observer.

% Identify the rows containing the data relating to the the current image
rows = txt_observers.data(:, 2) == image_num;

% Extract the segment numbers (always column 3)
segment = txt_observers.data(rows, 3);

% Extract the side coordinates - remember they need to be in [row, col]
% format (i.e. switch the x, y format of the spreadsheet), and the columns
% depend upon the observer number requested
col_start = (observer_num - 1) * 4 + 4;
side1 = txt_observers.data(rows, col_start+1:-1:col_start);
side2 = txt_observers.data(rows, col_start+3:-1:col_start+2);

% Determine how many segments are present
n_segments = max(segment);

% Create a list of vessels for the observer
vessels = Vessel.empty(n_segments, 0);
for ii = 1:n_segments
    vessels(ii) = Vessel;
    rows = segment == ii;
    vessels(ii).side1 = side1(rows, :) * scale_sides;
    vessels(ii).side2 = side2(rows, :) * scale_sides;
    vessels(ii).centre = (side1(rows, :) + side2(rows, :)) / 2 * scale_sides;
end