# TypeScript Standards

## Types
- Strict mode (`strict: true` in tsconfig) — no `any` unless explicitly justified
- Use `interface` for object shapes, `type` for unions/intersections
- Prefer `unknown` over `any` for external data, then narrow with type guards
- Zod or similar for runtime validation at API boundaries

## React
- Functional components only, no class components
- Custom hooks for reusable logic (prefix with `use`)
- Memoize expensive computations with `useMemo`, callbacks with `useCallback`
- Error boundaries around async/third-party component trees

## Error Handling
- `Result<T, E>` pattern for operations that can fail, not thrown exceptions in business logic
- Try/catch at boundaries only (API handlers, event handlers)
- Typed errors with discriminated unions

## Async
- Always handle promise rejections
- Use `AbortController` for cancellable operations
- Prefer `async/await` over raw `.then()` chains
