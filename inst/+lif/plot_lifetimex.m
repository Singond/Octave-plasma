## -*- texinfo -*-
## @deftypefn  {} {} lif.plot_lifetimex (@var{s})
## @deftypefnx {} {} lif.plot_lifetimex (@var{s}, @var{param}, @var{value}, @dots{})
## @deftypefnx {} {[@var{f1}, @var{f2}, @var{f3}] =} lif.plot_lifetimex (@dots{})
##
## Plot x-resolved lifetime data given in struct @var{s} and allow
## inspection of the underlying fits.
##
## The struct @var{s} must be similar in structure to the return value
## of @code{lif.lifetimex}.
## In particular, it must contain the field @code{taux}, which is the
## lifetime data to be plotted, and @code{fitsx}, which must be a struct
## array of the same size as @code{taux} and must be in the form returned
## by @code{fit_decay}.
## The field @code{xpos} must also be given.
##
## The main plot allows inspection of the fit leading to the value
## of @code{taux} at each pixel.
## Clicking the "Inspect fit" button and then clicking anywhere into the
## lifetime plot will open two additional plots with individual data points
## and the fitted curve which produced the value at the clicked pixel.
## These data are taken from the fields @code{t} and @code{imgnx} of @var{s},
## which must also be present if inspection is to work.
##
## Following additional parameter @var{param} is supported:
##
## @table @code
## @item taurange
## The display range of the main plot (the range of the colorbar).
## This is a two-element vector giving the minimum and maximum of @code{tau}
## to be displayed. Values outside this range are clipped.
## If empty (the default), the range is computed automatically as the
## minimum and maximum value.
## @end table
##
## The return values are figure handles to the resulting plots,
## namely the main plot (@var{f1}),
## the fit inspection plot in linear scale (@var{f2})
## and the same fit in semilogarithmic scale (@var{f3}).
##
## @seealso{lif.lifetimex, lif.plot_lifetime}
## @end deftypefn
function [fig_tau, fig_fit, fig_logfit] = plot_lifetimex(s, varargin)
	p = inputParser;
	p.addParameter("taurange", []);
	p.parse(varargin{:});

	warning("off", "Octave:negative-data-log-axis", "local");
	warning("off", "Octave:imshow-NaN", "local");

	## Setup figure, using current figure if one exists
	fig_tau = gcf;
	clf(fig_tau);

	## Clean up data
	tau = s.taux;
	tau(tau <= 0) = NaN;

	## Draw the plot
	errorbar(s.xpos, s.taux, s.tausigx, "d");
	xlim([min(s.xpos) max(s.xpos)]);
	if (!isempty(p.Results.taurange))
		ylim(p.Results.taurange);
	end

	## Initialize new figures for fit inspection
	fig_fit = figure("visible", "off");
	add_toggle_logy(fig_fit, gca);

	## Add controls for fit inspection
	figure(fig_tau);
	uicontrol("parent", fig_tau,
		"string", "Inspect fit",
		"position", [10 10 120 30],
		"callback", @(a,b) inspect_fit(s, s.fitsx, fig_tau, fig_fit));
	uicontrol("parent", fig_tau,
		"string", "Clear fits",
		"position", [140 10 120 30],
		"callback", @(a,b) clf(fig_fit));
end

function inspect_fit(s, fits, f1, f2, f3)
	figure(f1);
	[x, y, btn] = ginput(1);
	x = round(x);
	xr = x - min(s.xpos) + 1;

	if (x > max(s.xpos(:)) || x < min(s.xpos(:)))
		return;
	end

	fignew = !isfigure(f2);
	figure(f2, "name", "Fit detail", "visible", "on");
	hold on;
	plot_fit_decay(s.t, s.imgnx, fits, "dim", 3, "idx", {1, xr},
##		"only", {"fite"},
		"label", sprintf("[%d] \\tau = %g ns", x, s.taux(1,xr)));
	hold off;
	legend show;
	if (fignew)
		add_toggle_logy(f2, gca);
	end
end

function toggle_logy(h, evt, ax)
	if (get(h, "value"))
		set(ax, "yscale", "log");
	else
		set(ax, "yscale", "linear");
	end
end

function add_toggle_logy(f, ax)
	uicontrol("parent", f,
		"style", "togglebutton",
		"string", "Log scale",
		"position", [10 10 120 30],
		"callback", {@toggle_logy, ax});
end
