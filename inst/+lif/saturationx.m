## -*- texinfo -*-
## @deftypefn  {} {@var{R} =} lif.saturationx (@var{S})
## @deftypefnx {} {@var{R} =} lif.saturationx (@var{S}, @var{opts})
##
## Calculate the parameters of saturated fluorescence in each column
## of a series of images @code{@var{S}.imgn} taken at laser energies
## @code{@var{S}.E}.
##
## Sum @code{@var{S}.imgn} in vertical direction and work on this sum.
## This is like @code{lif.saturation}, but instead of fitting each pixel
## separately, only the sum in each column is fitted.
## This leads to faster computation and possibly more reliable fits due to
## better signal-to-noise ratio, at the cost of losing the resolution
## in y-direction.
##
## Return a copy of struct @var{S} with the following fields added:
##
## @table @code
## @item  ax
## @itemx bx
## The fluorescence parameters @var{a} and @var{b} at each pixel.
## Each of these is an array with the size equal to the first two
## dimensions of @code{@var{S}.imgn}.
##
## @item fitsx
## Information about the fits in the same form as in
## @code{fit_fluorescence_int}.
##
## @item imgsmx
## Image @code{@var{S}.imgn} smoothed by the @qcode{"smooth"} parameter.
## @end table
##
## Additional input arguments @var{opts} are passed directly into
## @code{lif.fit_fluorescence_int}.
##
## @seealso{lif.fit_fluorescence_int, lif.saturation}
## @end deftypefn
function result = saturationx(S, varargin)
	if (!isstruct(S))
		print_usage;
		return;
	end

	result = struct([]);
	for s = S
		printf("Fitting saturation to %s (x-resolved)\n", s.name);
		s.imgnx = sum(s.imgn, 1);
		[s.ax, s.bx, s.fitsx, s.imgsmx] = lif.fit_fluorescence_int(
			reshape(s.E, 1, 1, []), s.imgnx, 3, varargin{:});
		if (isfield(s, "info") && iscell(s.info))
			s.info{end+1,1} = "Fitted saturation to each column";
		end
		result(end+1) = s;
	end
end
