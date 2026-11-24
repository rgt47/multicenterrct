#' Simulation: Statistical Issues in Multicenter RCTs
#'
#' Compares analytic methods (ignore site, fixed site effects,
#' random site effects) across scenarios varying:
#'   - number of sites (few vs many)
#'   - site-level variance (none, moderate, large)
#'   - treatment-by-site interaction (none vs present)
#'   - balanced vs imbalanced site sizes
#'
#' @param n_sim Number of simulation replications
#' @param scenarios A tibble of scenario parameters
#' @return A tibble with performance metrics per scenario/method

library(lme4)
# Satterthwaite df for the mixed models come from lmerTest. Without it,
# summarize_mixed() would fall back to naive df for every fit, which
# would silently contradict the Methods text, so stop early instead.
if (!requireNamespace("lmerTest", quietly = TRUE)) {
  stop("Package 'lmerTest' is required for Satterthwaite df.")
}

#' Scenario grid used by report.Rmd
#'
#' The 16 alternative-hypothesis rows come first, then the null rows.
#' The six null rows with treatment-by-site interaction are appended
#' last. Appending them keeps the RNG stream, and so the generated
#' data, of every earlier scenario unchanged.
#'
#' @return A tibble with one row per scenario.
build_scenarios <- function() {
  tibble::tribble(
    ~label, ~n_sites, ~n_per_site, ~balanced,
    ~sigma_site, ~sigma_trt_site, ~true_trt, ~sigma_e,
    "K10_noVar_bal",     10, 20, TRUE,  0.0, 0.0, 0.3, 1,
    "K10_modVar_bal",    10, 20, TRUE,  sqrt(0.10), 0.0, 0.3, 1,
    "K10_hiVar_bal",     10, 20, TRUE,  sqrt(0.50), 0.0, 0.3, 1,
    "K10_modVar_imbal",  10, 20, FALSE, sqrt(0.10), 0.0, 0.3, 1,
    "K10_hiVar_imbal",   10, 20, FALSE, sqrt(0.50), 0.0, 0.3, 1,
    "K10_modVar_int",    10, 20, TRUE,  sqrt(0.10), 0.2, 0.3, 1,
    "K10_hiVar_int",     10, 20, TRUE,  sqrt(0.50), 0.2, 0.3, 1,
    "K10_hiVar_int_imb", 10, 20, FALSE, sqrt(0.50), 0.2, 0.3, 1,
    "K30_noVar_bal",     30, 20, TRUE,  0.0, 0.0, 0.3, 1,
    "K30_modVar_bal",    30, 20, TRUE,  sqrt(0.10), 0.0, 0.3, 1,
    "K30_hiVar_bal",     30, 20, TRUE,  sqrt(0.50), 0.0, 0.3, 1,
    "K30_modVar_imbal",  30, 20, FALSE, sqrt(0.10), 0.0, 0.3, 1,
    "K30_hiVar_imbal",   30, 20, FALSE, sqrt(0.50), 0.0, 0.3, 1,
    "K30_modVar_int",    30, 20, TRUE,  sqrt(0.10), 0.2, 0.3, 1,
    "K30_hiVar_int",     30, 20, TRUE,  sqrt(0.50), 0.2, 0.3, 1,
    "K30_hiVar_int_imb", 30, 20, FALSE, sqrt(0.50), 0.2, 0.3, 1,
    "H0_K10_noVar_bal",    10, 20, TRUE,  0.0, 0.0, 0.0, 1,
    "H0_K10_modVar_bal",   10, 20, TRUE,  sqrt(0.10), 0.0, 0.0, 1,
    "H0_K10_hiVar_bal",    10, 20, TRUE,  sqrt(0.50), 0.0, 0.0, 1,
    "H0_K10_hiVar_imbal",  10, 20, FALSE, sqrt(0.50), 0.0, 0.0, 1,
    "H0_K30_noVar_bal",    30, 20, TRUE,  0.0, 0.0, 0.0, 1,
    "H0_K30_modVar_bal",   30, 20, TRUE,  sqrt(0.10), 0.0, 0.0, 1,
    "H0_K30_hiVar_bal",    30, 20, TRUE,  sqrt(0.50), 0.0, 0.0, 1,
    "H0_K30_hiVar_imbal",  30, 20, FALSE, sqrt(0.50), 0.0, 0.0, 1,
    "H0_K10_modVar_int",    10, 20, TRUE,  sqrt(0.10), 0.2, 0.0, 1,
    "H0_K10_hiVar_int",     10, 20, TRUE,  sqrt(0.50), 0.2, 0.0, 1,
    "H0_K10_hiVar_int_imb", 10, 20, FALSE, sqrt(0.50), 0.2, 0.0, 1,
    "H0_K30_modVar_int",    30, 20, TRUE,  sqrt(0.10), 0.2, 0.0, 1,
    "H0_K30_hiVar_int",     30, 20, TRUE,  sqrt(0.50), 0.2, 0.0, 1,
    "H0_K30_hiVar_int_imb", 30, 20, FALSE, sqrt(0.50), 0.2, 0.0, 1
  )
}

