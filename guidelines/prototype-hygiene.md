# Prototype Hygiene — Shipping Clean from Day One

Rules learned from the Librarian genericization (2026-03-06). A prototype built against a real use case will ship — and whatever's hardcoded ships with it.

## Rule 1: Deployment Details Are Config Values, Not Code Values

**If it's specific to the deployment, it goes in `.env` or config — never in source code, system prompts, or architecture docs.**

No exceptions, even for "we'll fix it later."

Examples of deployment details:
- IP addresses, hostnames, ports
- Model names and versions (`qwen3:30b`, `gpt-4o`, etc.)
- User names, family names, company names
- File paths specific to the target machine
- SMB/NFS share paths, database names
- API keys, credentials (obviously)

✅ **Do this:**
```python
CHAT_MODEL = os.getenv("CHAT_MODEL", "")  # Set in .env
SYSTEM_PROMPT = "You are a document assistant..."  # Generic
```

❌ **Not this:**
```python
CHAT_MODEL = os.getenv("CHAT_MODEL", "qwen3.5:27b")  # Hardcoded default
SYSTEM_PROMPT = "You are the Francis family's document assistant..."  # Personal
```

The concrete use case belongs in `.env`, `reference/` data files, or deployment-specific config. The codebase stays generic and reusable.

## Rule 2: Docs Describe How and Why, Not What's Currently Running

**Documentation that contains state (current model, current counts, current IPs) is guaranteed to go stale.**

Docs that describe *patterns* (how VRAM contention works, why Option C beats Option A) stay accurate. Docs that describe *state* (15 documents indexed, using qwen3:30b) are wrong by next week.

✅ **Do this:**
- "The API retrieves top-K chunks via cosine similarity" (pattern — stable)
- "Check `GET /stats` for current document counts" (pointer to live state)
- "Configure the chat model via `LIBRARIAN_CHAT_MODEL` env var" (reference to config)

❌ **Not this:**
- "Currently 38 documents indexed with 307 chunks" (stale tomorrow)
- "Uses qwen3:30b for generation" (changed last week)
- "Running on 192.168.7.237" (meaningless to anyone else)

Current state belongs in health endpoints, status commands, and dashboards — not prose.

## Rule 3: Code That Isn't in a PR Doesn't Exist

**The commit isn't the deliverable — the PR is.**

Work on a branch with 16 commits, pushed to origin, that never gets a PR opened is invisible work. Invisible work is unfinished work.

- Commit → Push → **Open PR** → that's the deliverable
- Don't let branches sit. If the work is done, the PR should exist.
- If the work isn't ready for review, open a draft PR — still more visible than a branch.

## Meta-Lesson

The gap between "working" and "shipped" is where quality dies. Working code with hardcoded details, stale docs, and unopened PRs is a prototype pretending to be a product. The genericization pass is the cost of not doing it right the first time.

**Apply these rules from the first commit, not the first refactor.**
