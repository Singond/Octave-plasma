## -*- texinfo -*-
## @deftypefn  {} {@var{R} =} lif.saturation (@var{S})
## @deftypefnx {} {@var{R} =} lif.saturation (@var{S}, @var{opts})
##
## Calculate the parameters of saturated fluorescence in each pixel
## of a series of images @code{@var{S}.imgn} taken at laser energies
## @code{@var{S}.E}.
##
## Return a copy of struct @var{S} with the following fields added:
##
## @table @code
## @item  a
## @itemx b
## The fluorescence parameters @var{a} and @var{b} at each pixel.
## Each of these is an array with the size equal to the first two
## dimensions of @code{@var{S}.imgn}.
##
## @item fits
## Information about the fits in the same form as in
## @code{fit_fluorescence_int}.
##
## @item imgsm
## Image @code{@var{S}.imgn} smoothed by the @qcode{"smooth"} parameter.
## @end table
##
## Additional input arguments @var{opts} are passed directly into
## @code{lif.fit_fluorescence_int}.
##
## @seealso{lif.fit_fluorescence_int, lif.saturationx}
## @end deftypefn
function result = saturation(S, varargin)
	if (!isstruct(S))
		print_usage;
		return;
	end

	result = struct([]);
	for s = S
		printf("Fitting saturation to %s\n", s.name);
		[s.a, s.b, s.fits, s.imgsm] = lif.fit_fluorescence_int(
			reshape(s.E, 1, 1, []), s.imgn, 3, varargin{:});
		if (isfield(s, "info") && iscell(s.info))
			s.info{end+1,1} = "Fitted saturation to each pixel";
		end
		result(end+1) = s;
	end
end
