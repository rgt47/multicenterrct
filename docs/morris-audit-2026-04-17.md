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

---
*Source: ~/prj/res/07-multicenter-rct/multicenterrct/docs/morris-audit-2026-04-17.md*
