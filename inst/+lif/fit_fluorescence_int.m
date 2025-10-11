## -*- texinfo -*-
## @deftypefn  {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int @
##   (@var{L}, @var{F})
## @deftypefnx {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int @
##   (@var{L}, @var{F}, @var{dim})
## @deftypefnx {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int @
##   (@dots{}, @qcode{"geometry"}, @var{GEOM})
## @deftypefnx {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int @
##   (@dots{}, @qcode{"smooth"}, @var{kernel})
## @deftypefnx {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int @
##   (@dots{}, @qcode{"progress"})
## @deftypefnx {} {[@var{a}, @var{b}, @var{fit}, @var{Fmod}] =} @
##   lif.fit_fluorescence_int_planar (@dots{})
##
## Fit spatially integrated fluorescence to data.
##
## Fit a function describing the fluorescence induced by a laser beam
## to data points @var{F} detected at laser energies @var{L}.
## The precise form of this function depends on the assumed geometry
## of the laser beam, but in general the function describes
## the fluorescence signal that would be detected by a sensor
## looking perpendicularly from the side of the beam,
## assuming a homogeneous medium and accounting for saturation effects.
## The signal depends on two additional parameters @var{a} and @var{b},
## which are the parameters being optimized.
##
## By default, assume that the laser beam is a planar sheet.
## This can be changed by the parameter @qcode{"geometry"}.
## Valid value is @qcode{"planar"} (the default).
##
## With matrix argument @var{F} (and possibly @var{L}), fit the function
## to each column. If the optional argument @var{dim} is given,
## fit to each vector in that dimension.
##
## If the optional parameter @qcode{"smooth"} is given, first smooth
## the data @var{F} by convolution with the given @var{kernel}.
## The sum of @var{kernel} need not be equal to one,
## it will be normalized automatically.
##
## The switch @qcode{"progress"} turns on printing messages with progress
## when number of series is large.
##
## Return the parameters @var{a} and @var{b} which minimize the sum
## of squared residuals
## @code{lif.fluorescence_int_*(@var{L}, @var{a}, @var{b}) - @var{F}}.
##
## The optional return value @var{fit} is a struct with additional
## information about the fit:
## Its field @code{@var{fit}.fitl} (also a struct) describes
## the preliminary polynomial fit, while @code{@var{fit}.fite}
## describes the final fit of the true function.
## In particular, @code{@var{fit}.fite.cvg} is a flag indicating
## whether the fit converged and @code{@var{fit}.fite.iter} is the number
## of iterations.
##
## The return value @var{Fmod} returns data actually used for the fit,
## that is, the argument @var{F} after the modification done by the
## @qcode{"smooth"} parameter.
##
## Internally, this is a wrapper function which delegates to other
## @code{lif.fit_fluorescence_int_*} functions based on the
## @qcode{"geometry"} parameter.
##
## @seealso{lif.fit_fluorescence_int_planar}
## @end deftypefn
function varargout = fit_fluorescence_int(varargin)
	persistent geoms = {"planar"};

	## Filter the "geometry" parameter from arguments to be passed on
	k = 0;
	args = {};
	geometry = "planar";
	while ++k <= nargin
		argk = varargin{k};
		if (strncmpi(argk, "geometry", length(argk)))
			## Remove "geometry" parameter and its value
			if (k == nargin)
				error("The 'geometry' parameter requires an argument");
			end
			geometry = validatestring(varargin{++k}, geoms);
		elseif (isstruct(argk) && isfield(argk, "geometry"))
			## Remove "geometry" field from struct
			geometry = argk.geometry;
			args {end+1} = rmfield(argk, "geometry");
		else
			args{end+1} = argk;
		end
	end

	## Call the appropriate fit function with the remaining arguments
	switch (geometry)
		case "planar"
			varargout = nthargout([1:nargout],
				@lif.fit_fluorescence_int_planar, args{:});
		otherwise
			error("Unknown geometry %s\n", geometry);
	end
end

%!shared L, y
%! a = 4;
%! b = 0.2;
%! L = (1:20)';
%! y = (2 * a / b) * (1 - log(1 + b * L) ./ (b .* L));

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int(L, y, "geometry", "planar");
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int(L, y, "geom", "plan");
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);

%!test
%! opts.geometry = "planar";
%! [af, bf, fit] = lif.fit_fluorescence_int(L, y, opts);
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);
