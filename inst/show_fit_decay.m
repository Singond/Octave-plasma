## -*- texinfo -*-
## @deftypefn  {} {} show_fit_decay (@var{s}, @var{fit}, @var{r}, @var{c})
## @deftypefnx {} {} show_fit_decay (@dots{}, @code{@{"fitl", @dots{}@}})
##
## Inspect the fit produced by @code{fit_decay}.
##
## The optional cell array argument selects which fits in @var{fit}
## will be plotted. The default is to plot all fits.
## @end deftypefn
function show_fit_decay(s, fit, r, c, fields={})
	if (isempty(fields))
		fields = {"fitl", "fitb", "fite"};
	end
	x = s.t;
	y = s.in(r,c,:);

	[xmin, xmax] = bounds(x);
	[ymin, ymax] = bounds(y);

	xx = linspace(xmin, xmax);
	yl = yb = ye = [];
	if (any(strcmp(fields, "fitl")))
		yl = fit(r,c).fitl.f(xx);    # linear fit in log scale
	end
	if (any(strcmp(fields, "fitb")))
		yb = fit(r,c).fitb.f(xx);    # exponential fit with y-constant
	end
	if (any(strcmp(fields, "fite")))
		ye = fit(r,c).fite.f(xx);    # exponential fit
	end
	taue = fit(r,c).fite.tau;

	## Limit fitted functions to similar y-range as data
	if (strcmp(get(gca, "yscale"), "log"))
		ymin = min(y(y > 0));
		ml = (ymin * 0.1) < yl & yl < (ymax * 10);
		mb = (ymin * 0.1) < yb & yb < (ymax * 10);
		me = (ymin * 0.1) < ye & ye < (ymax * 10);
	else
		yrange = ymax - ymin;
		ml = (ymin - 0.1 * yrange) < yl & yl < (ymax + 0.1 * yrange);
		mb = (ymin - 0.1 * yrange) < yb & yb < (ymax + 0.1 * yrange);
		me = (ymin - 0.1 * yrange) < ye & ye < (ymax + 0.1 * yrange);
	end

	cidx = get(gca(), "colororderindex");
	cc = get(gca(), "colororder")(cidx,:);
	xscale = 1;
	plot(
		x * xscale, y, "d",
			"color", cc, "displayname",
			sprintf("[%d, %d] \\tau_e = %.3f ns", r, c, taue * xscale),
		xx(ml) * xscale, yl(ml),
			"b:", "color", cc, "handlevisibility", "off",
		xx(mb) * xscale, yb(mb),
			"b-.", "color", cc, "handlevisibility", "off",
		xx(me) * xscale, ye(me),
			"b--", "color", cc, "handlevisibility", "off");
	xlabel("time t [ns]");
	ylabel("inensity I [a.u.]");

	hleg = legend;
	set(hleg, "interpreter", "tex");
	## Compatibility hack for older Octave versions (tested on 5.2.0):
	## Set location and orientation explicitly to "default" to force
	## an update of the legend from current "displayname" properties.
	## This is not necessary in newer versions, where the legend is
	## updated automatically.
	if (compare_versions(version, "5.2.0", "<="))
		legend("location", "default", "orientation", "default");
	end
end
