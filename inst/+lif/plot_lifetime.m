## -*- texinfo -*-
## @deftypefn  {} {} lif.plot_lifetime (@var{s})
## @deftypefnx {} {} lif.plot_lifetime (@var{s}, @var{param}, @var{value}, @dots{})
## @deftypefnx {} {[@var{f1}, @var{f2}, @var{f3}] =} lif.plot_lifetime (@dots{})
##
## Plot 2D lifetime data given in struct @var{s} as image and allow inspection
## of the underlying fits.
##
## The struct @var{s} must be similar in structure to the return value
## of @code{lif.lifetime}.
## In particular, it must contain the field @code{tau}, which is the
## lifetime data to be plotted, and @code{fits}, which must be a struct
## array of the same size as @code{tau} and must be in the form returned
## by @code{fit_decay}.
## The fields @code{xpos} and @code{ypos} must also be given.
##
## The main plot allows inspection of the fit leading to the value
## of @code{tau} at each pixel.
## Clicking the "Inspect fit" button and then clicking anywhere into the
## lifetime plot will open two additional plots with individual data points
## and the fitted curve which produced the value at the clicked pixel.
## These data are taken from the fields @code{t} and @code{imgsm} of @var{s},
## which must also be present if inspection is to work.
##
## Following additional parameters @var{param} are supported:
##
## @table @code
## @item taurange
## The display range of the main plot (the range of the colorbar).
## This is a two-element vector giving the minimum and maximum of @code{tau}
## to be displayed. Values outside this range are clipped.
## If empty (the default), the range is computed automatically as the
## minimum and maximum value.
##
## @item colormap
## The colormap used by the image.
## @end table
##
## The return values are figure handles to the resulting plots,
## namely the main plot (@var{f1}),
## the fit inspection plot in linear scale (@var{f2})
## and the same fit in semilogarithmic scale (@var{f3}).
##
## @seealso{lif.lifetime, lif.plot_lifetimex}
## @end deftypefn
function [f1, f2, f3] = plot_lifetime(s, varargin)
	p = inputParser;
	p.addParameter("taurange", []);
	p.addParameter("colormap", []);
	p.parse(varargin{:});

	warning("off", "Octave:negative-data-log-axis", "local");
	warning("off", "Octave:imshow-NaN", "local");

	## Setup figure, using current figure if one exists
	f1 = gcf;
	clf(f1);

	## Clean up data
	tau = s.tau;
	tau(tau <= 0) = NaN;

	## Resolve colormap. This has to be done lazily, after figure creation,
	## to avoid creating an extra figure.
	cmap = p.Results.colormap;
	if (isempty(cmap))
		cmap = colormap();
	end

	## Draw the lifetime plot
	ax = axes("position", [0.1 0.2 0.8 0.65]);
	axes(ax);
	imshow(tau,
		"xdata", s.xpos, "ydata", s.ypos,
		"displayrange", p.Results.taurange,
		"colormap", cmap);
	axis on;
	set(ax, "ticklength", [0 0])
	grid off;
	cb = colorbar("SouthOutside");

	## Initialize new figures for fit inspection
	f2 = figure("visible", "off");
	f3 = figure("visible", "off");

	## Add controls for fit inspection
	figure(f1);
	uicontrol("parent", f1,
		"string", "Inspect fit",
		"position", [10 10 120 30],
		"callback", @(a,b) inspect_fit(s, s.fits, f1, f2, f3));
	uicontrol("parent", f1,
		"string", "Clear fits",
		"position", [140 10 120 30],
		"callback", @(a,b) arrayfun(@clf, [f2 f3]));
end

function inspect_fit(s, fits, f1, f2, f3)
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
	plot_fit_decay(s.t, s.imgsm, fits, "idx", {yr, xr}, "dim", 3,
		"label", sprintf("[%d,%d] \\tau = %g ns", x, y, s.tau(yr,xr)));
	legend show;
	hold off;

	figure(f3, "name", "Fit detail (log)", "visible", "on");
	set(gca, "yscale", "log");
	hold on;
	plot_fit_decay(s.t, s.imgsm, fits, "idx", {yr, xr}, "dim", 3,
		"label", sprintf("[%d,%d] \\tau = %g ns", x, y, s.tau(yr,xr)));
	legend show;
	hold off;
end
