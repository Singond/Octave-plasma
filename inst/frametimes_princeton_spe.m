## -*- texinfo -*-
## @deftypefn  {} {@var{t} =} frametimes_princeton_spe (@var{spe}, @var{trigp})
##
## Estimate times corresponding to the beginning and end of every frame
## in the .SPE file @var{spe}.
##
## The first argument is a struct containing metadata read from
## the file header by @code{read_princeton_spe}.
## The second argument, @var{trigp}, is the triggering period in seconds,
## that is the time between consecutive accumulations of signal.
##
## The output is a two-column matrix with one row for each frame,
## where the first and second columns correspond to the beginning
## and end of that frame, respectively.
## @seealso{read_princeton_spe}
## @end deftypefn
function t = frametimes_princeton_spe(spe, tp)
	if (nargin < 2)
		print_usage;
	end

	accumtime = spe.accum * tp;
	period = accumtime + spe.readouttime;
	t = (0:(spe.numframes - 1))' * period;
	t = [t t + accumtime];
end

%!test
%! spe.accum = 500;
%! spe.readouttime = 0.25;
%! spe.numframes = 4;
%! expected = [
%!    0.00 10.00;
%!   10.25 20.25;
%!   20.50 30.50;
%!   30.75 40.75;
%! ];
%! assert(frametimes_princeton_spe(spe, 1/50), expected, eps);

%!# Trigger period must be specified
%!error <Invalid call to frametimes_princeton_spe>
%! frametimes_princeton_spe(struct());
