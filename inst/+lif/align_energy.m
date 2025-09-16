## -*- texinfo -*-
## @deftypefn  {} {@var{avg} =} lif.align_energy (@var{t}, @var{E}, @var{edges})
##
## Average energy @var{E} given in times @var{t} over intervals
## given by @var{edges}.
##
## @var{edges} is a one- or two-column matrix specifying the start
## (and optionally ends) of the intervals.
##
## The return value is a vector of length @var{N},
## where @var{N} is the number of rows in @var{edges}.
## @end deftypefn
function r = align_energy(t, E, edges)
	if (columns(edges) == 1)
		skips = false;
	elseif (columns(edges) == 2)
		edges = edges'(:);
		skips = true;
	else
		error("lif.align_energy: EDGES must be a 1- or 2-column matrix");
	end

	[~, idx] = histc(t, edges);
	m = idx > 0;
	r = accumarray(idx(m), E(m), [], @mean);
	if (skips)
		r = r(1:2:end);
	end
end
