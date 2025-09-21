## -*- texinfo -*-
## @deftypefn  {} {@var{R} =} lif.lifetime (@var{S})
## @deftypefnx {} {@var{R} =} lif.lifetime (@var{S}, @var{opts})
##
## Calculate the lifetime of exponential decay in each pixel of a series
## of images @code{@var{S}.imgn} taken at times @code{@var{S}.t}.
##
## Return a copy of struct @var{S} with the following fields added:
##
## @table @code
## @item tau
## The lifetime at each pixel. This is an array with the size of the
## first two dimensions of @code{@var{S}.imgn}.
##
## @item tausig
## The uncertainty of @code{tau}.
##
## @item fits
## Information about the fits in the same form as in @code{fit_decay}.
##
## @item imgsm
## Image @code{@var{S}.imgn} smoothed by the @qcode{"smooth"} parameter.
## @end table
##
## Additional input arguments @var{opts} are passed into @code{lifetime}.
##
## @seealso{lifetime, fit_decay}
## @end deftypefn
function result = lifetime(S, varargin)
	if (!isstruct(S))
		print_usage;
		return;
	end

	result = struct([]);
	for s = S
		printf("Fitting lifetime to %s\n", s.name);
		[s.tau, s.tausig, s.fits, s.imgsm] = lifetime(
			s.imgn, s.t, 3, "limits", s.fitlim, varargin{:});
		if (isfield(s, "info") && iscell(s.info))
			s.info{end+1,1} = sprintf(
				"Fitted lifetime to each pixel in range [%g, %g] of t",
				s.fitlim);
		end
		result(end+1) = s;
	end
end
