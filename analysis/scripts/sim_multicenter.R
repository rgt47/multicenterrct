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

  # Method 1: Ignore site (simple t-test / OLS)
  m1 <- lm(y ~ trt, data = dat)
  s1 <- summary(m1)$coefficients["trt", ]
  results$ignore <- tibble::tibble(
    method = "ignore_site",
    est = s1[1],
    se = s1[2],
    pval = s1[4]
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
      pval = s2[4]
    )
  } else {
    results$fixed <- tibble::tibble(
      method = "fixed_site",
      est = NA_real_,
      se = NA_real_,
      pval = NA_real_
    )
  }

  # Method 3: Random site effects (mixed model)
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
    df_kr <- nrow(dat) - length(fixef(m3))
    pval3 <- 2 * pt(-abs(s3[1] / s3[2]), df = df_kr)
    results$random <- tibble::tibble(
      method = "random_site",
      est = s3[1],
      se = s3[2],
      pval = pval3
    )
  } else {
    results$random <- tibble::tibble(
      method = "random_site",
      est = NA_real_,
      se = NA_real_,
      pval = NA_real_
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

run_simulation <- function(scenarios, n_sim = 1000) {
  # Morris, White, and Crowther (2019) §4.1: the RNG seed is set ONCE
  # by the caller; this function does not call set.seed(). Per-replicate
  # RNG states are captured and attached as an attribute of the return
  # value for diagnostic reproducibility of any failing rep.
  all_results <- vector("list", nrow(scenarios) * n_sim)
  rng_states <- vector("list", nrow(scenarios) * n_sim)
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
                       "random_site"),
            est = NA_real_, se = NA_real_, pval = NA_real_
          )
        }
      )
      res$scenario <- sc$label
      res$rep <- r
      all_results[[idx]] <- res
    }
  }

  out <- dplyr::bind_rows(all_results)
  attr(out, "rng_states") <- rng_states
  out
}

summarize_simulation <- function(raw, true_trt) {
  # Morris et al. (2019) Table 6 Monte Carlo SEs for every metric.
  # `n_converged` is the number of reps returning a valid estimate —
  # Morris §5.1 treats non-convergence as a first-class outcome; we
  # therefore report convergence alongside the other measures rather
  # than silently dropping non-converged reps as in the previous
  # implementation.
  raw |>
    dplyr::group_by(scenario, method) |>
    dplyr::summarize(
      n_total = dplyr::n(),
      n_converged = sum(!is.na(est)),
      convergence_rate = n_converged / n_total,
      mcse_convergence = sqrt(
        convergence_rate * (1 - convergence_rate) / n_total
      ),
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
        (est - 1.96 * se <= true_trt) &
        (est + 1.96 * se >= true_trt),
        na.rm = TRUE
      ),
      mcse_coverage = sqrt(
        coverage * (1 - coverage) / n_converged
      ),
      .groups = "drop"
    )
}
