## -*- texinfo -*-
##
## @seealso{lif.saturation}
function result = saturationx(S, varargin)
	if (!isstruct(S))
		print_usage;
		return;
	end

	result = struct([]);
	for s = S
		printf("Fitting saturation to %s (x-resolved)\n", s.name);
		s.imgnx = sum(s.imgn, 1);
		[s.ax, s.bx, s.fitsx, s.imgsmx] = lif.fit_fluorescence_int(
			reshape(s.E, 1, 1, []), s.imgnx, 3, varargin{:});
		if (isfield(s, "info") && iscell(s.info))
			s.info{end+1,1} = "Fitted saturation to each column";
		end
		result(end+1) = s;
	end
end
