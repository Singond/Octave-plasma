classdef Spectrum
	## -*- texinfo -*-
	## @deftp  {Class} Spectrum
	## An optical spectrum consisting of wavelengths, spectral intensities
	## and some metadata.
	## The object contains the following fields:
	##
	## @table @code
	## @item wl
	## Wavelength values.
	##
	## @item in
	## Values of the spectral intensity corresponding to @code{wl}.
	##
	## @item acqtime
	## Acquisition time (integration time) of measurement.
	##
	## @item accumulations
	## Number of accumulations used in measurement.
	##
	## @item title
	## Spectrum title.
	##
	## @item description
	## Longer description.
	##
	## @item metadata
	## Arbitrary data in a @code{containers.Map} object.
	## @end table
	## @end deftp
	##
	## @deftypefn {Constructor} {@var{s} =} Spectrum @
	##   (@var{wl}, @var{in}, @var{metadata})
	## Create a new @code{Spectrum} object with wavelengths @var{wl},
	## intensities @var{in} and @var{metadata}.
	## @end deftypefn
	##
	## @defun dlmwrite (@var{spectrum}, @dots{})
	## @end defun
	properties
		wl;
		in;
		acqtime = 1;
		accumulations = 1;
		title = "";
		description= "";
		metadata = containers.Map();
	endproperties

	methods
		function self = Spectrum(wl, in, varargin)
			## The absence of an empty constructor causes problems
			## when copying object arrays. Therefore, provide
			## graceful handling of zero-argument invocation.
			if (nargin == 0)
				return
			endif

			if (!isvector(wl))
				error("Spectrum: WL must be a vector");
			elseif (!isvector(in))
				error("Spectrum: IN must be a vector");
			endif
			self.wl = wl(:);
			self.in = in(:);
			k = 0;
			while ++k <= numel(varargin)
				arg = varargin{k};
				if (ischar(arg))
					if (k >= numel(varargin))
						error("Expecting argument after '%s'.", arg);
					elseif (strcmp(arg, "acqtime"))
						self.acqtime = varargin{++k};
					elseif (strcmp(arg, "accumulations"))
						self.accumulations = varargin{++k};
					elseif (strcmp(arg, "title"))
						self.title = varargin{++k};
					elseif (strcmp(arg, "description"))
						self.description = varargin{++k};
					else
						self.metadata(arg) = varargin{++k};
					endif
				else
					error("Spectrum: Bad argument #%i", k+2);
				end
			endwhile
		endfunction

		function h = plot(spectrum, varargin)
			if (!isscalar(spectrum))
				wlcell = cell(numel(spectrum) * 2 - 1, 1);
				wlcell(1:2:end) = {spectrum.wl};
				wlcell(2:2:end) = NaN;
				wl = vertcat(wlcell{:});
				incell = cell(size(wlcell));
				incell(1:2:end) = {spectrum.in};
				incell(2:2:end) = NaN;
				in = vertcat(incell{:});
			else
				wl = spectrum(1).wl;
				in = spectrum(1).in;
			endif
			_h = plot(wl, in, varargin{:});
			if (nargout > 0)
				h = _h;
			endif
		endfunction

		## -*- texinfo -*-
		## @deftypemethod  {Spectrum} {@var{s} =} getrange ()
		## Return the wavelength range of this spectrum.
		##
		## If the @code{range} property is not empty, return this value,
		## otherwise calculate the range as the extremes of the @code{wl}
		## property.
		## @end deftypemethod
		function range = getrange(self)
			range = zeros(numel(self), 2);
			for i = 1:numel(self)
				if (numel(self(i).range) == 2)
					range(i,:) = self(i).range;
				else
					## Range not given separately, calculate it from wl
					range(i,:) = [min(self.wl), max(self.wl)];
				endif
			endfor
		endfunction

		## -*- texinfo -*-
		## @deftypemethod  {Spectrum} {@var{s} =} appenddescription @
		##   (@var{description})
		## Return a copy of this spectrum with @var{description}
		## appended to its @code{description} property.
		## @end deftypemethod
		function self = appenddescription(self, description)
			if (!isempty(self.description))
				separator = "\n";
			else
				separator = "";
			endif
			self.description = [self.description separator description];
		endfunction

		function disp(self)
			if (isscalar(self))
				printf("  Spectrum with the following properties:\n\n");
			else
				printf("  Array of spectra with the following properties:\n\n");
			endif
			for i = 1:numel(self)
				if (!isscalar(self))
					printf("\n  (%d):\n", i);
				endif
				printf("    title:                %s\n", self(i).title);
				printf("    acquisition time:     %f\n", self(i).acqtime);
				printf("    accumulations:        %d\n", self(i).accumulations);
				printf("    data points:          %d\n", numel(self(i).wl));
				for j = 1:self(i).metadata.length
					printf("    %-21s %s\n", [self(i).metadata.keys{j} ":"],
						deblank(disp(self(i).metadata.values{j})));
				endfor
				printf("    description:\n");
				printf("      %s\n",
					strrep(self(i).description, "\n", "\n      "));
			endfor
		endfunction

		## @defun  dlmwrite (@var{spectrum}, @var{file})
		## @defunx dlmwrite (@var{spectrum}, @var{file}, @var{args})
		## @defunx dlmwrite (@var{spectrum}, @var{fid}, @dots{})
		## Write the wavelength and intensity data to the text file @var{file}
		## in a delimiter-separated format.
		##
		## If @var{spectrum} is an array, the output from each of the
		## elements is concatenated in one file, separated by a blank line.
		##
		## Additional @var{args} are passed directly into the basic
		## @code{dlmwrite} function.
		## @end defun
		function dlmwrite(self, file, varargin)
			if (ischar(file))
				file = fopen(file, "w");
				close = true;
			else
				close = false;
			endif
			for i = 1:numel(self)
				if (i != 1)
					fprintf(file, "\n");
				endif
				fprintf(file, "# title: %s\n", self(i).title);
				fprintf(file, "# acquisition time: %g\n", self(i).acqtime);
				fprintf(file, "# accumulations: %d\n", self(i).accumulations);
				dlmwrite(file, [self(i).wl self(i).in], varargin{:});
			endfor
			if (close)
				fclose(file);
			endif
		endfunction
	endmethods
