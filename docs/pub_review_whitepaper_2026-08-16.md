# Referee Review: Statistical Issues in Multicenter Randomized Clinical Trials

*Review date: 2026-08-16 16:07 PDT*

This white paper is an update to the referee-style review of
`analysis/report/report.Rmd` ("Statistical Issues in Multicenter
Randomized Clinical Trials," R. G. Thomas). Three prior dated
versions exist: `docs/pub_review_whitepaper_2026-08-13.md`,
which found seven major and eight minor issues (verdict: major
revision, later same-day superseded pending independent re-review),
and `docs/pub_review_whitepaper_2026-08-14.md`, which independently
re-verified that remediation, found one new major presentation issue
(M1, an Introduction/Discussion redundancy) and several minor issues,
and recorded a same-day follow-up in which the author resolved all
open items, added a fourth analytic method (random slopes) as a new
Results subsection and Table 3, and revised verdict language toward
minor revision. The 2026-08-14 document was read in full before this
review, and its Revision History is carried forward at the end of
this document.

Since the 2026-08-14 13:07 PDT follow-up entry, the repository shows
one further content commit (`c480252`, already covered by that
follow-up entry) and one cosmetic commit (`9c49deb`, 2026-08-15,
verified by `git diff`: YAML front-matter reformatting, a `bookdown`
output-format switch already reflected in the reviewed text, a
margin/line-spacing change, and removal of a hand-written render
timestamp footer in favor of the `tools/render.sh` stamp, consistent
with this project's own house rule that `stamp.tex` owns provenance).
No prose, table, or figure content changed in that commit. This
review therefore treats the manuscript content as unchanged since the
2026-08-14 follow-up and independently re-verifies it from scratch,
rather than trusting the prior remediation log, per the standing
instructions for this review series.

This review finds one confirmed regression (a stale ADEMP appendix
claim that now contradicts the paper's own Results and Future
Research sections, reopening a variant of the 2026-08-13 review's M2
finding), one previously unreported figure/caption mismatch, and one
correction to the prior review's own diagnostic method: the
2026-08-14 review's minor finding m1 (a citation-colon spacing
artifact) was based on `pdftotext -layout` output and does not
reproduce when the rendered PDF page is inspected visually; the
"fix" applied for it, while harmless, targeted a defect that was not
actually present in the rendered document. No new correctness defects
affecting the simulation's numerical results were found; the
numerical claims in the headline findings, Table 1, Table 2, and
Table 3 were independently re-derived from the rendered table values
and matched the prose to the reported precision (verified by direct
arithmetic on the rendered PDF table entries, not by re-executing the
simulation).

## 1. Summary of the work under review

The manuscript is a Monte Carlo simulation study of four interrelated
questions in multicenter RCT analysis: how to model site effects
(ignore, fixed, random), the consequences of failing to adjust for
the site stratification variable, treatment-by-site interaction, and
the impact of imbalanced site sizes. The design crosses 24 scenarios
(16 under a true alternative $\delta = 0.30$, 8 under a true null
$\delta = 0$, the null arm omitting the interaction conditions), each
replicated $R = 1{,}500$ times, analyzed by three primary methods
(ignore site, fixed site effects, random site effects) plus, for the
six treatment-by-site-interaction scenarios specifically, a fourth
method (random slopes) reported in a dedicated Results subsection and
Table 3. Every performance measure is reported with its Morris,
White, and Crowther (2019) Table 6 Monte Carlo standard error. The
Introduction includes an extended subsection, "What does 'random'
actually mean here?," written in accessible prose for a statistically
literate, non-specialist reader, that lays out a genuine disagreement
in the published literature over why site should be treated as
random (a superpopulation-sampling argument versus a design-based
argument) and states the paper's own position. The Discussion,
Future Research, and a self-administered ADEMP compliance appendix
(updated against the original 2026-04-17 Morris audit) close out the
document, along with Data and Code Availability and Conflict of
Interest sections. This remains a single-manuscript repository; there
is no coherence-across-reports assessment to perform.

## 2. Major issues

**M1 (new/regression). The ADEMP self-audit appendix's "Still open"
item directly contradicts the paper's own Results, Future Research,
and Discussion sections regarding the random-slopes model.**
*Location: `report.Rmd:1312-1319` ("Morris et al. (2019) ADEMP
Compliance," "Still open") versus `report.Rmd:946-1022` (Results,
"Random slopes under treatment-by-site interaction," and Table 3),
`report.Rmd:1173-1185` (Future Research, item 1, labeled "partially
addressed"), and the abstract (`report.Rmd:26-30`, which reports the
random-slopes coverage and singular-fit trade-off as a headline
finding).* Inspected directly, and independently confirmed in the
rendered PDF (page 14, section "Morris et al. (2019) ADEMP
Compliance"): the "Still open" bullet reads, verbatim, "The
random-effects model fitted throughout includes only a random
intercept; Future research item 1 (a random-slopes extension) has
not yet been implemented, so the treatment-by-site-interaction
scenarios are analyzed by a specification the paper's own Discussion
and Limitations sections describe as misspecified for that
generating mechanism." This is false as of the current source: a
random-slopes method (Method 4 in "Analytic methods") is implemented
in `sim_multicenter.R::fit_methods()`, fit on every replicate, and
reported in a dedicated Results subsection and Table 3 for exactly
the six treatment-by-site-interaction scenarios, with the abstract
itself citing the random-slopes coverage gain and singular-fit rate
as one of the paper's contributions. This is precisely the category
of defect the 2026-08-13 review's M2 finding addressed (a stale
ADEMP appendix reporting an outdated status) and that the 2026-08-14
review confirmed resolved; the bullet regressed when the
random-slopes feature was added in commit `c480252` without a
corresponding update to this one appendix line. A referee reading the
paper's own self-audit appendix, which exists specifically to give a
reviewer a trustworthy checklist of what is and is not done, would
reasonably conclude the random-slopes work described three sections
earlier does not exist, or would flag the document as internally
inconsistent and unreliable as a compliance statement. **Remediation:**
move this bullet from "Still open" to "Resolved since the original
2026-04-17 audit," rewritten to state what was actually implemented
(a random-slopes method, reported for the six interaction scenarios
in Table 3) and to carry forward the genuinely still-open residual
scope (the null-hypothesis arm does not cover the random-slopes
method, and the $K$/$\sigma^2_\alpha$/balance factorial grid used for
the random-intercept comparison has not been extended to the
random-slopes method), which is already correctly stated in Future
Research item 1 and the Discussion's Limitations paragraph. This is a
five-minute fix but a real one; an ADEMP appendix that a referee
cannot trust undermines the credibility of the entire self-audit
exercise, not just this one line.

## 3. Minor issues

**m1 (new). Figure 2's caption claims a reference line that is not
drawn in the power panel.** *Location: `report.Rmd:779-828` (chunk
`fig-power`), caption text at line 779.* Inspected the chunk code and
independently confirmed by rendering the figure and viewing it (not
merely extracting text): the caption reads "Dashed lines indicate the
nominal 5% significance level (power panel) and 95% coverage target,"
but only the coverage panel (`p2`) contains a `geom_hline()` call (at
`yintercept = 0.95`); the power panel (`p1`) has no `geom_hline()`
call anywhere in its construction, and the rendered figure (verified
visually, page 10) shows no dashed reference line of any kind in the
left (power) panel. A "nominal 5% significance level" does not, in
any case, correspond to a natural horizontal reference line on a
power axis (power is not $\alpha$); this reads as boilerplate
carried over from an earlier draft of the caption that was never
matched to the code, or as a placeholder for a line that was
intended but never added. **Remediation:** either add the intended
reference (there is no obviously correct one for a power axis; a
horizontal line at the target power, if one exists, would need to be
introduced and justified), or, more simply, correct the caption to
describe only what the figure shows: "Dashed line indicates the 95%
coverage target (right panel)."

**m2 (correction to prior review, not a live defect). The 2026-08-14
review's finding m1 (citation-colon spacing) does not reproduce on
visual inspection of the rendered PDF and was likely a
`pdftotext`-extraction artifact rather than a real typographic
defect.** *Location: the passage in question,
`report.Rmd:1068-1070` ("...confirm the findings of Kahan and Morris
[@kahanImproperAnalysisTrials2012a]: when randomization is
stratified..."), renders on PDF page 14.* Verified: `pdftotext
-layout` on the current PDF still reports an apparent space before
the colon ("Kahan and Morris$^{11}$ :"), and the same spacing pattern
recurs at essentially every citation-adjacent punctuation mark
throughout the document (confirmed by `grep` across the extracted
text: commas, periods, and colons following a superscript citation
number all show the same apparent gap in `pdftotext` output,
including passages the 2026-08-14 review did not flag, e.g., page 2,
"findings$^{1,2}$ ."). However, rendering pages 2, 13, and 14 to PNG
at 150 dpi and inspecting them directly shows no visible extra space
around any of these citation marks; the kerning is tight in every
case checked. This indicates the apparent gap is an artifact of how
`pdftotext -layout` positions extracted characters around superscript
glyphs, not a feature of the typeset page. Practical consequence:
the 2026-08-14 review's remediation for this item (renaming the
citation from a bracket-only form to an explicit "Kahan and Morris
[@key]" form) was applied to a defect that, on the evidence gathered
in this review, was never visually present, though the change itself
is harmless and arguably improves readability regardless. The
methodological lesson for future review passes in this series:
`pdftotext -layout` is not a reliable instrument for detecting
sub-word typographic spacing; claims of this kind should be checked
against a rendered page image, not text extraction, before being
reported as a defect requiring remediation. **Remediation:** none
required for the manuscript. This entry is recorded so that the
2026-08-14 review's m1 is not silently dropped without explanation,
and so a future reviewer does not re-flag the same non-issue from
`pdftotext` output.

**m3 (carried forward, apparently still open, not independently
re-verified this round). Zotero reference-management hygiene.**
*Location: `analysis/report/zotero-sync/missing-references-for-zotero-import.bib`.*
Inspected: this file lists 16 of the manuscript's 24 bibliography
entries as absent from the linked Zotero collection. This is a
repository/reference-management housekeeping matter, not a defect in
the manuscript's citations themselves (all 24 entries are present
and resolve correctly in `references.bib`, and citation rendering was
checked above), so it is not scored as affecting submission
readiness, but it is noted because an incomplete Zotero sync
increases the risk of citation drift on a future edit.

## 4. What remains to be done

**(a) Required for correctness**

1. Fix the ADEMP appendix's false "Still open" claim about the
   random-slopes model (M1). This is a correctness item, not merely
   presentation: a false compliance claim in a self-audit appendix is
   a factual error about the paper's own content, and a referee who
   catches it (as this review did) will discount the reliability of
   the rest of the self-audit.

**(b) Required for acceptance at a statistical journal**

2. Correct or remove the false reference-line claim in Figure 2's
   caption (m1).
3. Extend the null-hypothesis arm to cover the treatment-by-site-
   interaction conditions under the random-slopes method, and extend
   the random-slopes comparison to the full $K$/$\sigma^2_\alpha$/
   balance factorial grid rather than the current six-scenario
   subset (Future Research item 1's own stated remaining scope;
   carried forward, unchanged since 2026-08-14).
4. Commit to the pedagogical/tutorial framing recommended in Section
   5 below (carried forward from both prior reviews, not yet acted
   on): retitle, rewrite the abstract's opening to lead with the
   practitioner decision, and move granular citation-by-citation
   literature detail to supplementary material.
5. Substitute a Kenward-Roger or Satterthwaite denominator-degrees-
   of-freedom correction (via `lmerTest`) for the current naive
   $N$-minus-fixed-effects approximation used for both mixed-model
   methods' $p$-values and CIs, and evaluate it across the same
   scenario grid (Future Research item 4; carried forward, unchanged).

**(c) Desirable polish**

6. Resync the Zotero collection referenced by
   `zotero-sync/missing-references-for-zotero-import.bib` (m3).
7. A full copyedit pass remains warranted; this review, like the
   2026-08-14 review, did not attempt a line-by-line style pass
   beyond the specific items flagged above.
8. Consider auditing the remaining figure captions (Figures 1 and 3)
   against their generating code with the same visual-versus-code
   cross-check applied to Figure 2 in this review, since that check
   surfaced a real mismatch the source-only reading in the prior
   review did not catch.

## 5. Recommended framing

Unchanged from the 2026-08-14 review, carried forward without
modification; nothing in this round's findings bears on the framing
question.

**(a) Plausible framings.** (i) methodological simulation study
(clinical-trials-methods journal); (ii) pedagogical/tutorial
synthesis aimed at practicing trialists; (iii) software/tools
contribution built around the ADEMP-audited simulation harness.

**(b) Recommendation: framing (ii), pedagogical/tutorial synthesis.**
The qualitative findings substantially replicate Chu et al. (2011)
and Kahan and Morris (2013), so framing (i) invites a referee
comparison the paper is not positioned to win on novelty grounds; the
genuine new contribution (the random-slopes coverage/singular-fit
trade-off, and the joint tracking of convergence versus singularity
as distinct outcomes) is real but narrow, and reads more naturally as
one worked example within a broader practitioner-facing synthesis
than as the centerpiece of a methods paper. The Introduction's
existing accessible-register subsection is direct evidence the author
is already inclined toward framing (ii).

**(c) Implications of the recommended framing.** *Title:* e.g., "A
Unified Simulation-Based Guide to Site-Effect Modeling Choices in
Multicenter RCTs." *Abstract/Introduction:* revise the abstract's
current methodological-register opening ("We report a factorial
Monte Carlo simulation...") to open with the practitioner decision,
matching the Introduction subsection's voice. *Comparators:*
completing the null-arm extension and full factorial grid for the
random-slopes method (item 3 above) is the one place this framing
still needs a method the paper does not yet fully have. *De-emphasize/
move to supplement:* the four per-issue literature subsections in the
Introduction.

## 6. Assessment

**Verdict: minor revision, unchanged from the 2026-08-14 review's
revised verdict, but not yet ready for acceptance.** The single
confirmed regression (M1, the ADEMP appendix's false "Still open"
claim) is narrowly scoped and inexpensive to fix, but it is a
correctness-level defect, not a stylistic one: it is a factually
false statement about the paper's own content in a section whose
entire purpose is a trustworthy self-audit, and a referee who spot-
checks it (as this review did) will reasonably question what else
in the self-audit is stale. The new figure-caption mismatch (m1,
minor) is a small but real polish item that a careful referee's
figure-by-figure read would catch. The correction to the prior
review's own m1 finding (m2 here) does not change the paper's
required-work list, but it does mean one item on the 2026-08-14
review's "resolved" list was resolved against a diagnosis that,
on closer inspection with a more reliable method, appears to have
been a false alarm; this is recorded for the epistemic record, not as
grounds for revising the verdict. The random-slopes model's own
scope limitation (null arm and full factorial grid not yet extended
to it) remains an open, disclosed limitation rather than a hidden
defect, and continues to be the substantive item standing between
this manuscript and a "required for acceptance" checklist with
nothing outstanding. This review did not re-execute the simulation
(the $R = 1{,}500 \times 24$-scenario, up to 4-method computation);
all numerical claims checked in this review (headline findings,
Table 1, Table 2, Table 3, and the abstract's summary statistics)
were independently re-derived by direct arithmetic on the values
printed in the rendered PDF and matched the prose to the reported
precision, which is a check of internal consistency between text and
table, not an independent recomputation from raw simulation output.

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
- 2026-08-14: Independent re-review. Re-verified from scratch, not by
  trusting the 2026-08-13 remediation log: all seven major issues
  confirmed resolved by direct re-inspection of source, re-execution
  of the test suite (15/15 passing), and re-reading of the rendered
  PDF text. New material since 2026-08-13 (an expanded Introduction
  subsection on the fixed-versus-random-effects justification debate,
  citing two newly added references, and a repository-wide narrative-
  citation rendering fix) was reviewed for the first time. One new
  major issue found: the new Introduction subsection and an existing
  Discussion paragraph present the same literature debate twice, in
  two different registers (M1, new) -- a presentation defect, not a
  correctness defect. One new minor typographic artifact found (m1,
  new: citation-colon spacing). One minor completeness gap found (m2,
  new: no computational-environment disclosure). Two minor items
  carried forward unresolved from the report's own ADEMP appendix
  (m3, m4: singular-fit test coverage, RNG state persistence). The
  random-slopes model and the recommended framing shift both remained
  open. Overall verdict revised from major revision to minor revision.
- 2026-08-14 (same-day follow-up, 13:07 PDT): All items from Section 4
  of that review were addressed. M1 (Introduction/Discussion
  redundancy) resolved by deleting the Discussion's full restatement
  and replacing it with a one-sentence cross-reference. m1
  (citation-colon spacing) "resolved" by naming the authors explicitly
  and moving the citation into a bracket (this review, see m2 below,
  found the underlying defect likely never existed in the rendered
  PDF). m2 (no computational-environment disclosure) resolved by
  adding an R/`lme4`-version and `renv.lock`/`renv::restore()` pointer
  to Data and Code Availability. m3 (singular-fit test coverage)
  resolved by adding two tests discriminating a high-singularity
  configuration from a near-zero-singularity one by rate. m4 (RNG
  state persistence) resolved: `run_simulation()` gained an
  `rng_state_path` argument and now writes per-replicate states to
  `analysis/data/derived_data/rng_states.rds`. A random-slopes model
  (Method 4) was implemented and reported in a new Results subsection
  and Table 3 for the six treatment-by-site-interaction scenarios; a
  units bug and an interpretive mischaracterization introduced during
  that work were caught and fixed before the entry was written. Test
  suite reported as 17/17. The recommended framing shift remained the
  one open item, an editorial decision left to the author.
- 2026-08-16: Independent re-review (this document). Confirmed via
  `git diff` that the only commit since the 2026-08-14 13:07 follow-up
  is a cosmetic YAML/front-matter change with no prose, table, or
  figure content changes; the manuscript content was therefore
  re-verified from scratch against the same content covered by that
  follow-up entry, not against new material. Test suite re-run and
  confirmed passing (17/17, verified by execution). Found one
  confirmed regression: the ADEMP appendix's "Still open" bullet
  falsely claims the random-slopes model has not been implemented,
  directly contradicting the Results, Future Research, and abstract
  sections of the same document (M1, new/regression, a variant of the
  2026-08-13 review's M2 finding that reopened when the random-slopes
  feature was added without updating this one appendix line). Found
  one new minor issue: Figure 2's caption claims a dashed reference
  line for "the nominal 5% significance level" in the power panel that
  does not exist in the figure's code or its rendered output (m1,
  new; found by cross-checking the figure's ggplot code against a
  rendered page image, a check not performed by the prior review).
  Corrected one item from the prior review: the 2026-08-14 review's
  m1 finding (citation-colon spacing) was based on `pdftotext -layout`
  extraction and does not reproduce when the rendered PDF page is
  inspected visually at 150 dpi; the underlying defect likely never
  existed, and the remediation applied for it, while harmless, was not
  necessary (m2, recorded as a correction, not a live defect). All
  numerical claims in the headline findings and Tables 1-3 were
  independently re-derived from the rendered PDF table values and
  matched the prose. Overall verdict unchanged at minor revision,
  reflecting that the one confirmed regression and one new minor issue
  are both narrowly scoped and inexpensive to remediate, while the
  substantive open item (random-slopes null-arm and full-grid
  extension) and the framing decision remain exactly where the
  2026-08-14 review left them.
