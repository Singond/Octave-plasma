## -*- texinfo -*-
## @deftypefn  {Function file} {@var{S} =} read_fhr1000(@var{file})
## Read spectrum from @var{file} in the file format produced
## by the @emph{Horiba FHR 1000} spectrometer.
##
## @var{file} is a path to the file to be read.
## The expected format is 29 header lines starting with @code{#}
## followed by tab-separated data in two columns.
## The first column is interpreted as wavelengths in nanometres,
## the second as spectral intensity in arbitrary units.
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
## The return value @var{S} is a @code{Spectrum} object with the wavelengths
## in nanometres and the spectral intensity in arbitrary units.
## @end deftypefn
function S = read_fhr1000(filename)
	f = fopen(filename, "r");

	## Parse the header
	acqtime = sscanf(fgetl(f), "#Acq. time (s)= %f");
	accumulations = sscanf(fgetl(f), "#Accumulations= %u");
	fskipl(f, 13);
	temperature = sscanf(fgetl(f), "#Detector temperature (%*cC)= %f");
	fskipl(f, 2);
	grating = sscanf(fgetl(f), "#Grating= %s");
	fskipl(f, 2);
	[minutes, seconds] = sscanf(fgetl(f), "#Full time(mm:ss)= %f:%f", "C");
	fulltime = minutes*60 + seconds;
	fskipl(f, 3);
	title = sscanf(fgetl(f), "#Title= %s");
	fskipl(f, 3);

	## Read the numeric data
	data = dlmread(f);
	fclose(f);
	S = Spectrum(data(:,1), data(:,2),
		"title", title,
		"acqtime", acqtime,
		"accumulations", accumulations,
		"temperature", temperature,
		"grating", grating,
		"total time", fulltime);
	S = S.appenddescription(sprintf("Loaded from path '%s'", filename));
endfunction
