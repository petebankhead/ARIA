function vessels = spline_centreline(vessels, piece_spacing, remove_invalid)
% Apply a least squares, smoothing spline fit to a number of Nx2
% dimensional arrays, treating them as coordinates, and output the fitted
% (i.e. smoothed) coordinates.  The arrays should already be sorted
% appropriately, so that coordinates are consecutive.
% 
% This is useful for creating a smoother representation of lines defined
% originally in terms of discrete pixel coordinates, and also computing the
% angle of the line perpendicular to the fit at each (output) coordinate,
% since the derivative of the spline can be calculated.
% 
% Note that this assumes a 2D fitting problem of coordinates.  An
% additional paramter is introduced based upon the Euclidean distance
% between coordinates, and this is used when applying 1D fits to each
% coordinate.  More information is given in the code comments.
%
% INPUT:
%   VESSELS - an array of VESSEL objects, in which the CENTRE property is
%   set.
%   PIECE_SPACING - the approximate spacing that should occur between
%   spline pieces.  The total length of the coordinate array (computed by
%   summing the Euclidean distances between each pair or coordinates) is
%   divided by this in order to figure out how many pieces should make up
%   the spline.  Note: if only one piece is needed, a least squares
%   polynomial fit is applied.  A higher value implies fewer pieces, and
%   therefore a smoother spline fit.
%   REMOVE_INVALID - TRUE if invalid vessels (i.e. those with too few
%   centre points for angle computations to work, which in this case means
%   just one point) should be removed from VESSELS, FALSE otherwise
%   (Default = TRUE).
%
% OUTPUT:
%   The same as the input VESSELS array.  It will now contain refined
%   CENTRE coordinates (dependent upon the spline fit) and the ANGLES
%   property, which gives unit vectors perpendicular to the
%   spline fit at the corresponding coordinate stored in the output CENTRE
%   (i.e. it gives the angle of the line through which the image profiles
%   should be computed).  However, note that some vessels might have been
%   removed if REMOVE_INVALID is TRUE.
%
%
% Copyright © 2011 Peter Bankhead.
% See the file : Copyright.m for further details.


% See later comment around the call to SPLINE to see why these lines might
% be useful
% mmdflag = spparms('autommd');
% spparms('autremove_invalidommd',0);

if nargin < 3 || ~islogical(remove_invalid)
    remove_invalid = true;
end

% May need to delete some vessels
remove_inds = false(size(vessels));

