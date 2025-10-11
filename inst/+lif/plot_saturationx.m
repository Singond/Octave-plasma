## -*- texinfo -*-
## @deftypefn  {} {} lif.plot_saturationx (@var{s})
## @deftypefnx {} {} lif.plot_saturationx (@var{s}, @var{param}, @var{value}, @dots{})
## @deftypefnx {} {[@var{f1}, @var{f2}] =} lif.plot_saturationx (@dots{})
##
## Plot x-resolved saturation data given in struct @var{s} and allow
## inspection of the underlying fits.
##
## The struct @var{s} must be similar in structure to the return value
## of @code{lif.saturationx}.
## In particular, it must contain the field @code{bx}, which is the
## saturation parameter to be plotted, and @code{fitsx}, which must be a struct
## array of the same size as @code{bx} and must be in the form returned
## by @code{fit_fluorescence_int}.
## The field @code{xpos} must also be given.
##
## The main plot allows inspection of the fit leading to the value
## of @code{bx} at each pixel.
## Clicking the "Inspect fit" button and then clicking anywhere into the
## saturation plot will open an additional plot with individual data points
## and the fitted curve which produced the value at the clicked pixel.
## These data are taken from the fields @code{E} and @code{imgsmx} of @var{s},
## which must also be present if inspection is to work.
##
## Following additional parameters @var{param} are supported:
##
## @table @code
## @item range
## The display range of the main plot (the range of the colorbar).
## This is a two-element vector giving the minimum and maximum of @code{b}
## to be displayed. Values outside this range are clipped.
## If empty (the default), the range is computed automatically as the
## minimum and maximum value.
##
## @item fitlabel
## A label used to identify the clicked point in the fit inspection plot.
## This is a pattern evaluated using @code{sprintf} with three parameters:
## the values of @code{xpos}, @code{ax} and @code{bx} at that point.
## @end table
##
## The return values are figure handles to the resulting plots,
## namely the main plot (@var{f1}),
## and the fit inspection plot (@var{f2}).
##
## @seealso{lif.saturationx, lif.plot_saturation}
## @end deftypefn
function [fig_b, fig_fit] = plot_saturationx(s, varargin)
	p = inputParser;
	p.addParameter("range", []);
	p.addParameter("fitlabel", "[%d] \\alpha = %g, \\beta = %g");
	p.parse(varargin{:});

	## Setup figure, using current figure if one exists
	fig_b = gcf;
	clf(fig_b);

	## Draw the plot
	[ax, h1, h2] = plotyy(s.xpos, s.ax, s.xpos, s.bx,
		@(x, y) plot(x, y, "s",
			"displayname", "intensity parameter \\alpha"),
		@(x, y) plot(x, y, "o",
			"displayname", "saturation parameter \\beta"));
	legend;
	xlim([min(s.xpos) max(s.xpos)]);
	if (!isempty(p.Results.range))
		ylim(p.Results.range);
	end
	ylabel(ax(1), "intensity parameter \\alpha");
	ylabel(ax(2), "saturation parameter \\beta");

	## Initialize new figure for fit inspection
	fig_fit = figure("visible", "off");

	## Add controls for fit inspection
	opts.fitlabel = p.Results.fitlabel;
	figure(fig_b);
	uicontrol("parent", fig_b,
		"string", "Inspect fit",
		"position", [10 10 120 30],
		"callback", @(a,b) inspect_fit(s, s.fitsx, fig_b, fig_fit, opts));
	uicontrol("parent", fig_b,
		"string", "Clear fits",
		"position", [140 10 120 30],
		"callback", @(a,b) clf(fig_fit));
end

function inspect_fit(s, fits, f1, f2, opts)
	figure(f1);
	[x, y, btn] = ginput(1);
	x = round(x);
	xr = x - min(s.xpos) + 1;

	if (x > max(s.xpos(:)) || x < min(s.xpos(:)))
		return;
	end

	figure(f2, "name", "Fit detail", "visible", "on");
	hold on;
	cidx = get(gca(), "colororderindex");
	plotcolor = get(gca(), "colororder")(cidx,:);
	plot(s.E, s.imgsmx(1,xr,:)(:), "d",
		"color", plotcolor,
		"displayname", sprintf(opts.fitlabel, x, s.ax(xr), s.bx(xr)));
	[Emin, Emax] = bounds(s.E);
	E0 = linspace(0, Emin);
	EE = linspace(Emin, Emax);
	plot(E0, fits(xr).fite.f(E0), ":",
		"color", plotcolor, "handlevisibility", "off");
	plot(EE, fits(xr).fite.f(EE), "--",
		"color", plotcolor, "handlevisibility", "off");
	legend show;
	hold off;
	legend show;
end
