## -*- texinfo -*-
## @deftypefn  {} {[@var{data}, @var{meta}] =} read_fhr1000(@var{file})
## @deftypefnx {} {@var{S} =} read_fhr1000(@dots{}, @qcode{"Spectrum"})
##
## Read spectrum from @var{file} in the file format produced
## by the @emph{Horiba FHR 1000} spectrometer.
##
## @var{file} is a path to the file to be read.
## The expected format is 29 header lines starting with @code{#}
## followed by tab-separated data in two columns, which is returned
## in the matrix @var{data}.
##
## This is an example header:
##
## @verbatim
##   #Acq. time (s)=	0.15
##   #Accumulations=	20
##   #Range (nm)=	454...467
##   #Windows=	2
##   #Auto scanning=	Off
##   #Autofocus=	Off
##   #AutoExposure=	Off
##   #Spike filter=	Off
##   #Delay time (s)=	0
##   #Binning=	1
##   #Readout mode=	Signal
##   #DeNoise=	Off
##   #ICS correction=	Off
##   #Dark correction=	Off
##   #Inst. Process=	Off
##   #Detector temperature (°C)=	-75.38
##   #Instrument=	OSD
##   #Detector=	Synapse
##   #Grating=	2400
##   #Front entrance slit=	20
##   #Exit mirror=	Side
##   #Full time(mm:ss)=	4:00
##   #Project=
##   #Sample=
##   #Site=
##   #Title=	data-01
##   #Remark=
##   #Date=	10.12.2019 10:16
##   #Acquired=	10.12.2019 10:16:02
## @end verbatim
##
## The optional return value @var{meta} is a struct with metadata read
## from the file header.
##
## If called with the @qcode{"Spectrum"} switch,
## return a @code{Spectrum} object containing the wavelengths
## and spectral intensity  as well as the header data.
## @end deftypefn
function varargout = read_fhr1000(filename, varargin)
	f = fopen(filename, "r");

	## Parse the header
	D.acqtime = sscanf(fgetl(f), "#Acq. time (s)= %f");
	D.accumulations = sscanf(fgetl(f), "#Accumulations= %u");
	fskipl(f, 13);
	D.temperature = sscanf(fgetl(f), "#Detector temperature (%*cC)= %f");
	fskipl(f, 2);
	D.grating = sscanf(fgetl(f), "#Grating= %s");
	fskipl(f, 2);
	[minutes, seconds] = sscanf(fgetl(f), "#Full time(mm:ss)= %f:%f", "C");
	D.totaltime = minutes*60 + seconds;
	fskipl(f, 3);
	D.title = sscanf(fgetl(f), "#Title= %s");
	fskipl(f, 3);

	## Read the numeric data
	data = dlmread(f);
	fclose(f);

	if (any(strcmp(varargin, "Spectrum")))
		S = Spectrum(data(:,1), data(:,2),
			"title", D.title,
			"acqtime", D.acqtime,
			"accumulations", D.accumulations,
			"temperature", D.temperature,
			"grating", D.grating,
			"total time", D.totaltime);
		S = S.appenddescription(sprintf("Loaded from path '%s'", filename));
		varargout = {S};
	else
		varargout = {data, D};
	endif
endfunction
