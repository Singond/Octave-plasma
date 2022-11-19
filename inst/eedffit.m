function [mbl, mb, drl, dr, gen] = eedffit(E, f)
	pkg load optim;
	pkg load singon-ext;

	persistent elemcharge = 1.602177e-19;    # Elementary charge [C]
	persistent boltzmann = 1.380649e-23;     # Boltzmann constant [J/K]
	c = struct();
	c.Tscale = elemcharge / boltzmann;

	## Fit Maxwell-Boltzmann distribution (linearized)
	if (isargout(1) || isargout(2))
		mbl = fit_mb_lin(E, f, c);
	endif

	## Fit Maxwell-Boltzmann distribution non-linearly
	if (isargout(2))
		try
			beta0 = [mbl.a 10000 / c.Tscale];
			mb = fit_mb(E, f, beta0, c);
		catch err
			warning(["Failed to fit Maxwell-Boltzmann distribution: " err.message]);
			warning("Falling back to linearized fit");
			mb = mbl;
		end_try_catch
	endif

	## Fit Druyvesteyn distribution (linearized)
	if (isargout(3) || isargout(4) || isargout(5))
		drl = fit_dr_lin(E, f, c);
	endif

	## Fit Druyvesteyn distribution non-linearly
	if (isargout(4))
		try
			beta0 = [drl.a 10000 / c.Tscale];
			dr = fit_dr(E, f, beta0, c);
		catch err
			warning(["Failed to fit Druyvesteyn distribution: " err.message]);
			warning("Falling back to linearized fit");
			dr = drl;
		end_try_catch
	endif

	## Fit general distribution
	## f(E) = a * sqrt(E) * exp(-(E/b)^c)
	if (isargout(5))
		try
			beta0 = [drl.a drl.b 2];
			gen = fit_gen(E, f, beta0, c);
		catch err
			warning(["Failed to fit general distribution: " err.message]);
		end_try_catch
	endif
endfunction

## Fit Maxwell-Boltzmann distribution (linearized).
## f(E) = a * sqrt(E) * exp(-E/b)
function F = fit_mb_lin(E, f, c)
	beta = ols(log(f) - log(E)/2, [ones(size(E)) E]);
	F = struct();
	F.beta = beta;
	F.a = exp(beta(1));
	F.b = -1/beta(2);
	F.f = @(E) exp(beta(1) + beta(2).*E) .* sqrt(E);
	F.T = F.b * c.Tscale;
endfunction

## Fit Maxwell-Boltzmann distribution non-linearly.
## f(E) = a * sqrt(E) * exp(-E/b)
function F = fit_mb(E, f, beta0, c)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-E./beta(2));
	opts.bounds = [
		0 Inf
		0 Inf
	];

	[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
		beta0, model, [], [], [], [], [], opts);

	F = struct();
	F.beta = beta;
	F.f = @(E) model(E, beta);
	F.a = beta(1);
	F.b = beta(2);
	F.T = F.b * c.Tscale;

	if (!cvg)
		warning("Maxwell-Boltzmann fit did not converge");
	elseif (iter == 1)
		warning("Maxwell-Boltzmann fit stopped after first iteration");
	endif
endfunction

## Fit Druyvesteyn distribution (linearized).
## f(E) = a * sqrt(E) * exp(-(E/b)^2)
function F = fit_dr_lin(E, f, c)
	beta = ols(log(f) - log(E)/2, [ones(size(E)) E.^2]);
	F = struct();
	F.beta = beta;
	F.a = exp(beta(1));
	F.b = 1/sqrt(abs(beta(2)));  # XXX
	F.f = @(E) exp(beta(1) + beta(2).*E.^2) .* sqrt(E);
	F.T = F.b * c.Tscale;
endfunction