#' Pair balanced and imbalanced scenarios for the imbalance figure
#'
#' Balance status is read from the scenario table's `balanced`
#' column, not inferred from the label. A label-suffix regex is
#' fragile here because 'imbal' itself ends in 'bal'. Each scenario
#' is mapped to a `base` label with its balance suffix removed, so
#' `K10_hiVar_int` pairs with `K10_hiVar_int_imb`. Bases that lack
#' either a balanced or an imbalanced member are dropped.
#'
#' @param scenarios A scenario tibble with `label` and `balanced`.
#' @return A tibble with columns `scenario`, `balance`, `base`.
pair_balance_scenarios <- function(scenarios) {
  out <- tibble::tibble(
    scenario = scenarios$label,
    balance = ifelse(scenarios$balanced, "Balanced", "Imbalanced"),
    base = sub("_(bal|imbal|imb)$", "", scenarios$label)
  )
  keep <- tapply(out$balance, out$base,
                 function(b) all(c("Balanced", "Imbalanced") %in% b))
  out[out$base %in% names(keep)[keep], ]
}

generate_trial_data <- function(
  n_sites,
  n_per_site,
  balanced,
  sigma_site,
  sigma_trt_site,
  true_trt,
  sigma_e
) {
  if (balanced) {
    site_n <- rep(n_per_site, n_sites)
  } else {
    raw <- rgamma(n_sites, shape = 0.8, rate = 0.8 / n_per_site)
    raw <- pmax(round(raw), 4)
    site_n <- round(raw * (n_sites * n_per_site) / sum(raw))
    site_n <- pmax(site_n, 4)
  }

  site_id <- rep(seq_len(n_sites), times = site_n)
  n_total <- sum(site_n)

  site_effect <- rnorm(n_sites, 0, sigma_site)
  trt_site_effect <- rnorm(n_sites, 0, sigma_trt_site)

  trt <- unlist(lapply(site_n, function(n) {
    sample(rep(0:1, length.out = n))
  }))

  y <- site_effect[site_id] +
    (true_trt + trt_site_effect[site_id]) * trt +
    rnorm(n_total, 0, sigma_e)

  out <- tibble::tibble(
    site = factor(site_id),
    trt = trt,
    y = y
  )

  # Conditional target of the fixed-site estimator: the weighted mean
  # of the realized site-specific effects, with the within-site OLS
  # weights n_i1 * n_i0 / n_i. It equals true_trt when
  # sigma_trt_site = 0. Computed from values already drawn, so it does
  # not consume the RNG stream.
  n1 <- as.numeric(tapply(trt, site_id, sum))
  w <- n1 * (site_n - n1) / site_n
  attr(out, "cond_target") <- sum(w * (true_trt + trt_site_effect)) /
    sum(w)
  out
}

#' Fit an lmer model without refitting on warnings
#'
#' Warnings (for example convergence diagnostics) are muffled and the
#' fit is kept, because REML permits boundary solutions. Singularity
#' and lme4 convergence messages are read from the fitted object by
#' the caller. A hard error returns NULL (non-convergence). The fit is
#' done once; an earlier version refit the model whenever a warning
#' was raised, which doubled the cost without changing the estimate.
#'
#' @param formula Model formula.
#' @param dat Trial data.
#' @return A merMod object, or NULL on error.
fit_lmer_quiet <- function(formula, dat) {
  tryCatch(
    withCallingHandlers(
      suppressMessages(lmer(formula, data = dat, REML = TRUE)),
      warning = function(w) invokeRestart("muffleWarning")
    ),
    error = function(e) NULL
  )
}

