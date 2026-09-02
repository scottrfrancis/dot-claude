# Prose Style Guidelines

**Apply these to anything written for a human reader.** Narrative prose, yes, but also knowledge-base pages, analysis documents, READMEs, ADRs, PR descriptions and commit bodies. Anywhere someone reads sentences.

**They do not apply to** code, code comments, generated data, log files, or machine-readable artefacts.

> **Why the broad scope.** Exempting "technical documentation and structured reference material" sounds reasonable and is not. One knowledge bundle written under that exemption reached **2,190 em-dashes across 56 files**, and clearing them took a multi-hour editing pass. Reference material is still read by people.

**Write to this standard the first time.** These rules exist to avoid the editing pass, not to describe it.

## Punctuation Discipline

- **Em-dashes**: The single most reliable AI tell. **Maximum two per piece of narrative prose.**

  For longer structured documents, where a hard cap is unrealistic, use the working rule: **if a dash can be a period, colon or comma, make it one.** Reserve the dash for a genuine mid-sentence interruption, which is rare.

  **Testable threshold:** more than **one em-dash per 40 lines** means you are leaning on them. Check with `grep -o '—' FILE | wc -l` against `wc -l`.

  Three patterns to fix on sight:

  | Instead of | Write |
  |---|---|
  | `**Bold claim** — explanation` | `**Bold claim.** Explanation` |
  | `- **Term** — definition` | `- **Term.** Definition` |
  | `## Heading — subtitle` | `## Heading: subtitle` |

  A dash acting as a comma before *which*, *and*, *so*, *because* or *but* is simply a comma.
- **Semicolons**: Use sparingly. One per piece is usually sufficient. If you reach for a semicolon, consider whether two sentences would be clearer.
- **Parentheticals**: Avoid nested or lengthy parenthetical asides. If the aside matters, give it its own sentence.

## Sentence Construction

- **Vary openers.** Never start three consecutive sentences with the same word, especially "The", "This", or "It". Read the paragraph aloud as a sequence of first words; if a pattern emerges, break it.
- **Vary length.** Alternate between short declarative sentences and longer compound ones. A paragraph of uniformly mid-length sentences reads as generated.
- **Avoid symmetrical constructions.** Phrases like "deliberately X, and deliberately Y" or "not only A but also B" are AI-favored patterns. Break the symmetry. Use a period instead: "Deliberately X. Also Y."
- **Kill the "not X, it is Y" reflex.** "This is not a penalty, it is the other half of a bargain." State the positive and drop the negation: "This is the other half of a bargain." Reach for the contrast only when the reader genuinely expects X.
- **Limit tricolons.** Three-item parallel lists (A, B, and C) are fine occasionally. More than two per piece starts sounding formulaic.
- **Use active verbs, imperative mood.** "Decompose problems" not "Decomposing problems." "Pick the right model" not "Selecting the right model." Gerund-heavy sentences read as generated outlines, not prose.
- **Be economical.** If a sentence works without a word, cut the word. Prefer short punches over compound clauses joined by commas. "API budgets are a rounding error against salaries" not "making API budgets a rounding error compared to fully-loaded engineering salaries."

## Transitions and Connective Tissue

- **Cut throat-clearing.** Delete sentences that exist only to announce what you're about to say: "This should not surprise anyone," "It's worth noting that," "The implication is clear."
- **Avoid hedging formulas.** "It depends on where you sit," "regardless of which X you prefer," "the broader point stands" all signal AI equivocation. Take a position or cut the sentence.
- **Earn your transitions.** "But," "However," "That said" are fine when they mark a genuine turn. If the next paragraph continues the same argument, drop the contrastive opener.
- **Don't summarize before concluding.** The conclusion should advance the argument, not restate it. If your final paragraph could serve as an abstract, rewrite it.

## Word Choice

- **Prefer concrete over abstract.** "Subscription seats replacing headcount requisitions" is better than "a fundamental shift in resource allocation paradigms."
- **Avoid AI-favored adverbs.** "Fundamentally," "essentially," "ultimately," "importantly," "significantly". Cut these unless they carry genuine meaning. They rarely do.
- **Watch for hollow intensifiers.** "Incredibly," "extremely," "absolutely," "truly". If the noun or verb needs propping up, choose a stronger noun or verb.
- **Limit "landscape/ecosystem/paradigm" language.** These words have become AI markers. Use them only when the technical meaning is precise (e.g., "threat landscape" in security writing).
- **Cut fluff phrases.** "It's worth noting that," "in terms of," "the fact that," "a technology organization can make". These pad word count without adding meaning. Find the verb. Say it.

## State What Is, Not What Changed

**Documents describe the world, not their own editing history.** Delete every trace of how the text got here.

| Cut | Keep |
|---|---|
| "This section previously said…" | The correct statement |
| "Corrected 2026-09-02" | The corrected fact |
| "An earlier draft claimed…" | Nothing |
| "Renamed and reframed" | The current name |

**The exceptions are narrow, and they are about the world rather than the document.** Record a *decision* and who made it ("Scott's call: exit 1 April"). Record a *source* and when it was read ("from the SPD, 2026-09-02"). Record a *correction* only where someone acting on the old version would now do harm, and then put it in the changelog, errata file or commit message where history belongs.

**Bold is a spotlight, not a highlighter.** If most sentences carry bold, none of them do. Reserve it for the load-bearing figure or the claim the section exists to make. One or two per paragraph at most.

## Voice and Ownership

- **Take ownership.** "My title" not "the title." "I'll qualify" not "the title needs qualifying." First person signals the author stands behind the argument.
- **Write as the author, not a commentator.** AI defaults to observational distance ("one might argue," "it could be said"). The author is in the arena. State positions directly.
- **Avoid distancing constructions.** "What this means depends on where you sit" hedges. "Engineering leadership already knows this" takes a position.

## Structural Tells

- **Don't start with a question you immediately answer.** "What does this mean for developers? It means..." is a pattern LLMs default to. State the claim directly.
- **Avoid the "to be sure" sandwich.** Stating a counterpoint only to immediately dismiss it ("To be sure, some disagree. But...") reads as performative balance. Either engage the counterpoint seriously or omit it.
- **Lists vs. narrative.** Default to narrative prose. Use bulleted lists only for genuinely enumerable items (steps, specifications, feature comparisons). A blog post with more than one bulleted list probably needs restructuring.

## Self-Check Before Finalizing

Read the piece and ask:
1. Could I identify this as AI-written from the first paragraph? If yes, rewrite the opening.
2. Do more than two paragraphs start with the same structural pattern? If yes, vary them.
3. Is there a sentence I included only because it "sounds professional"? If yes, cut it.
4. Does the conclusion say something the introduction didn't? If not, sharpen it.
5. **Count the em-dashes.** Over one per 40 lines, or over two in an essay, go back and convert them.
6. **Search for "previously", "earlier", "corrected", "no longer".** Each hit is the document talking about itself. Delete or move it.
7. **Scan the bold.** If more than a couple of phrases per paragraph are bold, the emphasis has stopped meaning anything.
