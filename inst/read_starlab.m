## -*- texinfo -*-
## @deftypefn  {} {[@var{data}, @var{meta}] =} read_starlab (@var{file})
## @deftypefnx {} {[@var{data}, @var{meta}] =} read_starlab @
##   (@dots{}, @qcode{"emptyvalue"}, @var{value})
## @deftypefnx {} {[@var{data}, @var{meta}] =} read_starlab @
##   (@dots{}, @qcode{"overvalue"}, @var{value})
## @deftypefnx {} {[@var{data_1}, @var{data_2}, @dots{} @var{meta}] =} @
##   read_starlab (@dots{})
##
## Read data from @var{file} in the format produced by the
## @emph{Ophir StarLab} software.
##
## @var{file} is a path to the file to be read.
## The expected format is multiple header lines starting with @code{;}
## and a data header followed by whitespace-separated numeric data.
## The first column is interpreted as time, subsequent columns are
## signal intensity in individual channels.
##
## This is an example header for a file with one channel:
##
## @verbatim
##   ;PC Software:StarLab Version 3.72 Build 3
##   ! ******* Warning: Do not modify this file. Changes may prevent   ********
##   ! ******* the StarLab Log reader from opening the file correctly. ********
##   ;Logged:18/08/2022 at 16:06:44
##   ;File Version:5
##   ;Time Resolution:1 microseconds
##   ;Graph Mode:Merge
##   ;Graph Type:Line
##   ;Notes:
##
##   ;Channel A:Vega Pyroelectric PE9 (s/n:574745)  VG2.54 (s/n:547613)
##
##   ;Channel A:Details
##   ;Name:PE9
##   ;Graph Color:RGB(14,104,168)
##   ;Units:J
##   ;Settings:Measuring:Energy
##   ;Settings:Wavelength:206
##   ;Settings:Range:200uJ
##   ;Settings:Diffuser:N/A
##   ;Settings:Pulse Width:30uS
##   ;Settings:Threshold:N/A
##
##   ;Channel A:Statistics
##   ;Min:28.30uJ
##   ;Max:40.70uJ
##   ;Average:35.91uJ
##   ;Std.Dev.:1.458uJ
##   ;Overrange:0
##   ;Total Pulses:31590
##   ;--------------------
##
##
##   ;First Pulse Arrived : 18/08/2022 at 16:06:45
##     Timestamp   	  Channel A
## @end verbatim
##
## The handling of non-numeric data in the file can be modified through
## the named parameters @qcode{"emptyvalue"} and @qcode{"overvalue"}.
## Both take a single scalar argument, which is the value used to fill
## empty and over-range values (marked "Over" in the file).
## The default values are @code{NaN} and @code{Inf}, respectively.
##
## In addition, the @qcode{"overvalue"} can be the string @qcode{"max"},
## in which case the over-range values are filled with the maximum
## valid number in the respective column.
##
## The second return value @var{meta} is a struct with the metadata
## read from the file header.
##
## In the last form, return the data separately for each channel.
## Each of the return values @var{data_n} is a two column matrix,
## where the first column is the first column from the file
## and the second column is the data of the @code{n}th channel.
## In this case, the matrix for each channel contains only valid
## values (numbers and "Over"), the empty values having been filtered out.
## Note that to invoke this variant, at least three output arguments
## must be given.
## @end deftypefn
function varargout = read_starlab(varargin)
	p = inputParser;
	p.addRequired("file");
	p.addParameter("emptyvalue", NaN);
	p.addParameter("overvalue", Inf);
	p.parse(varargin{:});
	args = p.Results;

	cleanup = [];
	if (ischar(args.file))
		filename = args.file;
		[f, fmsg] = fopen(filename);
		if (f == -1)
			error("read_starlab: Error reading %s: %s", filename, fmsg);
		endif
		cleanup = onCleanup(@() fclose(f));
	elseif (is_valid_file_id(args.file))
		filename = "stream";
		f = args.file;
	end
	[~, name, ext] = fileparts(filename);
	basename = [name ext];

	## Parse header
	meta = struct();
	ch = struct();
	try
		assert(startsw(fgetl(f), ";PC Software:StarLab Version"));
		fskipl(f, 9);

		## Find number of channels and their names
		k = 1;
		while (!isempty(id = fscanf(f, ";Channel %c:")))
			ch(k) = struct("id", id, "description", fgetl(f));
			k++;
		endwhile
		fskipl(f, 1);

		## Read the "Details" section of each channel
		for k = 1:length(ch);
			id = fscanf(f, ";Channel %c:Details");
			assert(strcmp(ch(k).id, id));
			fgetl(f);  # Consume rest of line
			fscanf(f, ";Name:");
			ch(k).name = fgetl(f);
			fskipl(f, 1);
			fscanf(f, ";Units:");
			ch(k).units = fgetl(f);
			while (!isempty(fgetl(f)))
				## Keep skipping lines
			endwhile
		endfor

		header_ended = false;
		for k = 1:length(ch);
			assert(!header_ended);
			id = fscanf(f, ";Channel %c:Statistics");
			assert(strcmp(ch(k).id, id));
			fgetl(f);  # Consume rest of line
			while (!header_ended && !isempty(line = fgetl(f)))
				if (startsw(line, ";---------"))
					header_ended = true;
					continue;
				endif
				assert(startsw(line, ";"));
				line = line(2:end);
				parts = strsplit(line, ":");
				if (strcmp(parts{1}, "Overrange"))
					ch(k).overrange = str2double(parts{2});
				elseif (strcmp(parts{1}, "Total Pulses"))
					ch(k).pulses = str2double(parts{2});
				endif
			endwhile
		endfor
		clear k;

		fskipl(f, 4);
		meta.channels = ch;
	catch err
		err.message = sprintf(
			"read_starlab: Bad file header in %s: %s",
			basename, err.message);
		rethrow(err);
	end

	## Finish gracefully if there is no data
	if (feof(f))
		## No data after header
		warning("read_starlab: No data in %s", basename);
		varargout = {[], meta};
		return;
	end

	## Read data
	fmt = [repmat("%s ", [1 length(ch) + 1]) "%*s"];
	cdata = textscan(f, fmt, "Delimiter", '\t');
	cdata = [cdata{:}];
	data = str2double(cdata);

	## Handle "Over" values
	over = strcmp(cdata, "Over       ");
	if (strcmp(args.overvalue, "max"))
		## Substitute overs with maximum in that column
		cmax = max(data, [], 1);
		m = over .* cmax;
		data(over) = m(over);
	else
		data(over) = args.overvalue;
	end

	## Handle empty values
	empty = cellfun("isempty", cdata);
	data(empty) = args.emptyvalue;

	## Check data with statistics from header
	for k = 1:length(ch);
		oversum = sum(over(:,k+1));
		if (oversum != ch(k).overrange)
			error("read_starlab: Found %d 'Over' values in channel %s but header states %d",
				oversum, ch(k).id, ch(k).overrange);
		endif

		emptysum = sum(empty(:,k+1));
		nonempty = rows(cdata) - emptysum;
		if (nonempty != ch(k).pulses)
			error("read_starlab: Found %d nonempty values in channel %s but header states %d",
				nonempty, ch(k).id, ch(k).pulses);
		endif
	endfor

	## Remove blank line at the end
	if (all(empty(end,:)))
		data = data(1:end-1,:);
		empty = empty(1:end-1,:);
	end

	## Split return value per channel, removing rows with empty value
	if (nargout > 2)
		t = data(:,1);
		out = {};
		for c = 2:columns(data)
			v = data(:,c);
			m = !empty(:,c);
			out = [out, {[t(m) v(m)]}];
		end
		varargout = [out, {meta}];
	else
		varargout = {data, meta};
	end
endfunction

function r = startsw(str, head)
	if (length(str) >= length(head))
		r = strcmp(str(1:length(head)), head);
	else
		r = false;
	endif
endfunction

## Tests are in the project's 'test' directory
%!assert(1)
