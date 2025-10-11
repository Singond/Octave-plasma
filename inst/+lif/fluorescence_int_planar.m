## -*- texinfo -*-
## @deftypefn  {} {@var{F} =} lif.fluorescence_int_planar (@var{L}, @var{a}, @var{b})
##
## Calculate the fluorescence induced by a planar laser beam of energy @var{L},
## integrated in direction perpendicular to the beam.
##
## This is the fluorescence signal that would be detected by a sensor
## looking perpendicularly from the side of the beam,
## assuming a homogeneous medium and accounting for saturation effects.
##
## @var{L} is the laser energy.
## Subsequent parameters are related to the properties of the medium.
## Parameter @var{a} describes the linear dependence of the signal
## on @var{L} in regions of low energy,
## while @var{b} describes the deviation from this linear dependence
## caused by saturation when the laser energy is high enough.
##
## The precise formula used is:
##
## @displaymath
## F = 2a/b * (1 - ln(1 + bL) / bL)
## @end displaymath
##
## Based on the article on LIF saturation by Mrkvičková et al., 2022
## (@url{https://doi.org/10.1016/j.combustflame.2022.112100}).
## The parameters @var{a} and @var{b} correspond to the parameters
## @math{\alpha_1} and @math{\beta_1} described therein, respectively.
##
## @seealso{lif.fluorescence_int_cylindrical}
## @end deftypefn
function F = fluorescence_int_planar(L, a, b)
	F = 2 * (a ./ b) .* (1 - log(1 + b .* L) ./ (b .* L));
end
