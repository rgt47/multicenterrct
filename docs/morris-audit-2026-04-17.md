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

---
*Source: ~/prj/res/07-multicenter-rct/multicenterrct/docs/morris-audit-2026-04-17.md*
