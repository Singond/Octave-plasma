## -*- texinfo -*-
## @deftypefn  {} {} plot_prefit_voigt (@var{x}, @var{y}, @var{fit})
## @deftypefnx {} {} plot_prefit_voigt (@dots{}, @var{style})
##
## Plot the preliminary fit of @code{log(@var{y})} produced
## by @code{fit_voigt}.
##
## Note: This function was used mainly when debugging @code{fit_voigt},
## but has been included for future reference.
##
## @seealso{voigt, fit_voigt, plot_fit_voigt}
## @end deftypefn
function plot_prefit_voigt(x, y, fit, style="d")
	m = fit.prefit.xmin <= x & x <= fit.prefit.xmax;
	x = x(m);
	y = y(m) - fit.prefit.y0;
	[xmin, xmax] = bounds(x(:));
	xx = linspace(xmin, xmax);

	if (ishold)
		coi = get(gca, "colororderindex");
	else
		coi = 1;
	end
	color = get(gca, "colororder")(coi,:);

	plot(x, log(y), style, "color", color,
		xx, polyval(fit.prefit.p, xx), "b:", "color", color);
end
