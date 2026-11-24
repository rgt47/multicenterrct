# Morris et al. (2019) ADEMP Audit: 07-multicenter-rct
*2026-04-17 09:02 PDT*

## Scope

Files audited:

- `analysis/scripts/sim_multicenter.R`
- `analysis/report/report.Rmd`
- `R/` package utilities, where present

## ADEMP scorecard

| Criterion | Status | Evidence |
|---|---|---|
| Aims explicit | Partial | `report.Rmd` lists study goals in prose; no ADEMP header |
| DGMs documented | Met | `sim_multicenter.R` parameterises site count, site sd, and n per site |
| Factors varied factorially | Partial | scenario grid present; not formally labelled as factorial |
| Estimand defined with true value | Met | treatment effect parameter is an input to the DGM |
| Methods justified | Met | competing methods (fixed-site, random-site, meta-analytic) listed |
| Performance measures justified | Partial | bias, emp SE, coverage, power listed but without explicit tie to aims |
| n_sim stated | Met | `report.Rmd:286` specifies `R = 1500` |
| n_sim justified via MCSE | Not met | no Monte Carlo SE target calculation supporting R = 1500 |
| MCSE reported per metric | Not met | `summarize_simulation()` in `sim_multicenter.R:176-192` returns point estimates only |
| Seed set once | Met | single `set.seed()` at script entry |
| RNG states stored | Not met | no per-replicate `.Random.seed` capture |
| Paired comparisons | Partial | same data fed to all methods within a rep, but `filter(!is.na(est))` silently drops non-converged reps, breaking pairing on the dropped rows |
| Reproducibility | Partial | seed present; `RNGkind("L'Ecuyer-CMRG")` not pinned |

## Overall verdict

**Partially compliant.**

## Gaps

- No Monte Carlo SE on any performance estimate (`sim_multicenter.R:176-192`).
- `R = 1500` fixed without MCSE derivation (`report.Rmd:286`).
- `filter(!is.na(est))` in summarisation silently drops `lmer`
  non-convergence reps, which (a) breaks paired comparisons across methods
  and (b) treats convergence failure as missing-at-random — an implicit
  assumption Morris §5.1 warns against.
- No per-replicate `.Random.seed` snapshot stored, so a specific failing
  repetition cannot be re-run to diagnose.
- `RNGkind()` not pinned — exact reproducibility fragile across R versions.

## Remediation plan

1. Add `mcse_*` columns to `summarize_simulation()` in
   `sim_multicenter.R:176-192`: `mcse_bias = sd(est) / sqrt(n_rep)`,
   `mcse_emp_se = emp_se / sqrt(2 * (n_rep - 1))`,
   `mcse_coverage = sqrt(coverage * (1 - coverage) / n_rep)`,
   `mcse_power = sqrt(power * (1 - power) / n_rep)`.
2. Replace the `filter(!is.na(est))` collapse with an explicit
   `convergence_rate` column; report this as an additional performance
   measure per Morris §5.1 (non-convergence as a first-class outcome).
3. Add an n_sim justification block at the top of `sim_multicenter.R`
   deriving R from a target MCSE (e.g., coverage MCSE ≤ 0.6 pp at 95%
   requires R ≥ 1584).
4. Pin `RNGkind("L'Ecuyer-CMRG")` immediately before `set.seed()`.
5. Store `.Random.seed` per replicate to a sidecar RDS
   (`analysis/data/derived_data/rng_states.rds`) keyed by scenario and
   replicate index.
6. In `report.Rmd`, add an explicit ADEMP-structured Methods section
   with an n_sim justification paragraph and a reference to Morris Table
   6 for the performance-measure formulae.

## References

Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate
statistical methods. Stat Med 2019;38:2074-2102. doi:10.1002/sim.8086

## Update: 2026-08-13

Following a referee-style review (`docs/pub_review_whitepaper_2026-08-13.md`),
`analysis/scripts/sim_multicenter.R` and `analysis/report/report.Rmd` were
revised. Status against the original scorecard above:

- MCSE reported per metric — **Met** (was Not met). Added to
  `summarize_simulation()` and displayed in Table 1/Table 3 of the report.
- n_sim justified via MCSE — **Met** (was Not met). Corrected arithmetic
  error in the report's derivation (the original text claimed R >= 1584 for
  MCSE <= 0.6pp; the correct threshold is R >= 1320).
- RNG states stored — **Partial** (was Not met). Captured in memory via
  `run_simulation()`'s `rng_states` attribute; not yet persisted to a
  sidecar RDS file on disk.
- Reproducibility (RNGkind pinned) — **Met** (was Partial).
- Paired comparisons — **Met** (was Partial). Non-convergence no longer
  drops rows; all three methods' rows are retained per replication.

New items identified during the 2026-08 review that were not part of the
original ADEMP scorecard:

- `fit_methods()` was silently treating singular/boundary `lmer` fits
  (warning-only, not error) as ordinary convergence. Verified empirically:
  53% of `lmer` fits were singular in a true-zero-site-variance scenario,
  none previously flagged. Fixed by adding explicit `singular` and
  `conv_warning` outcome columns.
- The p-value's ad hoc `df_naive` (previously misleadingly named `df_kr`,
  suggesting a Kenward-Roger correction that was never implemented) was
  inconsistent with the CI's fixed z = 1.96 half-width. Both now use the
  same per-method degrees of freedom.
