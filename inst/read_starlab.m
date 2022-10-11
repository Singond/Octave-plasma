## -*- texinfo -*-
## @deftypefn  {} {[@var{data}, @var{meta}] =} read_starlab (@var{file})
## @deftypefnx {} {[@var{data}, @var{meta}] =} read_starlab @
##   (@dots{}, @qcode{"emptyvalue"}, @var{value})
##
## Read data from @var{file} in the format produced by the
## @emph{Ophir StarLab} software.
##
## @var{file} is a path to the file to be read.
## The expected format is 34 header lines starting with @code{;}
## and a data header followed by whitespace-separated numeric data.
## The first column is interpreted as time, the second as signal intensity.
##
## This is an example header:
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
## The @qcode{"emptyvalue"} option specifies the value used to fill
## non-numeric fields in data like @code{Over}. The default is @code{nan}.
##
## The second return value @var{meta} is a struct with the metadata
## read from the file header.
## @end deftypefn
function [data, D] = read_starlab(varargin)
	p = inputParser;
	p.addRequired("file");
	p.addParameter("emptyvalue", nan);
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
	D = struct();
	channels = 0;
	try
		assert(startsWith(fgetl(f), ";PC Software:StarLab Version"));
		fskipl(f, 9);
		## Channel A
		fscanf(f, ";Channel A:");
		D.description = fgetl(f);
		fskipl(f, 2);
		fscanf(f, ";Name:");
		D.name = fgetl(f);
		fskipl(f, 1);
		fscanf(f, ";Units:");
		D.units = fgetl(f);
		fskipl(f, 19);
		channels += 1;
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
		data = dlmread(f, "emptyvalue", args.emptyvalue);
		data = data(:,1:channels+1);
	end
endfunction

## Tests are in the project's 'test' directory
%!assert(1)
