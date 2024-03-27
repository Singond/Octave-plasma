## -*- texinfo -*-
## @deftypefn  {} {} plot_fit_voigt (@var{x}, @var{y}, @var{fit})
## @deftypefnx {} {} plot_fit_voigt (@dots{}, @var{style})
##
## Plot the fit produced by @code{fit_voigt}.
##
## Plot style of the raw data can be changed by the @var{style}
## parameter, which must be a format argument understood by @code{plot}.
## Note that any color specifier will be ignored.
##
## @seealso{voigt, fit_voigt, plot}
## @end deftypefn
function plot_fit_voigt(x, y, fit, style="-")
	[xmin, xmax] = bounds(x(:));
	xx = linspace(xmin, xmax, 500);
	xprefit = xx(fit.prefit.xmin < xx & xx < fit.prefit.xmax);

	if (ishold)
		coi = get(gca, "colororderindex");
	else
		coi = 1;
	end
	color = get(gca, "colororder")(coi,:);

	plot(x, y, style, "color", color,
		xprefit, fit.prefit.f(xprefit), "b:", "color", color,
		xx, fit.f(xx), "b--", "color", color);
end