- No null-hypothesis (delta = 0) scenario existed, so the study could not
  support a Type I error claim despite engaging literature centrally
  concerned with Type I error under stratified randomization. A reduced
  null-arm scenario subset (8 of the 16 alternative scenarios, omitting
  the interaction conditions) was added.

See `docs/pub_review_whitepaper_2026-08-13.md` for the full review and
`docs/pub_review_whitepaper_2026-08-13.md`'s Revision History entry, to be
updated after re-rendering, for confirmation that the fixes were verified
against a fresh simulation run.

## Update: 2026-11-17

The ADEMP compliance section below was removed from
`analysis/report/report.Rmd` in response to the 2026-11-17 referee
report (`analysis/report/referee-report-2026-11-17.md`, Major 10),
which judged it lab-notebook content rather than manuscript content.
It is preserved here verbatim as it stood in the manuscript, followed
by a status note for the 2026-11-17 remediation.

### Section as removed from report.Rmd

### Morris et al. (2019) ADEMP Compliance

We audited this simulation study against the reporting
standards proposed by Morris, White, and Crowther
[-@morris2019using]. The original audit is recorded at
`docs/morris-audit-2026-04-17.md`. A status update following
the 2026-08 revision described below is appended to that file.

**Verdict:** Partially compliant (updated).

**Resolved since the original 2026-04-17 audit:**

- Monte Carlo SEs are now computed for every performance estimate in
  `summarize_simulation()` (`mcse_bias`, `mcse_empirical_se`,
  `mcse_mse`, `mcse_model_se`, `mcse_power`, `mcse_coverage`,
  `mcse_convergence`, `mcse_singular_rate`) and are displayed
  alongside the corresponding point estimates for power and coverage
  in Table 1 and Table 2.
- `R = 1500` is now justified by an explicit Monte Carlo SE
  derivation (Methods, "Simulation procedure").
- Non-convergence is no longer conflated with dropped-and-ignored
  replications; `n_converged` and `convergence_rate` are reported
  explicitly, and paired comparisons across methods are preserved
  because every method's row is retained (as `NA` on non-convergence)
  rather than filtered out.
- `RNGkind("L'Ecuyer-CMRG")` is pinned immediately before the single
  `set.seed()` call.
- Per-replicate `.Random.seed` values are captured by
  `run_simulation()`, attached as the `rng_states` attribute of its
  return value, and persisted to
  `analysis/data/derived_data/rng_states.rds` (keyed by scenario label
  and replicate index), so a specific failing or singular replication
  from a completed run can be re-run in isolation via
  `with_rng_state()`-style `.Random.seed` restoration without
  re-executing the whole simulation up to that point.
- A random-slopes method (Method 4 in "Analytic methods") is now
  implemented in `sim_multicenter.R::fit_methods()`, fit on every
  replicate, and reported in a dedicated Results subsection
  ("Random slopes under treatment-by-site interaction") and Table 3
  for the six treatment-by-site-interaction scenarios, with the
  coverage gain and singular-fit rate reported in the abstract.

**Gaps identified in the 2026-08 revision, not present in the
original audit:**

- Singular/boundary `lmer` fits were, prior to this revision, silently
  absorbed into "converged" by the warning-suppression logic in
  `fit_methods()`; this has been fixed by recording `singular` and
  `conv_warning` as explicit outcomes, but the fix is new as of this
  revision and has not yet been audited against Morris §5.1 on a
  wider scenario set than the one simulated here.
- Coverage previously used a fixed $z = 1.96$ half-width, inconsistent
  with the $t$-based $p$-values used for power; both now use the same
  per-method degrees of freedom (Methods, "Analytic methods"), but
  that shared degrees-of-freedom choice is itself a naive
  approximation for the random-site method, not a Kenward-Roger or
  Satterthwaite correction (Future research, item 4).
- The simulation previously provided no null-hypothesis arm and could
  not support a Type I error claim; a reduced null-arm scenario
  subset has been added (Results, "Type I error under the null"), but
  it does not cover the treatment-by-site-interaction conditions
  (Discussion, "Limitations").

**Still open:**

- The random-slopes method (Method 4) is reported only for the six
  treatment-by-site-interaction scenarios under the true alternative;
  the null-hypothesis arm does not yet cover the random-slopes
  method, and the $K$/$\sigma^2_\alpha$/balance factorial grid used
  for the random-intercept comparison has not been extended to the
  random-slopes method (Future research, item 1; Discussion,
  "Limitations").

### Status after the 2026-11-17 remediation

- The two mixed models now use Satterthwaite denominator df
  (`lmerTest`), with a K - 1 df sensitivity analysis, replacing the
  naive N-minus-p df. The naive df is kept only as a fallback when
  the Satterthwaite computation fails (`df_fallback`).
- The null-hypothesis arm now includes the six treatment-by-site
  interaction cells, so Type I error of the random-slopes method is
  assessed. These rows are appended at the end of the scenario grid,
  so the RNG stream of the original 24 scenarios is unchanged.
- Each replicate records the conditional target of the fixed-site
  estimator (`cond_target`), and `summarize_simulation()` reports
  `bias_cond` and `coverage_cond` against it.
- Still open: the K / sigma_alpha^2 / balance grid has not been
  extended to small centers, many sites, or low ICC, and the
  random-slopes comparison has not been extended to the full grid.
- The manuscript has not been re-rendered since these changes; see
  `analysis/report/referee-remediation-log-2026-11-17.md`.

---
*Source: ~/prj/res/07-multicenter-rct/multicenterrct/docs/morris-audit-2026-04-17.md*
