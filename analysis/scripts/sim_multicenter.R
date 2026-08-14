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
library(broom.mixed)

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

  tibble::tibble(
    site = factor(site_id),
    trt = trt,
    y = y
  )
}

fit_methods <- function(dat) {
  results <- list()

  # Method 1: Ignore site (simple t-test / OLS). `df` is the OLS
  # residual df, used for both the p-value (via lm's own t-test) and,
  # for consistency across all three methods below, the CI half-width.
  m1 <- lm(y ~ trt, data = dat)
  s1 <- summary(m1)$coefficients["trt", ]
  results$ignore <- tibble::tibble(
    method = "ignore_site",
    est = s1[1],
    se = s1[2],
    pval = s1[4],
    df = stats::df.residual(m1),
    singular = FALSE,
    conv_warning = FALSE
  )

  # Method 2: Fixed site effects
  n_sites <- nlevels(dat$site)
  if (n_sites <= 50) {
    m2 <- lm(y ~ trt + site, data = dat)
    s2 <- summary(m2)$coefficients["trt", ]
    results$fixed <- tibble::tibble(
      method = "fixed_site",
      est = s2[1],
      se = s2[2],
      pval = s2[4],
      df = stats::df.residual(m2),
      singular = FALSE,
      conv_warning = FALSE
    )
  } else {
    results$fixed <- tibble::tibble(
      method = "fixed_site",
      est = NA_real_,
      se = NA_real_,
      pval = NA_real_,
      df = NA_real_,
      singular = NA,
      conv_warning = NA
    )
  }

  # Method 3: Random site effects (mixed model). A genuine convergence
  # `error` is treated as non-convergence (est = NA). A `warning` (most
  # commonly a boundary/singular fit when the true site variance is
  # zero or small) does NOT imply an invalid estimate -- REML permits
  # boundary solutions -- so the model is refit with the warning
  # suppressed and the estimate is retained, but singularity and any
  # other lme4 convergence diagnostic are recorded explicitly as
  # first-class outcomes (`singular`, `conv_warning`) rather than
  # silently absorbed into an undifferentiated "converged" bucket.
  m3 <- tryCatch(
    lmer(y ~ trt + (1 | site), data = dat, REML = TRUE),
    error = function(e) NULL,
    warning = function(w) {
      suppressWarnings(
        lmer(y ~ trt + (1 | site), data = dat, REML = TRUE)
      )
    }
  )
  if (!is.null(m3)) {
    s3 <- summary(m3)$coefficients["trt", ]
    # NOTE: `df_naive` is N minus the number of fixed-effect
    # parameters. This is NOT a Kenward-Roger or Satterthwaite
    # denominator df -- it is a naive approximation used as an interim
    # reference distribution for both the p-value and the CI
    # half-width (kept internally consistent, unlike the earlier
    # implementation, which combined a t-based p-value with a z-based
    # CI). See "Future research" in report.Rmd for the planned
    # upgrade to lmerTest Satterthwaite/Kenward-Roger df.
    df_naive <- nrow(dat) - length(fixef(m3))
    pval3 <- 2 * pt(-abs(s3[1] / s3[2]), df = df_naive)
    results$random <- tibble::tibble(
      method = "random_site",
      est = s3[1],
      se = s3[2],
      pval = pval3,
      df = df_naive,
      singular = lme4::isSingular(m3),
      conv_warning = length(m3@optinfo$conv$lme4$messages) > 0
    )
  } else {
    results$random <- tibble::tibble(
      method = "random_site",
      est = NA_real_,
      se = NA_real_,
      pval = NA_real_,
      df = NA_real_,
      singular = NA,
      conv_warning = NA
    )
  }

  # Method 4: Random slopes (random intercept AND random treatment
  # slope per site). The correctly specified model under the
  # treatment-by-site-interaction data-generating mechanism
  # (report.Rmd, "Data generating model": gamma_i is a random slope),
  # unlike Method 3, which fits only a random intercept and is
  # misspecified whenever sigma_trt_site > 0. Computed for every
  # replicate (paired with the other three methods on the same
  # generated data, per Morris §4.2), but only reported for the
  # treatment-by-site-interaction scenarios (see report.Rmd, "Random
  # slopes under treatment-by-site interaction"); random-slope
  # variance components are frequently at or near the boundary when
  # the true interaction variance is zero or small, exactly as the
  # random-intercept model is for site variance, so the same
  # singular/conv_warning tracking applies.
  m4 <- tryCatch(
    lmer(y ~ trt + (1 + trt | site), data = dat, REML = TRUE),
    error = function(e) NULL,
    warning = function(w) {
      suppressWarnings(
        lmer(y ~ trt + (1 + trt | site), data = dat, REML = TRUE)
      )
    }
  )
  if (!is.null(m4)) {
    s4 <- summary(m4)$coefficients["trt", ]
    df_naive4 <- nrow(dat) - length(fixef(m4))
    pval4 <- 2 * pt(-abs(s4[1] / s4[2]), df = df_naive4)
    results$random_slope <- tibble::tibble(
      method = "random_slope",
      est = s4[1],
      se = s4[2],
      pval = pval4,
      df = df_naive4,
      singular = lme4::isSingular(m4),
      conv_warning = length(m4@optinfo$conv$lme4$messages) > 0
    )
  } else {
    results$random_slope <- tibble::tibble(
      method = "random_slope",
      est = NA_real_,
      se = NA_real_,
      pval = NA_real_,
      df = NA_real_,
      singular = NA,
      conv_warning = NA
    )
  }

  dplyr::bind_rows(results)
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
  fit_methods(dat)
}

