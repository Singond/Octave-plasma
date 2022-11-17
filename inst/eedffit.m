function r = eedffit(E, f)
	pkg load optim;
	pkg load singon-ext;

	persistent elemcharge = 1.602177e-19;    # Elementary charge [C]
	persistent boltzmann = 1.380649e-23;     # Boltzmann constant [J/K]

	## Fit Maxwell-Boltzmann distribution (linearized)
	## f(E) = a * sqrt(E) * exp(-E/b)
	beta = ols(log(f) - log(E)/2, [ones(size(E)) E]);
	r.mbl = struct();
	r.mbl.beta = beta;
	r.mbl.a = exp(beta(1));
	r.mbl.b = -1/beta(2);
	r.mbl.f = @(E) exp(beta(1) + beta(2).*E) .* sqrt(E);
	r.mbl.T = r.mbl.b * elemcharge / boltzmann;

	## Fit Maxwell-Boltzmann distribution non-linearly
	## f(E) = a * sqrt(E) * exp(-E/b)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-E./beta(2));
	beta0 = [r.mbl.a 10000 * boltzmann / elemcharge];
	opts.bounds = [
		0 Inf
		0 Inf
	];
	try
		[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
			beta0, model, [], [], [], [], [], opts);
		r.mbnl.beta = beta;
		r.mbnl.f = @(E) model(E, beta);
		r.mbnl.a = beta(1);
		r.mbnl.b = beta(2);
		r.mbnl.T = r.mbnl.b * elemcharge / boltzmann;
		if (!cvg)
			warning("Maxwell-Boltzmann fit did not converge");
		elseif (iter == 1)
			warning("Maxwell-Boltzmann fit stopped after first iteration");
		endif
		r.mb = r.mbnl;
	catch err
		warning(["Failed to fit Maxwell-Boltzmann distribution: " err.message]);
		warning("Falling back to linearized fit");
		r.mb = r.mbl;
	end_try_catch

	## Fit Druyvesteyn distribution (linearized)
	## f(E) = a * sqrt(E) * exp((-E/b)^2)
	beta = ols(log(f) - log(E)/2, [ones(size(E)) E.^2]);
	r.drl = struct();
	r.drl.beta = beta;
	r.drl.a = exp(beta(1));
	r.drl.b = 1/sqrt(abs(beta(2)));  # XXX
	r.drl.f = @(E) exp(beta(1) + beta(2).*E.^2) .* sqrt(E);
	r.drl.T = r.drl.b * elemcharge / boltzmann;

	## Fit Druyvesteyn distribution non-linearly
	## f(E) = a * sqrt(E) * exp((-E/b)^2)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-(E./beta(2)).^2);
	beta0 = [r.drl.a 10000 * boltzmann / elemcharge];
	opts.bounds = [
		0 Inf
		0 Inf
	];
	try
		[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
			beta0, model, [], [], [], [], [], opts);
		r.drnl.beta = beta;
		r.drnl.f = @(E) model(E, beta);
		r.drnl.a = beta(1);
		r.drnl.b = beta(2);
		r.drnl.T = r.drnl.b * elemcharge / boltzmann;
		if (!cvg)
			warning("Druyvesteyn fit did not converge");
		elseif (iter == 1)
			warning("Druyvesteyn fit stopped after first iteration");
		endif
		r.dr = r.drnl;
	catch err
		warning(["Failed to fit Druyvesteyn distribution: " err.message]);
		warning("Falling back to linearized fit");
		r.dr = r.drl;
	end_try_catch

	## Fit general distribution
	## f(E) = a * sqrt(E) * exp((-E/b)^c)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-(E./beta(2)).^beta(3));
	beta0 = [r.drl.a r.drl.b 2];
	opts.bounds = [
		0 Inf
		0 Inf
		0 Inf
	];
	try
		[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
			beta0, model, [], [], [], [], [], opts);
		r.gen.beta = beta;
		r.gen.f = @(E) model(E, beta);
		r.gen.a = beta(1);
		r.gen.b = beta(2);
		r.gen.c = beta(3);
		r.gen.T = r.gen.b * elemcharge / boltzmann;
		r.gen.kappa = r.gen.c;
		if (!cvg)
			warning("General fit did not converge");
		elseif (iter == 1)
			warning("General fit stopped after first iteration");
		endif
	catch err
		warning(["Failed to fit general distribution: " err.message]);
	end_try_catch
