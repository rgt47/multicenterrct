library(tinytest)

# `analysis/scripts/sim_multicenter.R` lives outside the installed
# package (analysis/ is excluded via .Rbuildignore), so it is only
# reachable when tests are run from a source checkout, e.g. via
# `pkgload::load_all("."); tinytest::run_test_dir("inst/tinytest")`.
# Under `tinytest::test_package()` on an *installed* package the file
# will not exist, and the simulation-function checks below are
# skipped rather than failed.
sim_script <- local({
  d <- getwd()
  while (!file.exists(file.path(d, "analysis", "scripts",
                                 "sim_multicenter.R")) &&
         dirname(d) != d) {
    d <- dirname(d)
  }
  path <- file.path(d, "analysis", "scripts", "sim_multicenter.R")
  if (file.exists(path)) path else NA_character_
})

if (!is.na(sim_script)) {
  source(sim_script)

  # generate_trial_data(): balanced design allocates treatment evenly
  # within every site and produces the requested total sample size.
  set.seed(1)
  dat <- generate_trial_data(
    n_sites = 5, n_per_site = 20, balanced = TRUE,
    sigma_site = 0.2, sigma_trt_site = 0, true_trt = 0.3, sigma_e = 1
  )
  expect_equal(nrow(dat), 100,
    info = "balanced design: 5 sites x 20 per site")
  site_trt_counts <- tapply(dat$trt, dat$site, sum)
  expect_true(all(site_trt_counts == 10),
    info = "treatment balanced 10/10 within each site under balanced design")

  # generate_trial_data(): imbalanced site sizes still respect the
  # n_i >= 4 floor.
  set.seed(2)
  dat_imb <- generate_trial_data(
    n_sites = 8, n_per_site = 20, balanced = FALSE,
    sigma_site = 0.2, sigma_trt_site = 0, true_trt = 0.3, sigma_e = 1
  )
  site_n <- table(dat_imb$site)
  expect_true(all(site_n >= 4),
    info = "imbalanced site sizes floored at 4")

  # fit_methods(): one row per analytic method, with the diagnostic
  # columns (df, singular, conv_warning) added during the 2026-08
  # revision present on every row.
  set.seed(3)
  dat3 <- generate_trial_data(
    n_sites = 6, n_per_site = 15, balanced = TRUE,
    sigma_site = 0.1, sigma_trt_site = 0, true_trt = 0.3, sigma_e = 1
  )
  fit3 <- fit_methods(dat3)
  expect_equal(nrow(fit3), 4, info = "one row per analytic method")
  expect_true(all(c("method", "est", "se", "pval", "df", "singular",
                     "conv_warning") %in% names(fit3)),
    info = "fit_methods() returns df/singular/conv_warning diagnostics")
  expect_equal(sort(fit3$method),
    sort(c("ignore_site", "fixed_site", "random_site",
           "random_slope")))

  # fit_methods(): the random-site `singular` flag is a determinate
  # logical (not silently NA) whenever the model converges -- this is
  # the diagnostic that replaced the earlier behavior of silently
  # treating every non-error `lmer` warning as ordinary convergence.
  set.seed(4)
  dat_null_var <- generate_trial_data(
    n_sites = 10, n_per_site = 20, balanced = TRUE,
    sigma_site = 0, sigma_trt_site = 0, true_trt = 0.3, sigma_e = 1
  )
  fit_null_var <- fit_methods(dat_null_var)
  random_row <- fit_null_var[fit_null_var$method == "random_site", ]
  expect_true(
    is.logical(random_row$singular) && !is.na(random_row$singular),
    info = "singular is a determinate logical for a converged random-site fit"
  )

  # fit_methods(): `singular` actually discriminates, rather than
  # being a determinate flag that happens to always read the same
  # value. Rates, not single draws, because REML's boundary behavior
  # is itself stochastic even when the true variance component is
  # exactly zero -- empirically calibrated (see review notes) so the
  # gap between the two rates is large relative to sampling noise at
  # these repetition counts.
  singular_rate_over <- function(n_sites, n_per_site, sigma_site, n_rep) {
    mean(vapply(seq_len(n_rep), function(i) {
      dat <- generate_trial_data(
        n_sites = n_sites, n_per_site = n_per_site, balanced = TRUE,
        sigma_site = sigma_site, sigma_trt_site = 0,
        true_trt = 0.3, sigma_e = 1
      )
      f <- fit_methods(dat)
      f$singular[f$method == "random_site"]
    }, logical(1)))
  }

  set.seed(5)
  rate_zero_var <- singular_rate_over(
    n_sites = 4, n_per_site = 20, sigma_site = 0, n_rep = 40
  )
  expect_true(rate_zero_var > 0.25,
    info = paste(
      "singular fits are common (rate", round(rate_zero_var, 2),
      "> 0.25 over 40 reps) when the true site variance is zero and",
      "there are few sites"
    ))

  set.seed(6)
  rate_high_var <- singular_rate_over(
    n_sites = 30, n_per_site = 20, sigma_site = sqrt(0.50), n_rep = 40
  )
  expect_true(rate_high_var < 0.10,
    info = paste(
      "singular fits are rare (rate", round(rate_high_var, 2),
      "< 0.10 over 40 reps) when the true site variance is large and",
      "there are many sites"
    ))

  # summarize_simulation(): closed-form checks on a small synthetic
  # input where the answer can be verified by hand, independent of
  # `run_simulation()`.
  synth <- tibble::tibble(
    scenario = "synthetic", method = "ignore_site",
    est = rep(0.30, 4), se = rep(0.10, 4), pval = rep(0.01, 4),
    df = rep(96, 4), df_between = NA_real_, df_fallback = FALSE,
    singular = rep(FALSE, 4), conv_warning = rep(FALSE, 4),
    cond_target = rep(0.30, 4), true_trt = rep(0.30, 4)
  )
  summ <- summarize_simulation(synth)
  expect_equal(summ$bias, 0, tolerance = 1e-8,
    info = "zero bias when every estimate equals the true value")
  expect_equal(summ$empirical_se, 0, tolerance = 1e-8,
    info = "zero empirical SE when every estimate is identical")
  expect_equal(summ$power, 1,
    info = "power = 1 when every p-value is below 0.05")
  expect_equal(summ$mcse_power, 0,
    info = "MCSE(power) = 0 when power is exactly 0 or 1")
  expect_equal(summ$n_converged, 4L)
  expect_equal(summ$convergence_rate, 1)

  # summarize_simulation(): coverage and its MCSE match the
  # closed-form sqrt(p(1-p)/n) formula (Morris et al. 2019, Table 6)
  # on a constructed case where exactly 3 of 4 t-based CIs cover the
  # true value.
  synth2 <- tibble::tibble(
    scenario = "synthetic2", method = "ignore_site",
    est = c(0.30, 0.30, 0.30, 10.0), se = rep(0.10, 4),
    pval = rep(0.01, 4), df = rep(96, 4), df_between = rep(9, 4),
    df_fallback = FALSE, singular = rep(FALSE, 4),
    conv_warning = rep(FALSE, 4), cond_target = rep(0.50, 4),
    true_trt = rep(0.30, 4)
  )
  summ2 <- summarize_simulation(synth2)
  expect_equal(summ2$coverage, 0.75,
    info = "coverage = fraction of replications whose t-based CI contains true_trt")
  expected_mcse <- sqrt(0.75 * 0.25 / 4)
  expect_equal(summ2$mcse_coverage, expected_mcse, tolerance = 1e-8,
    info = "mcse_coverage matches the closed-form sqrt(p(1-p)/n) formula")
  # With se = 0.1 and df = 96 the half-width is about 0.199, so
  # est = 0.30 misses cond_target = 0.50. With df = 9 it is about
  # 0.226, so the K - 1 interval covers 0.50.
  expect_equal(summ2$coverage_cond, 0,
    info = "coverage_cond is evaluated against cond_target, not true_trt")
  expect_equal(summ2$bias_cond, mean(synth2$est - 0.50),
    info = "bias_cond is the mean of est - cond_target")
  expect_equal(summ2$coverage_km1, 0.75,
    info = "coverage_km1 uses the df_between column")
  expect_true(summ2$mean_ci_width > 2 * 1.98 * 0.1,
    info = "mean CI width uses the t quantile with the per-row df")

  # build_scenarios(): the grid's first 24 rows are the ones whose
  # RNG states are stored in derived_data/rng_states.rds; the six
  # null interaction rows are appended after them.
  sc <- build_scenarios()
  expect_equal(nrow(sc), 30L, info = "30 scenarios in the grid")
  expect_true(all(sc$true_trt[25:30] == 0 & sc$sigma_trt_site[25:30] > 0),
    info = "null interaction scenarios are appended last")
  expect_identical(anyDuplicated(sc$label), 0L,
    info = "scenario labels are unique")
  expect_true(all(sc$balanced == !grepl("_(imbal|imb)$", sc$label)),
    info = "label suffix agrees with the balanced column")

  # pair_balance_scenarios(): every imbalanced scenario is labeled
  # Imbalanced (the regex defect in the original fig-imbalance chunk
  # labeled `_imbal` as Balanced because 'imbal' ends in 'bal'), and
  # every retained base has exactly one balanced and one imbalanced
  # member.
  bp <- pair_balance_scenarios(sc)
  expect_true(all(bp$balance[grepl("imb", bp$scenario)] == "Imbalanced"),
    info = "_imbal and _imb scenarios are classified Imbalanced")
  expect_true(all(bp$balance[!grepl("imb", bp$scenario)] == "Balanced"),
    info = "_bal and _int scenarios are classified Balanced")
  expect_true(all(table(bp$base) == 2),
    info = "each retained base pairs one balanced and one imbalanced")
  expect_identical(
    bp$base[bp$scenario == "K10_hiVar_int_imb"],
    bp$base[bp$scenario == "K10_hiVar_int"],
    info = "_int_imb pairs with its _int counterpart")
  expect_true(!("K10_noVar_bal" %in% bp$scenario),
    info = "unpaired scenarios are dropped")

  # generate_trial_data(): the conditional target equals true_trt
  # when there is no treatment-by-site interaction, and lies in the
  # range of the realized site effects otherwise.
  set.seed(7)
  d0 <- generate_trial_data(10, 20, FALSE, 0.3, 0, 0.3, 1)
  expect_equal(attr(d0, "cond_target"), 0.3, tolerance = 1e-12,
    info = "cond_target = true_trt when sigma_trt_site = 0")
  set.seed(8)
  d1 <- generate_trial_data(10, 20, TRUE, 0.3, 0.2, 0.3, 1)
  expect_true(is.finite(attr(d1, "cond_target")) &&
                attr(d1, "cond_target") != 0.3,
    info = "cond_target varies with the realized interaction effects")
  set.seed(8)
  rnorm(10); rnorm(10)
  invisible(lapply(rep(20, 10), function(n) sample(rep(0:1, length.out = n))))
  rnorm(200)
  rng_manual <- .Random.seed
  set.seed(8)
  invisible(generate_trial_data(10, 20, TRUE, 0.3, 0.2, 0.3, 1))
  expect_identical(.Random.seed, rng_manual,
    info = "generate_trial_data() consumes only the original RNG draws")

  # fit_methods(): mixed models use Satterthwaite df, which lies
  # between K - 1 and N - 2 here, and report K - 1 as df_between.
  set.seed(9)
  d2 <- generate_trial_data(10, 20, TRUE, sqrt(0.5), 0.2, 0.3, 1)
  f2 <- fit_methods(d2)
  rs <- f2[f2$method == "random_slope", ]
  expect_equal(rs$df_between, 9, info = "df_between = K - 1")
  expect_false(any(f2$df_fallback),
    info = "Satterthwaite df computed, not the naive fallback")
  expect_true(rs$df >= 1 && rs$df <= nrow(d2) - 2,
    info = "Satterthwaite df within [1, N - 2]")
  expect_equal(rs$pval, 2 * pt(-abs(rs$est / rs$se), rs$df),
    tolerance = 1e-12, info = "p-value uses the reported df")
  expect_true(all(f2$df[f2$method %in% c("ignore_site", "fixed_site")] ==
                    c(198, 189)),
    info = "OLS methods keep residual df")
} else {
  expect_true(TRUE,
    info = paste(
      "analysis/scripts/sim_multicenter.R not found (expected under",
      "R CMD check on the installed package, since analysis/ is",
      "excluded via .Rbuildignore); simulation-function tests skipped"
    ))
}