#' Summarize the treatment coefficient of a mixed model
#'
#' The primary reference distribution is t with Satterthwaite
#' denominator df (lmerTest). If the Satterthwaite computation fails,
#' the naive N-minus-p df is used and `df_fallback` is set. The
#' between-site df, K - 1, is returned for a sensitivity analysis.
#'
#' @param m A merMod object or NULL.
#' @param method Method label.
#' @param n_sites Number of sites K.
#' @param n_obs Number of patients N.
#' @return A one-row tibble.
summarize_mixed <- function(m, method, n_sites, n_obs) {
  if (is.null(m)) {
    return(tibble::tibble(
      method = method, est = NA_real_, se = NA_real_,
      pval = NA_real_, df = NA_real_, df_between = NA_real_,
      df_fallback = NA, singular = NA, conv_warning = NA
    ))
  }
  s <- summary(m)$coefficients["trt", ]
  df_satt <- tryCatch(
    suppressMessages(suppressWarnings(
      summary(lmerTest::as_lmerModLmerTest(m))$coefficients["trt", "df"]
    )),
    error = function(e) NA_real_
  )
  df_fallback <- !is.finite(df_satt)
  df_use <- if (df_fallback) n_obs - length(fixef(m)) else df_satt
  tibble::tibble(
    method = method,
    est = s[[1]],
    se = s[[2]],
    pval = 2 * stats::pt(-abs(s[[1]] / s[[2]]), df = df_use),
    df = df_use,
    df_between = n_sites - 1,
    df_fallback = df_fallback,
    singular = lme4::isSingular(m),
    conv_warning = length(m@optinfo$conv$lme4$messages) > 0
  )
}

fit_methods <- function(dat) {
  n_sites <- nlevels(dat$site)
  n_obs <- nrow(dat)

  # Methods 1 and 2: OLS ignoring site, and OLS with fixed site
  # effects. `df` is the OLS residual df, used for both the p-value and
  # the CI half-width.
  ols_row <- function(m, method) {
    s <- summary(m)$coefficients["trt", ]
    tibble::tibble(
      method = method, est = s[[1]], se = s[[2]], pval = s[[4]],
      df = stats::df.residual(m), df_between = NA_real_,
      df_fallback = FALSE, singular = FALSE, conv_warning = FALSE
    )
  }
  m1 <- lm(y ~ trt, data = dat)
  m2 <- lm(y ~ trt + site, data = dat)

  # Method 3: random site intercept. Method 4: random intercept and
  # random treatment slope per site, the correctly specified model
  # when sigma_trt_site > 0. Both are fit on every replicate, paired
  # with Methods 1 and 2 on the same data (Morris et al. 2019, 4.2).
  m3 <- fit_lmer_quiet(y ~ trt + (1 | site), dat)
  m4 <- fit_lmer_quiet(y ~ trt + (1 + trt | site), dat)

  dplyr::bind_rows(
    ols_row(m1, "ignore_site"),
    ols_row(m2, "fixed_site"),
    summarize_mixed(m3, "random_site", n_sites, n_obs),
    summarize_mixed(m4, "random_slope", n_sites, n_obs)
  )
}

run_one_rep <- function(
  n_sites, n_per_site, balanced,
  sigma_site, sigma_trt_site,
  true_trt, sigma_e
) {
  dat <- generate_trial_data(
    n_sites, n_per_site, balanced,
    sigma_site, sigma_trt_site,
    true_trt, sigma_e
  )
  res <- fit_methods(dat)
  res$cond_target <- attr(dat, "cond_target")
  res
}

run_simulation <- function(scenarios, n_sim = 1000, rng_state_path = NULL) {
  # Morris, White, and Crowther (2019) 4.1: the RNG seed is set ONCE
  # by the caller; this function does not call set.seed(). Per-replicate
  # RNG states are captured and attached as an attribute of the return
  # value for diagnostic reproducibility of any failing rep. If
  # `rng_state_path` is supplied, the same states are also persisted to
  # disk (keyed by scenario label and replicate index), so a specific
  # failing or singular replication can be re-run in isolation by
  # restoring `.Random.seed` without re-executing the whole simulation.
  all_results <- vector("list", nrow(scenarios) * n_sim)
  rng_states <- vector("list", nrow(scenarios) * n_sim)
  rng_index <- vector("list", nrow(scenarios) * n_sim)
  idx <- 0L

  for (i in seq_len(nrow(scenarios))) {
    sc <- scenarios[i, ]
    cat(sprintf(
      "Scenario %d/%d: %s ...\n",
      i, nrow(scenarios), sc$label
    ))

    for (r in seq_len(n_sim)) {
      idx <- idx + 1L
      rng_states[[idx]] <- .Random.seed
      rng_index[[idx]] <- tibble::tibble(scenario = sc$label, rep = r)
      res <- tryCatch(
        run_one_rep(
          n_sites = sc$n_sites,
          n_per_site = sc$n_per_site,
          balanced = sc$balanced,
          sigma_site = sc$sigma_site,
          sigma_trt_site = sc$sigma_trt_site,
          true_trt = sc$true_trt,
          sigma_e = sc$sigma_e
        ),
        error = function(e) {
          tibble::tibble(
            method = c("ignore_site", "fixed_site",
                       "random_site", "random_slope"),
            est = NA_real_, se = NA_real_, pval = NA_real_,
            df = NA_real_, df_between = NA_real_, df_fallback = NA,
            singular = NA, conv_warning = NA, cond_target = NA_real_
          )
        }
      )
      res$scenario <- sc$label
      res$rep <- r
      res$true_trt <- sc$true_trt
      all_results[[idx]] <- res
    }
  }

  out <- dplyr::bind_rows(all_results)
  attr(out, "rng_states") <- rng_states

  if (!is.null(rng_state_path)) {
    dir.create(dirname(rng_state_path), recursive = TRUE,
               showWarnings = FALSE)
    saveRDS(
      list(index = dplyr::bind_rows(rng_index), states = rng_states),
      rng_state_path
    )
  }

  out
}

