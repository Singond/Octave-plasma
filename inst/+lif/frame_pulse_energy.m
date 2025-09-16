## -*- texinfo -*-
## @deftypefn  {} {@var{s} =} lif.frame_pulse_energy (@var{s})
##
## Calculate mean laser energy for each camera frame.
##
## Average the energy in @code{s.pwrdata} over the frame times
## taken from @code{s.imgt}.
## If the field @code{imgt} is not set, throw an error.
##
## The result is the input struct with the field @code{E} set
## to the calculated energy.
##
## @seealso{frametimes}
## @end deftypefn
function x = frame_pulse_energy(x)
	if (!isfield(x, "imgt"))
		error("lif.frame_pulse_energy: No time data in S\n");
	endif

	x.E = [];
	for k = 1:length(x.pwrdata)
		pwrdata = x.pwrdata{k};
		valid = !isinf(pwrdata(:,2));
		x.E(:,k) = lif.align_energy(pwrdata(valid,1), pwrdata(valid,2), x.imgt);
	endfor
end
