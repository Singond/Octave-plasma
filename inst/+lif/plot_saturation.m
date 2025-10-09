## -*- texinfo -*-
## @deftypefn  {} {} lif.plot_saturation (@var{s})
## @deftypefnx {} {} lif.plot_saturation (@var{s}, @var{param}, @var{value}, @dots{})
## @deftypefnx {} {[@var{f1}, @var{f2}] =} lif.plot_saturation (@dots{})
##
## Plot 2D saturation data given in struct @var{s} as image and allow
## inspection of the underlying fits.
##
## The struct @var{s} must be similar in structure to the return value
## of @code{lif.saturation}.
## In particular, it must contain the field @code{b}, which is the
## saturation parameter to be plotted, and @code{fits}, which must be a struct
## array of the same size as @code{b} and must be in the form returned
## by @code{fit_fluorescence_int}.
## The fields @code{xpos} and @code{ypos} must also be given.
##
## The main plot allows inspection of the fit leading to the value
## of @code{b} at each pixel.
## Clicking the "Inspect fit" button and then clicking anywhere into the
## saturation plot will open an additional plot with individual data points
## and the fitted curve which produced the value at the clicked pixel.
## These data are taken from the fields @code{E} and @code{imgsm} of @var{s},
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
## @item colormap
## The colormap used by the image.
##
## @item fitlabel
## A label used to identify the clicked point in the fit inspection plot.
## This is a pattern evaluated using @code{sprintf} with four parameters:
## the values of @code{xpos}, @code{ypos}, @code{a} and @code{b} at that point.
## @end table
##
## The return values are figure handles to the resulting plots,
## namely the main plot (@var{f1}),
## and the fit inspection plot (@var{f2}).
##
## @seealso{lif.saturation}
## @end deftypefn
function [f1, f2] = plot_saturation(s, varargin)
	p = inputParser;
	p.addParameter("range", []);
	p.addParameter("colormap", []);
	p.addParameter("fitlabel", "[%d,%d] \\alpha = %g, \\beta = %g");
	p.parse(varargin{:});

	## Setup figure, using current figure if one exists
	f1 = gcf;
	clf(f1);

	## Clean up data
	b = s.b;
	b(b <= 0) = NaN;

	## Resolve colormap. This has to be done lazily, after figure creation,
	## to avoid creating an extra figure.
	cmap = p.Results.colormap;
	if (isempty(cmap))
		cmap = colormap();
	end

	## Draw the saturation plot
	ax = axes("position", [0.1 0.2 0.8 0.65]);
	axes(ax);
	imshow(b,
		"xdata", s.xpos, "ydata", s.ypos,
		"displayrange", p.Results.range,
		"colormap", cmap);
	axis on;
	set(ax, "ticklength", [0 0])
	grid off;
	cb = colorbar("SouthOutside");

	## Initialize new figure for fit inspection
	f2 = figure("visible", "off");

	## Add controls for fit inspection
	figure(f1);
	opts.fitlabel = p.Results.fitlabel;
	uicontrol("parent", f1,
		"string", "Inspect fit",
		"position", [10 10 120 30],
		"callback", @(a,b) inspect_fit(s, s.fits, f1, f2, opts));
	uicontrol("parent", f1,
		"string", "Clear fits",
		"position", [140 10 120 30],
		"callback", @(a,b) arrayfun(@clf, [f2]));
end

function inspect_fit(s, fits, f1, f2, opts)
	figure(f1);
	[x, y, btn] = ginput(1);
	x = round(x);
	y = round(y);
	xr = x - min(s.xpos) + 1;
	yr = y - min(s.ypos) + 1;

	if (yr > length(s.ypos) || yr < 1 ...
		|| xr > length(s.xpos) || xr < 1)
		return;
	end

	figure(f2, "name", "Fit detail", "visible", "on");
	hold on;
	cidx = get(gca(), "colororderindex");
	plotcolor = get(gca(), "colororder")(cidx,:);
	plot(s.E, s.imgsm(yr, xr, :)(:), "d",
		"color", plotcolor,
		"displayname", sprintf(opts.fitlabel, x, y, s.a(yr,xr), s.b(yr,xr)));
	[Emin, Emax] = bounds(s.E);
	E0 = linspace(0, Emin);
	EE = linspace(Emin, Emax);
	plot(E0, fits(yr,xr).fite.f(E0), ":",
		"color", plotcolor, "handlevisibility", "off");
	plot(EE, fits(yr,xr).fite.f(EE), "--",
		"color", plotcolor, "handlevisibility", "off");
	legend show;
	hold off;
end