summarize_simulation <- function(raw) {
  # `true_trt` is read per scenario from `raw$true_trt`, because the
  # grid holds both a true_trt = 0 null arm and true_trt = 0.30
  # alternative arms.
  #
  # Morris et al. (2019) Table 6 Monte Carlo SEs for every metric.
  # Non-convergence (`n_converged`), singular fits, and lme4
  # convergence diagnostics are reported as separate outcomes.
  #
  # Coverage uses a t-based CI, `est +/- qt(0.975, df) * se`, with the
  # same per-replicate `df` used for the p-value: the OLS residual df
  # for the ignore/fixed methods, and the Satterthwaite df for the two
  # mixed models (see summarize_mixed()). `power_km1` and
  # `coverage_km1` repeat the calculation with K - 1 df for the mixed
  # models, as a sensitivity analysis. `bias_cond` and
  # `coverage_cond` evaluate each method against the conditional
  # target of the fixed-site estimator (see generate_trial_data()).
  raw |>
    dplyr::mutate(
      half = stats::qt(0.975, df) * se,
      half_km1 = stats::qt(0.975, df_between) * se,
      pval_km1 = 2 * stats::pt(-abs(est / se), df = df_between)
    ) |>
    dplyr::group_by(scenario, method) |>
    dplyr::summarize(
      n_total = dplyr::n(),
      n_converged = sum(!is.na(est)),
      convergence_rate = n_converged / n_total,
      mcse_convergence = sqrt(
        convergence_rate * (1 - convergence_rate) / n_total
      ),
      n_singular = sum(singular, na.rm = TRUE),
      singular_rate = n_singular / n_converged,
      mcse_singular_rate = sqrt(
        singular_rate * (1 - singular_rate) / n_converged
      ),
      conv_warning_rate = sum(conv_warning, na.rm = TRUE) /
        n_converged,
      df_fallback_rate = sum(df_fallback, na.rm = TRUE) / n_converged,
      mean_df = mean(df, na.rm = TRUE),
      true_trt = dplyr::first(true_trt),
      bias = mean(est, na.rm = TRUE) - true_trt,
      mcse_bias = stats::sd(est, na.rm = TRUE) / sqrt(n_converged),
      empirical_se = stats::sd(est, na.rm = TRUE),
      mcse_empirical_se = empirical_se /
        sqrt(2 * (n_converged - 1)),
      mse = mean((est - true_trt)^2, na.rm = TRUE),
      mcse_mse = sqrt(
        stats::var((est - true_trt)^2, na.rm = TRUE) / n_converged
      ),
      mean_model_se = mean(se, na.rm = TRUE),
      mcse_model_se = stats::sd(se, na.rm = TRUE) /
        sqrt(n_converged),
      mean_ci_width = mean(2 * half, na.rm = TRUE),
      power = mean(pval < 0.05, na.rm = TRUE),
      mcse_power = sqrt(power * (1 - power) / n_converged),
      coverage = mean(
        (est - half <= true_trt) & (est + half >= true_trt),
        na.rm = TRUE
      ),
      mcse_coverage = sqrt(
        coverage * (1 - coverage) / n_converged
      ),
      power_km1 = mean(pval_km1 < 0.05, na.rm = TRUE),
      coverage_km1 = mean(
        (est - half_km1 <= true_trt) & (est + half_km1 >= true_trt),
        na.rm = TRUE
      ),
      bias_cond = mean(est - cond_target, na.rm = TRUE),
      coverage_cond = mean(
        (est - half <= cond_target) & (est + half >= cond_target),
        na.rm = TRUE
      ),
      .groups = "drop"
    )
}