## Fit Druyvesteyn distribution non-linearly.
## f(E) = a * sqrt(E) * exp(-(E/b)^2)
function F = fit_dr(E, f, beta0, c)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-(E./beta(2)).^2);
	opts.bounds = [
		0 Inf
		0 Inf
	];

	[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
		beta0, model, [], [], [], [], [], opts);

	F = struct();
	F.beta = beta;
	F.f = @(E) model(E, beta);
	F.a = beta(1);
	F.b = beta(2);
	F.T = F.b * c.Tscale;

	if (!cvg)
		warning("Druyvesteyn fit did not converge");
	elseif (iter == 1)
		warning("Druyvesteyn fit stopped after first iteration");
	endif
endfunction

## Fit generalized distribution.
## f(E) = a * sqrt(E) * exp(-(E/b)^c)
function F = fit_gen(E, f, beta0, c)
	model = @(E, beta) sqrt(E) .* beta(1) .* exp(-(E./beta(2)).^beta(3));
	opts.bounds = [
		0 Inf
		0 Inf
		0 Inf
	];

	[fm, beta, cvg, iter, ~, covp] = leasqr(E, f,
		beta0, model, [], [], [], [], [], opts);

	F = struct();
	F.beta = beta;
	F.f = @(E) model(E, beta);
	F.a = beta(1);
	F.b = beta(2);
	F.c = beta(3);
	F.T = F.b * c.Tscale;
	F.kappa = F.c;

	if (!cvg)
		warning("General fit did not converge");
	elseif (iter == 1)
		warning("General fit stopped after first iteration");
	endif
endfunction

%!# The 'clear -g verbose' inside the tests is used to silence warnings
%!# about a global variable leaked by the 'leasqr' function.

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
%! clear -g verbose;
%! assert(mbl.a,     a, 0.8);
%! assert(mbl.b,     b, 0.6);
%! assert(mb.a,      a, 0.1);
%! assert(mb.b,      b, 0.1);
%! assert(gen.a,     a, 0.3);
%! assert(gen.b,     b, 0.2);
%! assert(gen.kappa, 1, 0.03);
%! assert(mbl.f(E),  mbl.a .* sqrt(E) .* exp(-E/mbl.b), 1e-14);
%! assert(mb.f(E),   mb.a  .* sqrt(E) .* exp(-E/mb.b),  1e-14);
%! assert(gen.f(E),  gen.a .* sqrt(E) .* exp(-(E/gen.b) .^ gen.kappa), 1e-14);

%!test
%! # Maxwell-Boltzmann distribution with given noise
%! # (expected values taken from original implementation)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 4;
%! f = (a) .* sqrt(E) .* exp(-E ./ b) + 0.4 * known_noise;
%! [mbl, mb, ~, ~, gen] = eedffit(E, f);
%! clear -g verbose;
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
%! clear -g verbose;
%! assert(drl.a,     a, 0.02);
%! assert(drl.b,     b, 0.01);
%! assert(dr.a,      a, 0.001);
%! assert(dr.b,      b, 0.001);
%! assert(gen.a,     a, 0.002);
%! assert(gen.b,     b, 0.002);
%! assert(gen.kappa, 2, 0.001);
%! assert(drl.f(E),  drl.a .* sqrt(E) .* exp(-(E/drl.b) .^ 2), 1e-14);
%! assert(dr.f(E),   dr.a  .* sqrt(E) .* exp(-(E/dr.b)  .^ 2), 1e-14);
%! assert(gen.f(E),  gen.a .* sqrt(E) .* exp(-(E/gen.b) .^ gen.kappa), 1e-14);

%!test
%! # Druyvesteyn distribution with given noise
%! # (expected values taken from original implementation)
%! E = (0.1:0.1:20)';
%! s = size(E);
%! a = 7;
%! b = 8;
%! f = (a) .* sqrt(E) .* exp(-(E ./ b).^2) + 0.01 * known_noise;
%! [~, ~, drl, dr, gen] = eedffit(E, f);
%! clear -g verbose;
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
%! clear -g verbose;
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
%! clear -g verbose;
%! assert(gen.a,      7.0029, 1e-4);
%! assert(gen.b,     11.9914, 1e-4);
%! assert(gen.kappa,  2.5977, 1e-4);
%! assert(gen.f(E),  gen.a .* sqrt(E) .* exp(-(E/gen.b) .^ gen.kappa), 1e-14);