run_simulation <- function(scenarios, n_sim = 1000, rng_state_path = NULL) {
  # Morris, White, and Crowther (2019) §4.1: the RNG seed is set ONCE
  # by the caller; this function does not call set.seed(). Per-replicate
  # RNG states are captured and attached as an attribute of the return
  # value for diagnostic reproducibility of any failing rep. If
  # `rng_state_path` is supplied, the same states are also persisted to
  # disk (keyed by scenario label and replicate index), so a specific
  # failing or singular replication can be re-run in isolation via
  # `with_rng_state()`-style `.Random.seed` restoration without
  # re-executing the whole simulation up to that point.
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
            df = NA_real_, singular = NA, conv_warning = NA
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
  # `true_trt` is read per scenario from `raw$true_trt` (attached by
  # run_simulation() from the scenario table) rather than passed as a
  # single scalar, because the scenario grid now includes a
  # true_trt = 0 null arm (for Type I error) alongside the
  # true_trt = 0.30 alternative arms; a single scalar `true_trt`
  # argument could not correctly compute bias/coverage/power for both.
  #
  # Morris et al. (2019) Table 6 Monte Carlo SEs for every metric.
  # `n_converged` is the number of reps returning a valid estimate —
  # Morris §5.1 treats non-convergence as a first-class outcome; we
  # therefore report convergence alongside the other measures rather
  # than silently dropping non-converged reps as in the previous
  # implementation. Singular (boundary) fits and other lme4
  # convergence-diagnostic warnings are likewise reported as
  # first-class outcomes among the converged reps, rather than being
  # silently folded into "converged."
  #
  # Coverage uses a t-based CI, `est +/- qt(0.975, df) * se`, with the
  # same per-replicate `df` used for the p-value (OLS residual df for
  # the ignore/fixed methods; the naive N-minus-fixed-effects df for
  # the random-site method -- see fit_methods()). This replaces a
  # fixed z = 1.96 half-width that was inconsistent with the t-based
  # p-values used for power, and that did not vary with sample size or
  # method.
  raw |>
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
      power = mean(pval < 0.05, na.rm = TRUE),
      mcse_power = sqrt(power * (1 - power) / n_converged),
      coverage = mean(
        (est - stats::qt(0.975, df) * se <= true_trt) &
        (est + stats::qt(0.975, df) * se >= true_trt),
        na.rm = TRUE
      ),
      mcse_coverage = sqrt(
        coverage * (1 - coverage) / n_converged
      ),
      .groups = "drop"
    )
}
