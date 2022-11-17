function [mbl, mb, drl, dr, gen] = eedffit(E, f)
	pkg load optim;
	pkg load singon-ext;

	persistent elemcharge = 1.602177e-19;    # Elementary charge [C]
	persistent boltzmann = 1.380649e-23;     # Boltzmann constant [J/K]

	## Fit Maxwell-Boltzmann distribution (linearized)
	## f(E) = a * sqrt(E) * exp(-E/b)
	beta = ols(log(f) - log(E)/2, [ones(size(E)) E]);
	mbl = struct();
	mbl.beta = beta;
	mbl.a = exp(beta(1));
	mbl.b = -1/beta(2);
	mbl.f = @(E) exp(beta(1) + beta(2).*E) .* sqrt(E);
	mbl.T = mbl.b * elemcharge / boltzmann;

	## Fit Maxwell-Boltzmann distribution non-linearly
	## f(E) = a * sqrt(E) * exp(-E/b)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-E./beta(2));
	beta0 = [mbl.a 10000 * boltzmann / elemcharge];
	opts.bounds = [
		0 Inf
		0 Inf
	];
	try
		[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
			beta0, model, [], [], [], [], [], opts);
		mbnl.beta = beta;
		mbnl.f = @(E) model(E, beta);
		mbnl.a = beta(1);
		mbnl.b = beta(2);
		mbnl.T = mbnl.b * elemcharge / boltzmann;
		if (!cvg)
			warning("Maxwell-Boltzmann fit did not converge");
		elseif (iter == 1)
			warning("Maxwell-Boltzmann fit stopped after first iteration");
		endif
		mb = mbnl;
	catch err
		warning(["Failed to fit Maxwell-Boltzmann distribution: " err.message]);
		warning("Falling back to linearized fit");
		mb = mbl;
	end_try_catch

	## Fit Druyvesteyn distribution (linearized)
	## f(E) = a * sqrt(E) * exp((-E/b)^2)
	beta = ols(log(f) - log(E)/2, [ones(size(E)) E.^2]);
	drl = struct();
	drl.beta = beta;
	drl.a = exp(beta(1));
	drl.b = 1/sqrt(abs(beta(2)));  # XXX
	drl.f = @(E) exp(beta(1) + beta(2).*E.^2) .* sqrt(E);
	drl.T = drl.b * elemcharge / boltzmann;

	## Fit Druyvesteyn distribution non-linearly
	## f(E) = a * sqrt(E) * exp((-E/b)^2)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-(E./beta(2)).^2);
	beta0 = [drl.a 10000 * boltzmann / elemcharge];
	opts.bounds = [
		0 Inf
		0 Inf
	];
	try
		[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
			beta0, model, [], [], [], [], [], opts);
		drnl.beta = beta;
		drnl.f = @(E) model(E, beta);
		drnl.a = beta(1);
		drnl.b = beta(2);
		drnl.T = drnl.b * elemcharge / boltzmann;
		if (!cvg)
			warning("Druyvesteyn fit did not converge");
		elseif (iter == 1)
			warning("Druyvesteyn fit stopped after first iteration");
		endif
		dr = drnl;
	catch err
		warning(["Failed to fit Druyvesteyn distribution: " err.message]);
		warning("Falling back to linearized fit");
		dr = drl;
	end_try_catch

	## Fit general distribution
	## f(E) = a * sqrt(E) * exp((-E/b)^c)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-(E./beta(2)).^beta(3));
	beta0 = [drl.a drl.b 2];
	opts.bounds = [
		0 Inf
		0 Inf
		0 Inf
	];
	try
		[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
			beta0, model, [], [], [], [], [], opts);
		gen.beta = beta;
		gen.f = @(E) model(E, beta);
		gen.a = beta(1);
		gen.b = beta(2);
		gen.c = beta(3);
		gen.T = gen.b * elemcharge / boltzmann;
		gen.kappa = gen.c;
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
%! [mbl, mb, ~, ~, gen] = eedffit(E, f);
%! assert(mbl.a,     a, 0.8);
%! assert(mbl.b,     b, 0.6);
%! assert(mb.a,      a, 0.1);
%! assert(mb.b,      b, 0.1);
%! assert(gen.a,     a, 0.3);
%! assert(gen.b,     b, 0.2);
%! assert(gen.kappa, 1, 0.03);

%!test
%! # Maxwell-Boltzmann distribution with given noise
%! # (expected values taken from original implementation)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 4;
%! f = (a) .* sqrt(E) .* exp(-E ./ b) + 0.4 * known_noise;
%! [mbl, mb, ~, ~, gen] = eedffit(E, f);
%! assert(mbl.a,     6.9084, 1e-4);
%! assert(mbl.b,     4.0096, 1e-4);
%! assert(mb.a,      7.0034, 1e-4);
%! assert(mb.b,      3.9946, 1e-4);
%! assert(gen.a,     6.9476, 1e-4);
%! assert(gen.b,     4.0341, 1e-4);
%! assert(gen.kappa, 1.0082, 1e-4);

%!xtest
%! # Druyvesteyn distribution with random noise
%! # (may fail occasionally)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 8;
%! noise = (rand(s) - 0.5);
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^2) + 0.01 * noise;
%! [~, ~, drl, dr, gen] = eedffit(E, f);
%! assert(drl.a,     a, 0.02);
%! assert(drl.b,     b, 0.01);
%! assert(dr.a,      a, 0.001);
%! assert(dr.b,      b, 0.001);
%! assert(gen.a,     a, 0.002);
%! assert(gen.b,     b, 0.002);
%! assert(gen.kappa, 2, 0.001);

%!test
%! # Druyvesteyn distribution with given noise
%! # (expected values taken from original implementation)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 8;
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^2) + 0.01 * known_noise;
%! [~, ~, drl, dr, gen] = eedffit(E, f);
%! assert(drl.a,     6.9861, 1e-4);
%! assert(drl.b,     8.0061, 1e-4);
%! assert(dr.a,      7.0001, 1e-4);
%! assert(dr.b,      7.9998, 1e-4);
%! assert(gen.a,     6.9999, 1e-4);
%! assert(gen.b,     8.0000, 1e-4);
%! assert(gen.kappa, 2.0001, 1e-4);

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
%! [~, ~, ~, ~, gen] = eedffit(E, f);
%! assert(gen.a,     a, 0.04);
%! assert(gen.b,     b, 0.03);
%! assert(gen.kappa, k, 0.03);

%!test
%! # Generalized distribution with given noise
%! # (may fail occasionally)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 12;
%! k = 2.6;
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^k) + 0.4 * known_noise;
%! [~, ~, ~, ~, gen] = eedffit(E, f);
%! assert(gen.a,      7.0029, 1e-4);
%! assert(gen.b,     11.9914, 1e-4);
%! assert(gen.kappa,  2.5977, 1e-4);
