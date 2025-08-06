## -*- texinfo -*-
## @deftypefn  {} {} plot_fit_decay (@var{x}, @var{y}, @var{fit})
## @deftypefnx {} {} plot_fit_decay (@dots{}, @qcode{"dim"}, @var{dim})
## @deftypefnx {} {} plot_fit_decay (@dots{}, @qcode{"idx"}, @var{idx})
## @deftypefnx {} {} plot_fit_decay (@dots{}, @qcode{"only"}, @code{@{"fitl", @dots{}@}})
## @deftypefnx {} {} plot_fit_decay (@var{s}, @dots{})
##
## Plot the fit produced by @code{fit_decay}.
##
## The function accepts several optional parameters:
##
## @table @code
##
## @item dim
## The @qcode{"dim"} argument to @code{fit_decay}.
##
## @item idx
## This is a cell array of subscripts into @var{fit}.
## If given, only plot the fits given by the subscript.
##
## @item only
## This is a cell array which selects which fits in @var{fit}
## will be plotted. The default is to plot all fits.
##
## @item label
## A label of the plot in the legend.
## The value can also be a function which accepts two arguments:
## The (scalar) fit struct corresponding to the given data series,
## and a cell array of its indices in @var{fit}.
## @end table
##
## Instead of @var{x} and @var{y}, the same struct can be given
## as in the call to @code{fit_decay}.
## @end deftypefn
function plot_fit_decay(varargin)
	if (nargin == 0)
		print_usage();
	end
	k = 1;
	x = varargin{k++};
	if (isnumeric(x))
		if (k > nargin)
			print_usage();
		end
		y = varargin{k++};
	elseif (isstruct(x))
		s = x;
		x = s.t;
		y = s.in;
	else
		print_usage();
	end
	p = inputParser;
	p.addRequired("fit", @isstruct);
	p.addParameter("dim", 1, @isnumeric);
	p.addParameter("idx", {}, @iscell);
	p.addParameter("only", {"fitl", "fitb", "fite"}, @iscell);
	p.addParameter("label", "");
	p.parse(varargin{k:end});

	fit = p.Results.fit;
	dim = p.Results.dim;
	idx = p.Results.idx;
	fitidx = reshape(1:numel(fit), size(fit));

	if (!isempty(idx))
		assert(dim <= ndims(fit) + 1);
		fit = subsref(fit, substruct("()", idx));
		fitidx = subsref(fitidx, substruct("()", idx));
	end
	dims = 1:ndims(y);
	y = permute(y, [dim dims(dims != dim)]);
	y = reshape(y, length(x), []);

	fields = p.Results.only;
	label = p.Results.label;

	[xmin, xmax] = bounds(x);
	[ymin, ymax] = bounds(y(:));

	washold = ishold;
	hold on;
	for k = 1:numel(fit)
		fitk = fit(k);
		idxk = fitidx(k);
		fits = p.Results.fit;
		subsk = nthargout(1:ndims(fits), @ind2sub, size(fits), idxk);
		yk = y(:,idxk);
		xx = linspace(xmin, xmax);
		yl = yb = ye = [];
		if (any(strcmp(fields, "fitl")))
			yl = fitk.fitl.f(xx);    # linear fit in log scale
		end
		if (any(strcmp(fields, "fitb")))
			yb = fitk.fitb.f(xx);    # exponential fit with y-constant
		end
		if (any(strcmp(fields, "fite")))
			ye = fitk.fite.f(xx);    # exponential fit
		end

		## Limit fitted functions to similar y-range as data
		if (strcmp(get(gca, "yscale"), "log"))
			ymin = min(yk(yk > 0));
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

		labelargs = {};
		if (!isempty(label))
			labelk = label;
			if (is_function_handle(label))
				labelk = label(fitk, subsk);
			end
			labelargs = {"displayname", labelk};
		end
		plot(
			x * xscale, yk, "d",
				"color", cc,
				labelargs{:},
			xx(ml) * xscale, yl(ml),
				"b:", "color", cc, "handlevisibility", "off",
			xx(mb) * xscale, yb(mb),
				"b-.", "color", cc, "handlevisibility", "off",
			xx(me) * xscale, ye(me),
				"b--", "color", cc, "handlevisibility", "off");
	end
	if (!washold)
		hold off
	end

	## Compatibility hack for older Octave versions (tested on 5.2.0):
	## Set location and orientation explicitly to "default" to force
	## an update of the legend from current "displayname" properties.
	## This is not necessary in newer versions, where the legend is
	## updated automatically.
	if (compare_versions(version, "5.2.0", "<="))
		legend("location", "default", "orientation", "default");
	end
end

%!demo
%! x = (0:15)';
%! y = exp(4:-0.25:0.25)';
%! fits = fit_decay(x, y);
%! plot_fit_decay(x, y, fits);
%! title("Fit all data");

%!demo
%! x = (0:15)';
%! y = exp([0.38 1.54 2.98 2.46 3:-0.25:0.25])';
%! fits = fit_decay(x, y, "xmin", 4);
%! plot_fit_decay(x, y, fits);
%! title("Fit data where x >= 4");

%!demo
%! x = (0:15)';
%! y = exp((4:-0.25:0.25) .* [2; 1.7; 1.5; 1.2; 1]);
%! fits = fit_decay(x, y, "dim", 2);
%! plot_fit_decay(x, y, fits, "dim", 2);
%! title("Multiple fits along 2nd dimension");

%!demo
%! x = (0:15)';
%! y = exp((4:-0.25:0.25) .* [2; 1.7; 1.5; 1.2; 1]);
%! fits = fit_decay(x, y, "dim", 2);
%! plot_fit_decay(x, y, fits, "idx", {[3:5], 1}, "dim", 2);
%! title("A subset of multiple fits");

%!demo
%! x = (0:15)';
%! y = exp((4:-0.25:0.25) .* [2; 1.7; 1.5; 1.2; 1]);
%! fits = fit_decay(x, y, "dim", 2);
%! fmtsubs = @(subs) sprintf("%d,", subs{:})(1:end-1);
%! labelfun = @(fit, subs) sprintf("[%s] tau = %f", fmtsubs(subs), fit.fite.tau);
%! plot_fit_decay(x, y, fits, "dim", 2, "label", labelfun);
%! legend show
%! title("Custom labels with function in 'label' parameter");

%!demo
%! s.t = (0:15)';
%! s.in = exp(4:-0.25:0.25)';
%! fits = fit_decay(s);
%! plot_fit_decay(s, fits);
%! title("With structure argument");

%!demo
%! s.t = (0:15)';
%! s.in = exp([0.7 0.8 0.9; 1.0 1.1 1.2] .* reshape(4:-0.25:0.25, 1, 1, []));
%! fits = fit_decay(s.t, s.in, "dim", 3);
%! fmtsubs = @(subs) sprintf("%d,", subs{:})(1:end-1);
%! labelfun = @(fit, subs) sprintf("[%s] tau = %f", fmtsubs(subs), fit.fite.tau);
%! plot_fit_decay(s, fits, "dim", 3, "idx", {2:3}, "label", labelfun);
%! legend show
%! title("With structure argument and higher dimension");
%! # The labels should show coordinates [2,1] and [1,2].