% Fit splines to each vessel
for ii = 1:numel(vessels)
    % Get centre points
    c_points = vessels(ii).centre;
    if isempty(c_points) || size(c_points, 1) < 2
        remove_inds(ii) = true;
        continue;
    end
    
    % NOTE: In the following, Y is Nx2 and X is Nx1 - that is, the original
    % coordinates are stored within Y, and X is a newly-introduced
    % parameter based upon the distance between them.  Spline fits are
    % applied to each column of Y (i.e. each coordinate) independently of
    % one another, but reliant upon X.  In other words, it is like
    % calculating a 1D spline fit between X and Y(:,1), and another between
    % X and Y(:,2), then evaluating both of these again to get the smoothed
    % coordinates.
    y = c_points;
    
    % Calculate offsets along centre line using Euclidean distances
    pixel_length = [0; sqrt(sum((diff(c_points, [], 1).^2).'))'];
    
    % Use Lee's centripedal scheme described in 'Choosing nodes in
    % parametric curve interpolation' to parameterize.  The square root
    % works considerably better than just using the Euclidean distance
    % alone.
    x = cumsum(sqrt(pixel_length));

    % Calculate number of least squares spline pieces
    n_pieces = round(sum(pixel_length) / piece_spacing);
    if n_pieces < 1
        n_pieces = 1;
    end
    
    % Assign X_EVAL to use integer values when evaluating
    x_eval = (0:floor(max(x)))';

    % If there is only 1 piece, do a least squares polynomial fit - which
    % should be considerably faster, and can occur frequently enough to be
    % worthwhile
    if n_pieces == 1
        % Polynomial degree (cubic if enough data points)
        deg = min(3, numel(x)-1);
        % Construct Vandermonde matrices
        V = ones(numel(x), deg+1);
        V_eval = ones(numel(x_eval), deg+1);
        for jj = deg:-1:1
            V(:,jj) = x.*V(:,jj+1);
            V_eval(:,jj) = x_eval.*V_eval(:,jj+1);
        end
        % Do fit to get polynomial coefficients - each column gives the
        % coefficients of a polynomial
        p = V \ y;
        % Evaluate polynomial for centre line
        cent = p' * V_eval';
        % Compute polynomial derivate
        pd = bsxfun(@times, p(1:end-1, :), (deg:-1:1)');
        % Evaluate derivatives
        der = pd' * V_eval(:, 2:end)';
        
        % Note: This code does the same, but more slowly
%         p1 = polyfit(x, y(:,1), 2);
%         p2 = polyfit(x, y(:,2), 2);
%         cent = [polyval(p1, x_eval), polyval(p2, x_eval)];
%         pd1 = polyder(p1);
%         pd2 = polyder(p2);
%         der = [polyval(pd1, x_eval), polyval(pd2, x_eval)];
    else
        % Do the least squares spline fit.
        % Using the spline toolbox, it's possible to change the spline
        % order and provide a bit more control of the output.  But the
        % dependency on having the additional toolbox is undesireable and,
        % at least as of R2009b, the spline toolbox is considerably slower
        % (due in part to frequent use of string comparisons for input
        % checking, and REPMAT rather than BSXFUN).
        % So use instead the built-in SPLINE functions of MATLAB.
        % Still, the explanation for the following code is given in the
        % spline toolbox documentation, under the title
        %   'Least-Squares Approximation by "Natural" Cubic Splines'
        
        % Determine breaks
        b = linspace(x(1), x(end), n_pieces+1);
        
        % Create spline - calls to SPPARMS make the original SPLINE
        % function slow within loops.  A way to speed that up would be to
        % disable those calls in a custom SPLINE implementation, and
        % possibly to set SPPARMS before and after the loop.  Nevertheless,
        % here we accept the increase in computation time (which may only
        % be a few tens or hundredths of a second) and just use SPLINE as
        % it is.
        pp = spline(b, y'/spline(b, eye(length(b)), x(:)'));
        
        % Evaluate the spline for the centre line
        cent = ppval(pp, x_eval);
        % Compute spline derivative
        pd = pp;
        pd.order = pp.order - 1;
        pd.coefs = bsxfun(@times, pd.coefs(:, 1:3), [3, 2, 1]);
        % Evaluate the derivative
        der = ppval(pd, x_eval);
        
        % Alternative SPLINE TOOLBOX code (uses quadratic splines and
        % gives different results, with output in B-form)
%         % Calculate quadratic least squares spline approximation
%         spl = spap2(n_pieces, 3, x, y');
%         % Calculate angles along spline
%         der = fnval(fnder(spl), x_eval);
%         % Calculate centre line values
%         cent = fnval(spl, x_eval)';
    end

    % Store centre line values
    vessels(ii).centre = cent';

    % Convert derivative values to unit tangents at each point
    normals = [0 1; -1 0] * der;
    normals = normalize_vectors(normals);
    vessels(ii).angles = normals';
end


% Remove any vessels if the centreline couldn't be fixed (too few points)
if remove_invalid && any(remove_inds)
    vessels(remove_inds) = [];
end


% Reset SPPARMS
% spparms('autommd',mmdflag);


%--------------------------------------------------



% v is a 2 * n array containing n 2-dimensional vectors
% u is a 2 * n array containing n 2-dimensional unit vectors
function u = normalize_vectors(v)
u = bsxfun(@rdivide, v, hypot(v(1,:), v(2,:)));