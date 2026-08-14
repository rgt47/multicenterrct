# Referee Review: Statistical Issues in Multicenter Randomized Clinical Trials

*Review date: 2026-08-14 11:52 PDT*

This white paper is an update to the referee-style review of
`analysis/report/report.Rmd` ("Statistical Issues in Multicenter
Randomized Clinical Trials," R. G. Thomas) first conducted on
2026-08-13. The most recent prior version,
`docs/pub_review_whitepaper_2026-08-13.md`, was read in full before
this review; its Revision History is carried forward at the end of
this document. All seven major issues (M1-M7) and eight minor issues
(m1-m8) from that review were addressed in a same-day remediation
pass, and the present review independently re-verifies that
remediation from scratch — re-inspecting the current source, re-running
the test suite, and re-checking the rendered PDF text directly, rather
than trusting the prior review's own remediation log. It also covers
substantial new material added since 2026-08-13: an expanded
Introduction subsection on the fixed-versus-random-effects framing
debate (citing two newly added references, Falissard and Chavance 1996
and Edgar, Roberts, and Sharples 2021), and a repository-wide fix to a
citation-rendering defect. This review finds that new material
introduces one referee-worthy presentation problem, detailed in
Major Issue 1 below, and one small formatting artifact, detailed in
Minor Issue 1. No new correctness defects were found.

## 1. Summary of the work under review

The manuscript remains a Monte Carlo simulation study of four
interrelated questions in multicenter RCT analysis: modeling site
effects, adjusting for the site stratification variable,
treatment-by-site interaction, and imbalanced site sizes, now
extended with an abstract, a formal Type I error analysis under a
null-hypothesis scenario arm, and singular/boundary-fit disclosure
for the random-effects method. The paper now has 24 scenarios total
(16 under the true alternative $\delta = 0.30$, 8 under the null
$\delta = 0$, the null arm omitting the interaction conditions), each
replicated $R = 1{,}500$ times, analyzed by three methods (ignore
site, fixed site effects, random site effects), with every
performance measure reported alongside its Morris et al. (2019) Table
6 Monte Carlo standard error. The Introduction has grown a substantial
new subsection, "What does 'random' actually mean here?," written in
plain, low-jargon prose aimed at a statistically literate but
non-specialist (physician) reader, walking through the fixed-versus-
random distinction with the data-generating equation and then
presenting a genuine disagreement in the published literature over
*why* an analyst should treat site as random (a literal superpopulation-
sampling assumption, per Falissard and Chavance 1996, versus a
design-based, randomization-stratification argument that needs no such
assumption, per Kahan and Morris 2012/2013 and Edgar, Roberts, and
Sharples 2021). The paper now includes Data and Code Availability and
Conflict of Interest sections, and its ADEMP self-audit appendix has
been rewritten to state the current, accurate status of each item
against the original 2026-04-17 audit rather than the stale status
reported in the 2026-08-13 review's M2 finding.

## 2. Major issues

All seven major issues from the 2026-08-13 review (M1-M7) were
independently re-verified as resolved during this pass; see the
Revision History for a per-item summary of that re-verification. One
new major issue was identified.

**M1 (new). The site-effects-justification debate is presented twice,
in full, in two different registers, producing a presentation-level
inconsistency a referee would require resolved before acceptance.**
*Location: `report.Rmd:232-282` (Introduction, "Two different reasons
statisticians give for treating site as random") and
`report.Rmd:915-950` (Discussion, the unlabeled caveat paragraph
following "Modeling site effects").* Inspected directly: both passages
cover the same three sources (Falissard and Chavance 1996; Kahan and
Morris 2012/2013; Edgar, Roberts, and Sharples 2021), make the same
two-camp argument (superpopulation-sampling justification versus
design-based justification), and reach the same conclusion (the two
camps disagree on the reason but agree on the recommendation), each in
roughly 150 words. The Introduction passage is written in short,
plain sentences with minimal jargon ("Picture a trial run at ten
hospitals..."); the Discussion passage restates the identical content
in dense academic register ("a premise essentially never satisfied in
practice," "an argument that requires no claim about how sites were
sampled"). This is not merely repetitive; it is a register
inconsistency within a single manuscript. A referee reading the
Introduction would reasonably expect a paper written for a
statistically literate, non-specialist audience; a referee reading
the Discussion's restatement of the same material would reasonably
expect a paper written for a methodologist audience. No single target
journal is well served by switching registers to reargue the same
point twice. This finding directly reinforces, rather than
contradicts, the framing recommendation carried forward from the
2026-08-13 review (§5 below): the presence of accessible,
physician-facing content is evidence the author is already leaning
toward a pedagogical framing, and the fix for M1 is to commit to that
choice rather than hedge with a second, technical-register copy.
**Remediation:** keep the full treatment in one location (the
Introduction subsection is the better home, since it already carries
the necessary math and citations and is written for the audience the
recommended framing targets) and replace the Discussion paragraph with
a single cross-referencing sentence, e.g., "The recommendation above
rests on a design-based justification that does not require sites to
be a literal random sample of a larger population; see Introduction,
'Two different reasons statisticians give for treating site as
random,' for the two competing justifications in the literature."

## 3. Minor issues

**m1 (new). A citation immediately followed by a colon produces a
stray-space typographic artifact.** *Location: `report.Rmd:957`,
Discussion, "Failure to adjust for stratification."* Verified in the
rendered PDF (`pdftotext -layout`): "...confirm the findings of¹¹ :
when randomization is stratified by center..." — a visible space
appears between the citation superscript and the following colon.
This is not the grammar-breaking narrative-citation defect fixed
throughout the rest of the document (this citation functions as the
object of a preposition, not as a sentence's missing subject, so the
sentence still parses), but it is a visible formatting blemish this
document's own citation-style CSL produces whenever a bare `@key`
citation directly precedes punctuation other than a period or comma.
It is the one citation in the document with this exact adjacency;
`grep` for `@[a-zA-Z0-9]*:` in `report.Rmd` returns only this line.
**Remediation:** name the authors explicitly and move the citation
into a bracket, matching the pattern used everywhere else in this
document since the prior review's citation-bug fix, e.g., "...confirm
the findings of Kahan and Morris [@kahanImproperAnalysisTrials2012a]:
when randomization is stratified by center..."

**m2 (new). The Data and Code Availability section does not disclose
the computational environment.** *Location: `report.Rmd:1080-1089`.*
Inspected: the section states the simulation is "fully reproducible
from the fixed seed and RNG kind" but names no R version, no `lme4`
(or other package) version, and does not reference the repository's
own `renv.lock`, which exists at the repository root and pins exact
package versions. `lme4`'s optimizer and convergence-warning behavior
(directly relevant to the singular/boundary-fit diagnostics this paper
now reports as a headline result) can change across package versions,
so a seed and RNG kind alone do not guarantee another reader
reproduces the same singular-fit rates. **Remediation:** add one
sentence naming the R version and key package versions (or simply
pointing to `renv.lock` and stating that `renv::restore()` recreates
the exact environment used), consistent with what a referee would
expect from the "hardware/software disclosure" component of adequate
empirical-evidence reporting.

**m3 (carried forward, still open). No unit test discriminates a
definitively non-singular fit from a singular one.** *Location:
`inst/tinytest/test_basic.R:64-78`.* Verified by re-reading and
re-running the test suite (15/15 passing): the existing test checks
only that `singular` is a determinate, non-`NA` logical for a fit
generated under $\sigma^2_\alpha = 0$ (a scenario expected to be
frequently, not necessarily always, singular); it does not construct
a case expected to converge to a strictly interior solution and assert
`singular == FALSE` there, nor a case virtually guaranteed singular and
assert `singular == TRUE`. The gap was already flagged as "Still
open" in the report's own ADEMP appendix (`report.Rmd:1158-1162`) and
remains unaddressed. **Remediation:** add two tests: one with a large
true $\sigma^2_\alpha$ and many sites, expected to converge to an
interior solution with high probability, asserting `singular ==
FALSE`; one with $\sigma^2_\alpha = 0$ and few observations per site,
asserting `singular == TRUE` with high probability (or asserting the
rate over several seeds exceeds a threshold, to avoid test flakiness
from a single-seed coin flip).

**m4 (carried forward, still open). RNG states are captured only in
memory, not persisted to disk.** *Location:
`analysis/scripts/sim_multicenter.R:167-215`, `run_simulation()`.*
Inspected: `rng_states` is attached as an in-memory attribute of the
function's return value but is never written to
`analysis/data/derived_data/rng_states.rds` as recommended in the
original 2026-04-17 Morris audit's remediation plan and acknowledged
as still open in the report's own ADEMP appendix. Without a
persisted copy, a specific failing or singular replication discovered
after a knit session has ended cannot be re-run in isolation without
re-executing the full simulation from the start of that scenario.
**Remediation:** write `rng_states` to a sidecar `.rds` file keyed by
scenario label and replicate index at the end of `run_simulation()`,
or accept and document this as a deliberate scope limitation given the
in-memory capture already satisfies same-session reproducibility.

## 4. What remains to be done

**(a) Required for correctness**

No items remain in this category. All items in this category from the
2026-08-13 review (singular-fit tracking, null-hypothesis arm,
p-value/coverage consistency, MCSE arithmetic, fresh render, MCSE
display, ADEMP appendix accuracy) were independently re-verified as
resolved during this review.

**(b) Required for acceptance at a statistical journal**

1. Resolve the Introduction/Discussion redundancy and register
   inconsistency (M1, new).
2. Commit to the pedagogical/tutorial framing recommended in §5 below
   (carried forward, not yet acted on): retitle, rewrite the
   abstract's opening to lead with the practitioner decision rather
   than a general topic statement, and move the most granular
   citation-by-citation literature detail to supplementary material.
   This resolves M1 more durably than a local edit alone, since it
   settles which register the whole paper should use.
3. Implement the random-slopes model for the treatment-by-site-
   interaction scenarios (Future research item 1; carried forward).
   The paper's own Discussion and Limitations sections already state
   that the current random-intercept fit is misspecified for the
   generating mechanism used in the interaction scenarios; this is a
   disclosed limitation, not a hidden defect, but it remains a gap a
   journal referee would ask to see closed, or at minimum would ask
   whether the interaction scenarios should be reframed as
   illustrating the consequence of misspecification rather than as a
   fair evaluation of the random-intercept method.
4. Add computational-environment disclosure to Data and Code
   Availability (m2, new).
5. Strengthen singular-fit unit test coverage (m3, carried forward).
6. Persist RNG states to disk, or explicitly scope this out (m4,
   carried forward).

**(c) Desirable polish**

7. Fix the citation-colon spacing artifact (m1, new).
8. A full copyedit pass is warranted given the volume of new prose
   added since 2026-08-13; this review did not attempt a
   line-by-line style pass beyond the specific items above.

## 5. Recommended framing

Unchanged in substance from the 2026-08-13 review, with one update:
the new physician-facing Introduction subsection is itself evidence
supporting the recommendation, not merely consistent with it, and its
existence should be treated as the author having already begun the
transition.

**(a) Plausible framings.** (i) methodological simulation study
(clinical-trials-methods journal); (ii) pedagogical/tutorial synthesis
aimed at practicing trialists; (iii) software/tools contribution built
around the ADEMP-audited simulation harness.

**(b) Recommendation: framing (ii), pedagogical/tutorial synthesis.**
The reasoning from the prior review stands: the qualitative findings
substantially replicate Chu et al. (2011) and Islam and Bangdiwala
(2024), so framing (i) would draw a referee comparison the paper is
not currently positioned to win. What has changed since 2026-08-13 is
that the paper now contains direct evidence of the author's own
inclination toward framing (ii) — the new Introduction subsection is
written exactly the way a tutorial aimed at trialists should be
written. The remaining work is to make that choice consistently
throughout, rather than leaving one subsection in tutorial voice and
the rest, including the Discussion's duplicate treatment of the same
argument (M1), in methodologist voice.

**(c) Implications of the recommended framing, updated.** *Title:*
unchanged recommendation, e.g., "A Unified Simulation-Based Guide to
Site-Effect Modeling Choices in Multicenter RCTs." *Abstract/
Introduction:* the current abstract (added since 2026-08-13) is
written in standard methodological-abstract register ("We report a
factorial Monte Carlo simulation...") and should be revised to open
with the practitioner decision, consistent with the new Introduction
subsection's voice, once the framing is adopted. *Comparators:*
completing the random-slopes model (item 3 above) remains the one
place this framing still needs a method the paper does not yet have.
*De-emphasize/move to supplement:* the four per-issue literature
subsections in the Introduction, and, once M1 is resolved, whichever
of the two site-effects-justification passages is not retained.

## 6. Assessment

**Verdict: minor revision.** This is a material change from the
2026-08-13 review's "major revision" verdict, and is justified: every
correctness-level defect identified in that review (M1-M7) was
independently re-verified as resolved in this pass — re-rendered PDF
confirmed newer than source (verified via file mtime, `report.tex`
2026-08-14 11:39 against `report.Rmd` 2026-08-14 11:23), test suite
re-run and passing 15/15 (verified by execution, not inspection), MCSE
columns confirmed present in the rendered table text, Type I error
results confirmed present with values in a sane range around the
nominal 0.05, and no stray "Table 3" cross-references remain anywhere
in the source (verified by `grep`). The one new major issue (M1, new)
is a presentation defect, not a correctness defect, and has a
narrowly scoped, low-risk remediation (delete one redundant paragraph,
add one cross-reference sentence). The remaining open items (random
slopes, RNG persistence, singular-fit test coverage, environment
disclosure) are all either explicitly disclosed limitations already
or straightforward additions, none of which threaten the validity of
the results currently reported. This review did not re-execute the
full $R = 1{,}500 \times 24$-scenario $\times$ 3-method simulation
itself (the knitr cache, keyed on the MD5 hash of
`sim_multicenter.R` per the fix verified in this pass, was inspected
for consistency with the rendered output rather than forced to
recompute); the specific numeric values in Table 1 and Table 2 are
therefore verified-by-execution (the pipeline ran and produced them,
confirmed via the rendered PDF text) rather than independently
recomputed by this review from raw data.

## 7. Revision history

- 2026-08-13: Initial review. Seven major issues identified (M1-M7:
  stale PDF, stale ADEMP appendix, silently absorbed singular fits,
  no null-hypothesis arm, MCSE arithmetic error, p-value/coverage
  reference-distribution mismatch, MCSE claimed but not displayed).
  Eight minor issues identified. Recommended framing: pedagogical/
  tutorial synthesis over methods-novelty framing. Overall verdict:
  major revision.
- 2026-08-13 (same-day follow-up): All seven major and eight minor
  issues resolved and verified against a re-rendered PDF. Simulation
  code gained singular-fit tracking, consistent t-based inference, and
  a null-hypothesis arm; report gained an abstract, Type I error
  results, availability/COI sections, corrected arithmetic, and an
  updated ADEMP self-audit; tests gained real coverage. Framing shift
  not acted on. Verdict language noted as superseded pending a fresh
  independent pass.
- 2026-08-14: Independent re-review (this document). Re-verified from
  scratch, not by trusting the 2026-08-13 remediation log: all seven
  major issues confirmed resolved by direct re-inspection of source,
  re-execution of the test suite (15/15 passing), and re-reading of
  the rendered PDF text. New material since 2026-08-13 (an expanded
  Introduction subsection on the fixed-versus-random-effects
  justification debate, citing two newly added references, and a
  repository-wide narrative-citation rendering fix) was reviewed for
  the first time. One new major issue found: the new Introduction
  subsection and an existing Discussion paragraph present the same
  literature debate twice, in two different registers (M1, new) — a
  presentation defect, not a correctness defect. One new minor
  typographic artifact found (m1, new: citation-colon spacing). Two
  new minor completeness gaps found (m2, new: no computational-
  environment disclosure). Two minor items carried forward unresolved
  from the report's own ADEMP appendix (m3, m4: singular-fit test
  coverage, RNG state persistence). The random-slopes model and the
  recommended framing shift both remain open, unchanged from
  2026-08-13. Overall verdict revised from major revision to **minor
  revision**, reflecting genuine, independently verified progress on
  every correctness-level finding from the prior review.
