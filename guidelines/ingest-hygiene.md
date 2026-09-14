# Automated Ingest Hygiene

Automated mail ingest writes client material into git without a human in the loop. Twice in
sixteen days that produced something that should never have been committed, and both times the
control that existed did not fire. This is what was learned.

## What happened

**2026-08-25 — a client's plaintext MSSQL password.** Mailed to us in the ordinary course of
setting up a database, filed verbatim into `wiki/raw/`, and swept into a pushed branch by a broad
`git add` that took 84 files at once.

**2026-08-17, found 2026-09-10 — ten operative reports.** Patient name, date of service and
procedure **in the filename**, so a directory listing discloses without a file being opened.
Auto-committed and pushed to a vendor we hold no BAA with. Twenty-four days to detection.

## The five failures, and the rule each one buys

**1. Ingest wrote into a tracked tree by default.**
`wiki/raw/` became tracked so that every wiki page's cited source resolves in a fresh clone,
which is genuinely useful. It also made "a client emailed us something" and "it is in git and
pushed" the same event.

> **Message bodies are tracked. Attachments are not.** A body is text, it is what a page cites,
> and it is what a screen can read. An attachment is an opaque payload whose *filename alone* can
> disclose. Canonical block: `~/.claude/mixins/wiki-raw/gitignore`.

**2. The version marker lied.** Five repos carried `# wiki-mixin: begin v1.0` over three
materially different policies — raw fully ignored, raw tracked with only media excluded, raw
tracked with documents excluded. "Is this repo patched?" could not be answered from the marker.

> **A version string that does not distinguish behaviour is worse than none**, because it invites
> the question and answers it wrongly. Where a convention is copy-pasted rather than propagated,
> ship an audit that inspects reality: `~/.claude/scripts/wiki-raw-audit.sh`.

**3. The gate ran before the data arrived.** The screen was called during the sweep; the body and
attachments were fetched afterwards, in the write block, so the ~82% of mail that drops never
costs a download. Both decisions are right on their own. Together they made a control that cannot
see what it is looking for while reading as though it can — it screened the subject line.

> **Ask what a control would actually have seen on the day.** Not what it is passed in the source,
> what is populated at the moment it runs.

**4. The gate failed open for anything undeclared.** Screening was opt-in per bundle. A bundle
nobody had declared was scanned for nothing — a card number, CVV, SSN and date of birth ingested
clean. Adding a client meant adding an unscreened client, silently.

> **A default that protects nothing must not be reachable by omission.** Screen universally for
> what is sensitive in anyone's data (cards, SSNs); make domain-specific screening opt-in, because
> that is where false positives come from and a queue nobody reads protects nothing.

**5. Remediations landed on one machine and were recorded as done.** Three separate fixes — a
history rewrite, the mail-bot attachment fix, a credential removal — were each written, committed,
and recorded complete while living on one host or one unmerged branch.

> **"Done" means on the default branch of the authoritative remote.** Check with
> `git branch -r --contains <sha>`, not with the commit message.

## Standing rules

- **Stage exact paths.** Never `git add -A` or `add .` for an ingest commit. A broad add is how 84
  files went at once, and a scoped add would have prevented it with no tooling at all.
- **Screen the payload, not the envelope** — body plus attachment filenames.
- **A secret that reached git is rotated, not just deleted.** Removing it at the tip is hygiene;
  the credential is still valid until someone retires it. Say which one you did.
- **Filenames are content.** Enough incidents have turned on a filename that it is a class of its
  own.
- **The pre-commit hook is per-clone opt-in.** `git config core.hooksPath tools/hooks` is *local*
  config and does not propagate, so every fresh clone starts unprotected and nothing says so. Set
  it as a setup step and verify it rather than assuming it.

## Checks

```bash
~/.claude/scripts/wiki-raw-audit.sh      # posture of every repo with a wiki/raw tree; exits 1 if any tracks documents
git config --get core.hooksPath          # empty means the secret-scan hook is not running here
```

Related: [Security Hardening](./security-hardening.md), [Prototype Hygiene](./prototype-hygiene.md),
[Project Setup](./project-setup.md).
