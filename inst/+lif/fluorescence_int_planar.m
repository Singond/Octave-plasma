function F = fluorescence_int_planar(Ly, a, b)
	F = 2 * (a ./ b) .* (1 - log(1 + b .* Ly) ./ (b .* Ly));
end
