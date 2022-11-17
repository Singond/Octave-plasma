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
		r.kappa = r.gen.c;
		if (!cvg)
			warning("General fit did not converge");
		elseif (iter == 1)
			warning("General fit stopped after first iteration");
		endif
	catch err
		warning(["Failed to fit general distribution: " err.message]);
	end_try_catch
endfunction
