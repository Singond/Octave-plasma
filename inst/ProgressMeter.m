## Helper class for printing progress of long running operations.
classdef ProgressMeter < handle
	properties (Access = private)
		count = 0;
		total = 0;
		every = 10;
		message = "%d/%d\n";
		out = stderr;
	end

	methods
		function m = ProgressMeter(varargin)
			p = inputParser;
			p.addRequired("total", @isnumeric);
			p.addParameter("message", "", @ischar);
			p.addParameter("name", "", @ischar);
			p.addParameter("every", 10, @isnumeric);
			p.parse(varargin{:});

			m.total = p.Results.total;
			if (m.total <= 0)
				error("ProgressMeter: TOTAL must be positive\n");
			end
			if (!isempty(p.Results.message))
				m.message = p.Results.message;
			elseif (!isempty(p.Results.name))
				m.message = [p.Results.name ": %d/%d\n"];
			end
			m.every = p.Results.every;
			if (m.every <= 0)
				error("ProgressMeter: EVERY must be positive\n");
			end
		end

		function increment(m, n = 1)
			m.count += n;
			m.countchanged;
		end
	end

	methods (Access = private)
		function countchanged(m)
			if ((mod(m.count, m.every) == 0) || m.count == m.total)
				fprintf(m.out, m.message, m.count, m.total);
			end
		end
	end
end
