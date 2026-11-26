---
paths:
  - "**/*.{ts,tsx,mts,cts}"
---

# TypeScript

- `strict: true`, and no `any` without a stated reason. Type external data as `unknown` and
  narrow it, with Zod or similar at API boundaries.
- `interface` for object shapes, `type` for unions and intersections, discriminated unions for
  typed errors.
- Business logic returns a `Result<T, E>` from operations that can fail. Use try/catch only at
  boundaries such as API and event handlers.
- Handle every promise rejection, prefer `async`/`await` to `.then()` chains, and make long
  operations cancellable with `AbortController`.
- React: function components, custom `use*` hooks for shared logic, `useMemo` and
  `useCallback` for expensive work, and error boundaries around async or third-party trees.
