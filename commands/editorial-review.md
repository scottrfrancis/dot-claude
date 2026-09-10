---
description: Audit prose for AI tells and refine voice/tone. Optional style parameter.
argument-hint: [voice/style, e.g. "professional", "Hunter S. Thompson", "Scientific American", "https://example.com/reference"]
allowed-tools: Read, Edit, Write, Glob, Grep, WebFetch
---

# Editorial Review

Perform a thorough editorial review of a prose document, auditing for AI-generated writing patterns and refining toward a target voice.

## Determine the Target File

Look at recent conversation context for the file being discussed. If ambiguous, ask the user which file to review.

## Determine the Target Voice

Arguments provided: $ARGUMENTS

Interpret the argument as a voice, tone, or style directive. Examples of how to handle different inputs:

- **No argument or "professional"**: Use the default guidelines from `~/.claude/guidelines/prose-style.md`. Aim for the author's established voice as seen on https://scottrfrancis.wordpress.com — direct, technical, declarative, light on hedging.
- **Named author** (e.g., "Hunter S. Thompson", "Joan Didion", "Paul Graham"): Adopt structural and tonal characteristics of that author's nonfiction prose. Do not parody. Absorb rhythm, sentence construction preferences, and rhetorical habits.
- **Publication name** (e.g., "Scientific American", "The Economist", "MAD Magazine", "Ars Technica"): Match the publication's editorial conventions — formality level, humor tolerance, jargon density, paragraph length norms.
- **URL**: Fetch the page at the URL using WebFetch. Analyze the writing style on that page (sentence structure, tone, vocabulary level, rhetorical patterns). Use that analysis as the target voice for this review.
- **Adjective** (e.g., "cheeky", "sardonic", "formal", "conversational"): Apply that quality as a modifier on top of the base prose-style guidelines.

## Load Base Guidelines

Read `~/.claude/guidelines/prose-style.md` for the structural and mechanical checklist. These rules apply regardless of voice selection. The voice parameter adjusts *tone and style*; the guidelines govern *craft and anti-AI hygiene*.

Each rule names a move. When an earlier edit reworded a move instead of removing it, report it as the original finding: a colon standing in for an em-dash still counts, and so does "X doesn't do it. Y does." standing in for "not X but Y".

## Audit Pass

Read the target file and perform the following audit. Track findings as you go.

### 1. Mechanical Patterns (from prose-style.md)
- Count em-dashes. Flag if more than 2.
- Check for consecutive sentences starting with the same word.
- Identify symmetrical constructions ("not only X but also Y", "deliberately A, and deliberately B").
- Find the corrective frame in every disguise the guideline lists: split across two sentences, subject swap, trailing "not an X", "was never", verdict pairs, paired definitions, negated headings. Run the guideline's candidate finder, then delete the negated half of each hit. If nothing is lost, flag it.
- Run the guideline's abstract-noun counter (edge, surface, layer, shape, axis, the question, the line, load-bearing and the rest of the watch list). Flag any word used more than three times, and any use where the reader could not point at the thing it names.
- Count tricolons (three-item parallel lists). Flag if more than 2.
- Flag AI-favored adverbs: fundamentally, essentially, ultimately, importantly, significantly, incredibly.
- Flag hollow landscape/ecosystem/paradigm language.
- Flag gerund-heavy constructions ("Decomposing...Writing...Selecting") that should be imperative ("Decompose...Write...Pick").
- Flag fluff phrases: "it's worth noting that," "in terms of," "the fact that," and other padding that adds words without meaning.

### 2. Economy and Verb Strength
- Flag passive constructions that can be active.
- Flag compound clauses that work better as short separate sentences.
- Flag wordy phrases and suggest tighter alternatives (e.g., "making API budgets a rounding error compared to fully-loaded engineering salaries" → "API budgets are a rounding error against salaries").
- Flag sentences where cutting 3+ words changes nothing about the meaning.

### 3. Voice and Ownership
- Flag third-person distancing where first person is appropriate ("the title" → "my title", "the title needs qualifying" → "I'll qualify my own title").
- Flag observational hedging ("one might argue," "it could be said," "what this means depends on where you sit") — the author should take positions.
- Flag sentences written as commentary about the argument rather than the argument itself.

### 4. Structural Patterns
- Flag throat-clearing openers ("This should not surprise anyone", "It's worth noting").
- Flag hedging formulas ("regardless of which X you prefer", "the broader point stands").
- Flag question-then-answer patterns ("What does this mean? It means...").
- Flag "to be sure" sandwiches (counterpoint raised only to be immediately dismissed without engagement).
- Check whether the conclusion restates the introduction or advances beyond it.
- Flag dramatic staging: a paragraph closing on a quotable metaphor that restates it, one-sentence paragraphs held back for effect, verbless fragment runs, personified data ("the ledger asserts"), absolutes the evidence does not support, and a close built from two short imperatives.

### 5. Voice Alignment (target style)
- Compare the draft's tone against the target voice/style.
- Flag passages that deviate from the target (too formal for a cheeky piece, too casual for Scientific American, etc.).
- Note where sentence rhythm doesn't match the target voice's characteristic patterns.

## Report Findings

Present findings to the user as a concise summary:
- Total issues found, grouped by category
- The 3-5 most impactful changes (not an exhaustive list of every minor issue)
- For each, quote the problematic text and suggest a revision

Ask the user: "Should I apply these changes, or do you want to adjust any of them first?"

## Apply Changes

After user approval, edit the file. Apply changes using the Edit tool for precision. After editing, re-read the file and do one final scan for any new issues introduced by the edits.

## Final Check

Read the revised file once more against the self-check from prose-style.md:
1. Could I identify this as AI-written from the first paragraph?
2. Do more than two paragraphs start with the same structural pattern?
3. Is there a sentence included only because it "sounds professional"?
4. Does the conclusion say something the introduction didn't?
5. Does any contrast survive deleting its negated half?
6. Does any paragraph end on an epigram?
7. Could the reader point at the thing every watch-list noun names?

Report the final status to the user.
