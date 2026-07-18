# Assumption Tracker

**Arguments:** text after `/assumptions` is the assumption to capture
(e.g. `/assumptions the vendor API returns results in under 200ms`).

## When to Use

- After an interview surfaces an unvalidated belief
- During architecture discussions when a decision depends on an untested premise
- Before a meeting where you need to validate something
- When someone says "I think..." or "We assume..." or "It should be..."

## Instructions

### 1. Find the assumptions tracker

Search for the tracker file in order:
- `docs/discovery/ASSUMPTIONS-TRACKER.md`
- `docs/ASSUMPTIONS-TRACKER.md`
- `docs/discovery/assumptions.md`

If none exists, create `docs/discovery/ASSUMPTIONS-TRACKER.md` with a header and the first entry.

### 2. Determine the next ID

Read the existing tracker and find the highest A## number. The new assumption gets the next sequential number.

### 3. Structure the assumption

Transform the plain-language input into the hypothesis format:

```markdown
### A[##]: [Title — short, specific]

**Hypothesis**: [Precise testable statement]
**Validation Status**: PENDING
**Validation Method**: [How we will test this — meeting, measurement, prototype, document review]
**Impact if TRUE**: [What becomes possible, what path we take]
**Impact if FALSE**: [What breaks, what alternative path we need]
**Fallback**: [Plan C — what we do if we can't validate at all]
**Severity**: [CRITICAL | HIGH | MEDIUM | LOW]
**Owner**: [TBD unless specified]
**Due Date**: [TBD unless specified]
**Source**: [Where this assumption came from — interview, meeting, design discussion]
```

### 4. Classify severity

- **CRITICAL**: Blocks project direction (e.g. platform choice, deployment model)
- **HIGH**: Affects timeline or scope significantly
- **MEDIUM**: Affects design decisions but has workable alternatives
- **LOW**: Nice to validate but not blocking

### 5. Append to tracker

Add the new assumption to the end of the tracker file. Do not reorder existing entries.

### 6. Check for related assumptions

Scan existing assumptions for:
- **Duplicates**: same hypothesis already tracked (skip, report as duplicate)
- **Dependencies**: new assumption depends on or conflicts with an existing one (note it)
- **Clusters**: multiple assumptions about the same system or decision (note the cluster)

## Verification

- [ ] Assumption has a testable hypothesis (not vague)
- [ ] Impact-if-true and impact-if-false describe different project paths
- [ ] Fallback plan exists (what if we can't validate at all?)
- [ ] No duplicate of an existing assumption
- [ ] Severity classification is reasonable

## Example

Input: `/assumptions the third-party pricing API responds in under 200ms at p95`

Output appended to tracker:

```markdown
### A06: Pricing API Latency <200ms p95

**Hypothesis**: The third-party pricing API returns results in under 200ms at the 95th percentile under expected load.
**Validation Status**: PENDING
**Validation Method**: Load-test the endpoint at target RPS; compare against the vendor SLA; confirm with a timed sample over 24h.
**Impact if TRUE**: Synchronous pricing at request time; no caching layer needed for v1.
**Impact if FALSE**: Requires a cache + async refresh; adds a background job and cache-invalidation design; timeline extends.
**Fallback**: Ship with a short-TTL cache and a "prices as of HH:MM" disclaimer.
**Severity**: HIGH
**Owner**: TBD
**Due Date**: TBD
**Source**: Architecture design discussion
```
