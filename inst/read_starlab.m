## -*- texinfo -*-
## @deftypefn  {} {[@var{data}, @var{meta}] =} read_starlab (@var{file})
## @deftypefnx {} {[@var{data}, @var{meta}] =} read_starlab @
##   (@dots{}, @qcode{"emptyvalue"}, @var{value})
## @deftypefnx {} {[@var{data}, @var{meta}] =} read_starlab @
##   (@dots{}, @qcode{"overvalue"}, @var{value})
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
## The second return value @var{meta} is a struct with the metadata
## read from the file header.
## @end deftypefn
function [data, meta] = read_starlab(varargin)
	p = inputParser;
	p.addRequired("file");
	p.addParameter("emptyvalue", nan);
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

		## Skip the "Statistics" section of each channel
		while (!startsw(fgetl(f), ";---------"))
			## Keep skipping lines
		endwhile
		fskipl(f, 4);
		meta.channels = ch;
	catch err
		err.message = sprintf(
			"read_starlab: Bad file header in %s: %s",
			basename, err.message);
		rethrow(err);
	end

	## Read data
	if (feof(f))
		## No data after header
		warning("read_starlab: No data in %s", basename);
		data = [];
	else
		fmt = [repmat("%s ", [1 length(ch) + 1]) "%*s"];
		cdata = textscan(f, fmt,
			"Delimiter", '\t',
			"EmptyValue", args.emptyvalue);
		cdata = [cdata{:}];
		data = str2double(cdata);
		## Handle "Over" values
		m = strcmp(cdata, "Over       ");
		data(m) = args.overvalue;
		## Remove blank line at the end
		if (all(isnan(data(end,:))) && rows(data) > 1)
			data = data(1:end-1,:);
		end
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
