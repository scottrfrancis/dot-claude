# Prose Style Guidelines

**Apply these to anything written for a human reader.** Narrative prose, yes, but also knowledge-base pages, analysis documents, READMEs, ADRs, PR descriptions and commit bodies. Anywhere someone reads sentences.

**They do not apply to** code, code comments, generated data, log files, or machine-readable artefacts.

> **Why the broad scope.** Exempting "technical documentation and structured reference material" sounds reasonable and is not. One knowledge bundle written under that exemption reached **2,190 em-dashes across 56 files**, and clearing them took a multi-hour editing pass. Reference material is still read by people.

**Write to this standard the first time.** These rules exist to avoid the editing pass, not to describe it.

**Each rule names a move, and rewording the move keeps the tell.** Readers learn to recognize the move itself. A model tuned away from "it's not X, it's Y" writes "X doesn't do it. Y does." instead, and the reader who spotted the first form spots the second. An em-dash swapped for a colon is the same failure. When a rule fires, rewrite the sentence so the move is gone. Swapping the punctuation or the wording leaves it in place.

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
- **Kill the corrective frame.** "This is not a penalty, it is the other half of a bargain." State the positive and drop the negation: "This is the other half of a bargain." The frame has many disguises, listed under [The Corrective Frame](#the-corrective-frame).
- **Limit tricolons.** Three-item parallel lists (A, B, and C) are fine occasionally. More than two per piece starts sounding formulaic.
- **Use active verbs, imperative mood.** "Decompose problems" not "Decomposing problems." "Pick the right model" not "Selecting the right model." Gerund-heavy sentences read as generated outlines, not prose.
- **Be economical.** If a sentence works without a word, cut the word. Prefer short punches over compound clauses joined by commas. "API budgets are a rounding error against salaries" not "making API budgets a rounding error compared to fully-loaded engineering salaries."

## The Corrective Frame

The corrective frame raises a claim nobody made so the sentence can knock it down. It reads as insight, and it spends the reader's attention on the wrong idea first. Models were tuned away from the literal "it's not X, it's Y", and the move now arrives in other forms. A reader described it in September 2026: "now models seem to be avoiding that exact form but it shows up in a slightly different way."

| Disguise | Example |
|---|---|
| Split across two sentences | "Cost is not a property of a row. It is a property of the row's position in the window." |
| Subject swap | "Money does not stop the work. The usage window does." |
| Trailing negation | "A timestamp, not an amount." "Share a schema, not a table." |
| Fronted "not … but" | "Not what this token cost, but whether this seat is producing." |
| "Was never" | "The gap was never capability." "The question was never why. It was which." |
| Verdict pair | "Right instinct. Wrong clock." |
| Paired definitions | "Zero says measured. Null says not applicable." "Pricing asks X. Allocation asks Y." |
| Denial, then reveal | "This is not an expensive mistake. It is a cheap success I could not audit." |
| Negated heading | "## Allocation is not pricing" |
| "Easy part" setup | "Those are easy fixes. This one is not." |
| "The real X" | "The real cost is headroom." "The money is in the nodes you were never offered." |

**The test is to delete the negated half.** If the sentence still tells the reader everything they need, the negated half was a strawman, so leave it deleted. Keep a contrast only when this audience actually holds the rejected view, and then say who holds it: "Most token dashboards report dollars. On a subscription, the limit that stops work is the five-hour cap."

Headings state what the section establishes. One corrective frame in a piece is a choice. Two in adjacent paragraphs, or more than one per 500 words, is a habit.

Candidate finder. It over-matches, so read each hit:

```bash
grep -nE "\b(not|never|isn't|wasn't|aren't|doesn't|don't)\b[^.]*\. (It|This|That|The [a-z]+) (is|was|does|did)\b|, not (a |an |the )?[a-z]+|\bNot [^.]*, but\b|\bwas never\b|\brather than\b|^#+ .*\bis not\b" FILE
```

## Plain Register

Technical readers come for the information. Dramatic staging makes them wait for it and then asks them to admire the delivery. Write the way you would explain the work to a colleague at a whiteboard.

- **The epigram kicker.** A paragraph that closes on a quotable metaphor restating itself: "a rumor with a schema", "It is a metronome." The paragraph already made the point. Cut the line, or, if it really is the thesis, say it literally and move it to the front of the paragraph.
- **The staged reveal.** A one-sentence paragraph held back for effect: "The second does everything right." Fold it into the paragraph it belongs to. Allow one single-sentence paragraph per piece at most.
- **Verbless fragment runs.** "Components kept, total derived, provenance retained." "Two components, one workspace, no join." Write the sentence, with its verb.
- **Personified data.** "A notional figure walks into a margin conversation." "The ledger asserts precision." Name the person and the action: "Whoever builds the margin report will read it as a real charge."
- **Stakes inflation.** "Forever", "nobody", "every", "the only", "confidently wrong". Check each absolute against the evidence. Most become a count, a qualifier, or nothing.
- **The drumbeat close.** Two short imperatives to finish: "Build the gauge. Then reconcile it." End on the last useful instruction, stated once, in an ordinary sentence.

The test is to read the sentence aloud to that colleague. If you would not say it that way, write it the way you would.

## Concrete Nouns

Some abstract nouns sound precise and point at nothing. Models lean on a short list of them, and a reader who notices one starts counting. The watch list: *edge, surface, layer, shape, axis, space, lens, seam, spine, primitive, load-bearing, unlock, leverage, friction, signal*, and the stand-ins *the thing, the move, the story, the question, the point, the line, the far side*.

Each one stands in for a noun the writer did not name. Name it.

| Abstract | Concrete |
|---|---|
| "take the cheapest edge into the claim" | "run the cheapest check that can prove the claim" |
| "building around it puts you on the wrong axis" | "a cost column is empty for most of this ledger" |
| "which work sat on the far side" | "which jobs ran after the allowance ran out" |
| "the doctrine failed to travel" | "the other project never got the script" |

Technical terms keep their technical meaning. A graph edge in a piece that defines the graph, an edge device, and an edge case are all fine, because the reader can point at the thing. A technical word repeated through a piece still turns into a verbal tic. Past three uses of any word on the list, replace some of them with the object they refer to.

Candidate counter:

```bash
grep -oiwE "edges?|surfaces?|layers?|shape|axis|lens|seams?|spine|primitives?|load-bearing|unlock|leverage|friction|signal" FILE | sort | uniq -c | sort -rn
```

## Transitions and Connective Tissue

- **Cut throat-clearing.** Delete sentences that exist only to announce what you're about to say: "This should not surprise anyone," "It's worth noting that," "The implication is clear."
- **Avoid hedging formulas.** "It depends on where you sit," "regardless of which X you prefer," "the broader point stands" all signal AI equivocation. Take a position or cut the sentence.
- **Earn your transitions.** "But," "However," "That said" are fine when they mark a genuine turn. If the next paragraph continues the same argument, drop the contrastive opener.
- **Don't summarize before concluding.** The conclusion should advance the argument, not restate it. If your final paragraph could serve as an abstract, rewrite it.

## Word Choice

- **Prefer concrete over abstract.** "Subscription seats replacing headcount requisitions" is better than "a fundamental shift in resource allocation paradigms." The abstract nouns models favor are listed under [Concrete Nouns](#concrete-nouns).
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

## Self-Impeaching Hedges

**Never announce the virtue you are currently exercising.** "I'd rather be straightforward," "to be
honest," "let me be clear," "candidly," "I want to be upfront with you," "full transparency" — each
one implies the default is otherwise. **The phrase impeaches the writer it was meant to reassure.**

| Cut | Keep |
|---|---|
| "I'd rather be straightforward about where this sits" | "Linda and I are reviewing this weekend." |
| "To be honest, the hours don't work" | "The hours don't work." |
| "Let me be clear:" | The claim |
| "I want to be upfront that I haven't decided" | "I haven't decided." |
| "I'm not raising this as a bargaining point" | Nothing. The content says what it is |

**The test: delete the clause and read the sentence.** If it says the same thing, the clause was
doing nothing but characterising the speaker. **A straightforward person writes the fact and stops.**

**The same applies to explaining yourself.** "I did not want to write as though it were settled" is
the writer narrating their own good intentions. State the position; the reader infers the intent.

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
8. **Delete the negated half of every contrast**, headings included. If nothing is lost, leave it deleted. Run the candidate finder above.
9. **Read the last sentence of each paragraph.** If it restates the paragraph as a quotable metaphor, cut it.
10. **Count the watch-list nouns.** For each one, could the reader point at the thing it names? If not, name the thing.
