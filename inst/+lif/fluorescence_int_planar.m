function F = fluorescence_int_planar(Ly, p)
	F = p(1) - (p(1)/p(2)) * log(1 + p(2) * Ly) ./ Ly;
end
