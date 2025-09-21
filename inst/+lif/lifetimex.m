## -*- texinfo -*-
## @deftypefn  {} {@var{R} =} lif.lifetimex (@var{S})
## @deftypefnx {} {@var{R} =} lif.lifetimex (@var{S}, @var{opts})
##
## Calculate the lifetime of exponential decay in each column of a series
## of images @code{@var{S}.imgn} taken at times @code{@var{S}.t}.
##
## Sum @code{@var{S}.imgn} in vertical direction and fit the decay
## to this sum.
## This is like @code{lif.lifetime}, but instead of fitting each pixel
## separately, only the sum in each column is fitted.
## This leads to faster computation and possibly more reliable fits due to
## better signal-to-noise ratio, at the cost of losing the resolution
## in y-direction.
##
## Return a copy of struct @var{S} with the following fields added:
##
## @table @code
## @item imgnx
## Sum of @code{@var{S}.imgn} along columns.
## This is the data to be fitted.
##
## @item taux
## The lifetime at each column.
## This is an array with size of @code{[1, columns(@var{S}.imgn)]}.
##
## @item tausigx
## The uncertainty of @code{taux}.
##
## @item fitsx
## Information about the fits in the same form as in @code{fit_decay}.
##
## @item imgsmx
## Image @code{@var{S}.imgn} smoothed by the @qcode{"smooth"} parameter.
## @end table
##
## Additional input arguments @var{opts} are passed into @code{lifetime}.
##
## @seealso{lifetime, fit_decay}
## @end deftypefn
function result = lifetimex(S, varargin)
	if (!isstruct(S))
		print_usage;
		return;
	end

	result = struct([]);
	for s = S
		s.imgnx = sum(s.imgn, 1);
		printf("Fitting lifetime to %s (x-resolved)\n", s.name);
		[s.taux, s.tausigx, s.fitsx, s.imgsmx] = lifetime(
			s.imgnx, s.t, 3, "limits", s.fitlim, varargin{:});
		if (isfield(s, "info") && iscell(s.info))
			s.info{end+1,1} = sprintf(
				"Fitted lifetime to each column in range [%g, %g] of t",
				s.fitlim);
		end
		result(end+1) = s;
	end
end

