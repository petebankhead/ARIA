function [w, s_out] = iuwt_vessel_all(im, levels, padding)
% Compute the 2D 'Isotropic Undecimated Wavelet Transform' as described in
% various papers by J -L Starck and F Murtagh.
% 
% Input:
%   IM - the input image
%   LEVELS - a 1-dimensional vector containing the desired wavelet levels,
%   e.g. 1:5.
%   PADDING - the same as the PADDING input argument in IMFILTER; here it
%   is 'symmetric' by default.
%
% Output:
%   W - the wavelet levels, as an array with one dimension more than IM, so
%   that wavelet level LEVELS(I) for a 2D image is in W(:,:,I)
%   S_OUT - the smoothed array associated with the wavelet transform
%   
%
% This function will compute transform and return only the requested
% levels, to avoid including too much info for large images.  Therefore the
% first 5 levels of the transform can be obtained using
%   [W, S] = IUWT_VESSEL_ALL(IM, 1:5);
%
% Individual levels can be viewed, e.g. using
%   IMSHOW(W(:,:,1), []);
%
% The inverse transform is simply
%   IM = SUM(W, 3) + S;
%
%
% SEE ALSO IUWT_VESSELS
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.

if nargin < 3
   padding = 'symmetric';
end

% Determine output class - single if input is single, or contains many elements
if strcmp(class(im), 'single') || numel(im) > 10000000
    wclass = 'single';
    s_in = single(im);
else
    wclass = 'double';
    s_in = double(im);
end   

% Preallocate wavelet output; 3-d even if input is a vector
w = zeros([size(im) length(levels)], wclass);

% B3 spline coefficients for filter
b3 = [1 4 6 4 1] / 16;

% Compute transform
for ii = 1:levels(end)
    % Create convolution kernel
    h = dilate_wavelet_kernel(b3, 2^(ii-1)-1);
    
    % Convolve and subtract to get wavelet level
    s_out = imfilter(s_in, h' * h, padding);

    % Store wavelet level only if it's in LEVELS
    ind = find(levels == ii);
    if isscalar(ind)
        w(:,:,ind) = s_in - s_out;
    end
    
    % Update input for new iteration
    s_in = s_out;
end

% Remove singleton dimensions
w = squeeze(w);



function h2 = dilate_wavelet_kernel(h, spacing)
% Dilates a wavelet kernel by entering SPACING zeros between each
% coefficient of the filter kernel H.

% Check input
if ~isvector(h) && ~isscalar(spacing)
    error(['Invalid input to DILATE_WAVELET_KERNEL: ' ...
          'H must be a vector and SPACING must be a scalar']);
end

% Preallocate the expanded filter
h2 = zeros(1, numel(h) + spacing * (numel(h) - 1));
% Ensure output kernel orientation is the same
if size(h,1) > size(h,2)
    h2 = h2';
end
% Put in the coefficients
h2(1:spacing+1:end) = h;