endfunction

%!shared known_noise
%! rand("seed", 8);
%! known_noise = (rand(200, 1) - 0.5);
%! rand("state", "reset");

%!xtest
%! # Maxwell-Boltzmann distribution with random noise
%! # (may fail occasionally)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 4;
%! noise = (rand(s) - 0.5);
%! f = (a) .* sqrt(E) .* exp(-E ./ b) + 0.4 * noise;
%! r = eedffit(E, f);
%! assert(r.mbl.a,     a, 0.8);
%! assert(r.mbl.b,     b, 0.6);
%! assert(r.mb.a,      a, 0.1);
%! assert(r.mb.b,      b, 0.1);
%! assert(r.gen.a,     a, 0.3);
%! assert(r.gen.b,     b, 0.2);
%! assert(r.gen.kappa, 1, 0.03);

%!test
%! # Maxwell-Boltzmann distribution with given noise
%! # (expected values taken from original implementation)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 4;
%! f = (a) .* sqrt(E) .* exp(-E ./ b) + 0.4 * known_noise;
%! r = eedffit(E, f);
%! assert(r.mbl.a,     6.9084, 1e-4);
%! assert(r.mbl.b,     4.0096, 1e-4);
%! assert(r.mb.a,      7.0034, 1e-4);
%! assert(r.mb.b,      3.9946, 1e-4);
%! assert(r.gen.a,     6.9476, 1e-4);
%! assert(r.gen.b,     4.0341, 1e-4);
%! assert(r.gen.kappa, 1.0082, 1e-4);

%!xtest
%! # Druyvesteyn distribution with random noise
%! # (may fail occasionally)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 8;
%! noise = (rand(s) - 0.5);
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^2) + 0.01 * noise;
%! r = eedffit(E, f);
%! assert(r.drl.a,     a, 0.02);
%! assert(r.drl.b,     b, 0.01);
%! assert(r.dr.a,      a, 0.001);
%! assert(r.dr.b,      b, 0.001);
%! assert(r.gen.a,     a, 0.002);
%! assert(r.gen.b,     b, 0.002);
%! assert(r.gen.kappa, 2, 0.001);

%!test
%! # Druyvesteyn distribution with given noise
%! # (expected values taken from original implementation)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 8;
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^2) + 0.01 * known_noise;
%! r = eedffit(E, f);
%! assert(r.drl.a,     6.9861, 1e-4);
%! assert(r.drl.b,     8.0061, 1e-4);
%! assert(r.dr.a,      7.0001, 1e-4);
%! assert(r.dr.b,      7.9998, 1e-4);
%! assert(r.gen.a,     6.9999, 1e-4);
%! assert(r.gen.b,     8.0000, 1e-4);
%! assert(r.gen.kappa, 2.0001, 1e-4);

%!xtest
%! # Generalized distribution with random noise
%! # (may fail occasionally)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 12;
%! k = 2.6;
%! noise = (rand(s) - 0.5);
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^k) + 0.4 * noise;
%! r = eedffit(E, f);
%! assert(r.gen.a,     a, 0.04);
%! assert(r.gen.b,     b, 0.03);
%! assert(r.gen.kappa, k, 0.03);

%!test
%! # Generalized distribution with given noise
%! # (may fail occasionally)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 12;
%! k = 2.6;
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^k) + 0.4 * known_noise;
%! r = eedffit(E, f);
%! assert(r.gen.a,      7.0029, 1e-4);
%! assert(r.gen.b,     11.9914, 1e-4);
%! assert(r.gen.kappa,  2.5977, 1e-4);
