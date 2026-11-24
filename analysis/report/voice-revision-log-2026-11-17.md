# Voice Revision Log: report.Rmd
*2026-11-17 17:21 PST*

This pass revised the manuscript's prose into the `/use_rgtvoice`
voice. It used the stricter version of the 'Short, simple
sentences' rule: one idea per sentence, a target of 15 to 20 words,
a ceiling of 25, subordinate clauses split into separate sentences
with plain connectives, and common words preferred to Latinate
ones. No substantive claim was changed. The referee-report issues
(`referee-report-2026-11-17.md`) were deliberately not fixed in this
pass. Nothing was staged, committed, or rendered.

## Scope

There were 25 Edit operations covering about 30 prose paragraphs.
These were in the Introduction (all subsections), the Methods prose
(Data generating model lead-in, Parameter values closing sentence,
Analytic methods lead-in, Simulation procedure), the Results prose
(Headline findings, Type I error, Random slopes), the Discussion
(all five paragraphs), the Future research items 1 to 6, and Data
and code availability.

## Kinds of change

- **Sentence splitting.** Sentences over about 25 words were split
  at clause boundaries. The split was signaled with plain
  connectives ('However,', 'As a result,', 'This means', 'That
  is,'). All hedges and qualifiers were kept.
- **Plain diction.** Examples: 'demonstrated' became 'showed',
  'consume' became 'use up', 'exhibit' became 'is', and
  'incorporate' became 'include' or 'enter'.
- **Register.** In the 'What does "random" actually mean here?'
  subsection, 'pretend trials' became 'simulated trials', 'computer
  program' became 'simulation code', and 'Picture a trial' became
  'To illustrate, consider a trial'. 'We think' became 'In our
  view'.
- **Voice signatures, used sparingly.** These were one rhetorical
  question ('But what kind of quantity is $\alpha_i$?'), one bridge
  ('In symbols,') before each of the two model equations, and one
  added 'Unfortunately,' before an existing limitation. The other
  'Unfortunately,' was already present.
- **Hyphenation artifact.** 'near- nominal' (a line-break artifact
  that rendered with a space) became 'near-nominal'.

## Mechanical checks (run by script against a baseline copy)

The YAML header (lines 1 to 57), every code chunk including chunk
options and figure captions, every heading line, every inline `r`
expression, every cite key, every `$...$` math span (91 of 91), and
the multiset of numeric tokens in the prose were all identical to
the baseline. A search found no em dashes and no British spellings.
'randomisation' is kept inside the verbatim ICH E9 quotation.

## Deliberately left alone

- **Abstract.** It is excluded by the skill and by the task
  instructions.
- **YAML, chunks, table and figure captions.** These were excluded
  by the task constraints. Captions sit inside chunk options.
- **Headings.** These were excluded as section structure. This
  includes 'What does "random" actually mean here?', which keeps
  its double quotes.
- **ADEMP bullet list (Methods), Parameter values list, and
  Analytic methods numbered list.** These are dense with math and
  definitions. Splitting them risked altering technical content.
  The ADEMP 'Methods' and 'Performance measures' bullets still
  contain sentences well over 25 words, plus revision-history
  wording that the referee report flags (Major 10).
- **Morris et al. (2019) ADEMP Compliance section.** This is an
  audit log, not manuscript prose. Its placement is a referee-report
  item (Major 10).
- **Conflict of interest.** It is already short and plain.
- **Claims the referee report identifies as wrong or unsupported.**
  These were rephrased for sentence length only, with their content
  unchanged. They include the K = 30 fixed-effects efficiency loss,
  the 'negative correlation' mechanism, both ICH E9 quotations, the
  CV of about 1.1, 'permuted blocks' and 'all factorial
  combinations'. Revision-history phrasing such as 'is now fit' and
  'partially addressed' was also kept. Fixing any of these is a
  separate decision.
