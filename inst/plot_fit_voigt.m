## -*- texinfo -*-
## @deftypefn  {} {} plot_fit_voigt (@var{x}, @var{y}, @var{fit})
## @deftypefnx {} {} plot_fit_voigt (@dots{}, @var{plotparams})
##
## Plot the fit produced by @code{fit_voigt}.
##
## Plot style of the raw data can be changed by additional arguments,
## which are passed directly to @code{plot}.
## Note that color specifiers in format arguments will be ignored.
##
## @seealso{voigt, fit_voigt, plot}
## @end deftypefn
function plot_fit_voigt(x, y, fit, varargin)
	[xmin, xmax] = bounds(x(:));
	xx = linspace(xmin, xmax, 500);
	xprefit = xx(fit.prefit.xmin < xx & xx < fit.prefit.xmax);

	if (ishold)
		coi = get(gca, "colororderindex");
	else
		coi = 1;
	end
	color = get(gca, "colororder")(coi,:);

	plot(x, y, "color", color, varargin{:},
		xprefit, fit.prefit.f(xprefit),...
			"b:", "color", color, "handlevisibility", "off",
		xx, fit.f(xx),...
			"b--", "color", color, "handlevisibility", "off");
end