endclassdef

%!# Constructor
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3]);
%! assert(S.wl, [10 20 30 40 50 60 70 80 90 100]');
%! assert(S.in, [7 2 6 0 4 1 9 3 2 3]');
%! assert(S.acqtime, 1);
%! assert(S.accumulations, 1);
%! assert(S.title, "");
%! assert(S.description, "");
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3], "acqtime", 0.05);
%! assert(S.acqtime, 0.05);
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3], "accumulations", 10);
%! assert(S.accumulations, 10);
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3], "title", "My spectrum");
%! assert(S.title, "My spectrum");
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3], "description",
%!     "A long\ndescription");
%! assert(S.description, "A long\ndescription");
%!# Metadata
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3], "some metadata", 2400);
%! assert(S.metadata("some metadata"), 2400);

%!# Display with metadata
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3], "some metadata", 2400);
%! evalc("disp(S)");  # Should not produce an error

%!# As array
%!test
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3]);
%! S(2) = Spectrum(150:10:250, [1 -1 2 8 1 6 9 3 1 5 0]);


%!demo
%! S = Spectrum(10:10:100, [7 2 6 0 4 1 9 3 2 3]);
%! S(2) = Spectrum(150:10:250, [1 -1 2 8 1 6 9 3 1 5 0]);
%! T = Spectrum(10:10:110, [2 8 6 -1 4 2 8 5 0 10 2]);
%! T(2) = Spectrum(150:10:220, [2 0 8 -1 4 0 6 4]);
%! hold on
%! plot(S)
%! plot(T)
%! legend("blue signal", "red signal");
