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
  expect_equal(nrow(fit3), 3, info = "one row per analytic method")
  expect_true(all(c("method", "est", "se", "pval", "df", "singular",
                     "conv_warning") %in% names(fit3)),
    info = "fit_methods() returns df/singular/conv_warning diagnostics")
  expect_equal(sort(fit3$method),
    sort(c("ignore_site", "fixed_site", "random_site")))

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

  # summarize_simulation(): closed-form checks on a small synthetic
  # input where the answer can be verified by hand, independent of
  # `run_simulation()`.
  synth <- tibble::tibble(
    scenario = "synthetic", method = "ignore_site",
    est = rep(0.30, 4), se = rep(0.10, 4), pval = rep(0.01, 4),
    df = rep(96, 4), singular = rep(FALSE, 4),
    conv_warning = rep(FALSE, 4), true_trt = rep(0.30, 4)
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
    pval = rep(0.01, 4), df = rep(96, 4), singular = rep(FALSE, 4),
    conv_warning = rep(FALSE, 4), true_trt = rep(0.30, 4)
  )
  summ2 <- summarize_simulation(synth2)
  expect_equal(summ2$coverage, 0.75,
    info = "coverage = fraction of replications whose t-based CI contains true_trt")
  expected_mcse <- sqrt(0.75 * 0.25 / 4)
  expect_equal(summ2$mcse_coverage, expected_mcse, tolerance = 1e-8,
    info = "mcse_coverage matches the closed-form sqrt(p(1-p)/n) formula")
} else {
  expect_true(TRUE,
    info = paste(
      "analysis/scripts/sim_multicenter.R not found (expected under",
      "R CMD check on the installed package, since analysis/ is",
      "excluded via .Rbuildignore); simulation-function tests skipped"
    ))
}
