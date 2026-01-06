# AI Systems Engineering Patterns

Reference guide based on [AI Systems Engineering Patterns](https://blog.alexewerlof.com/p/ai-systems-engineering-patterns) by Alex Ewerlöf (Nov 2025).

> "The majority of experience as traditional software engineers applies to the new AI era... patterns like caching, input validation, firewalls, composition, separation of concern—albeit with new names and additions."

---

## Part 1: Interface Patterns

The biggest change with AI Engineering is the interface. Traditional front-end speaks DOM/mobile components, backend speaks JSON/gRPC, but the model speaks **vectors, tokens, and natural language**.

### 1. Structured JSON Prompting

**What**: User submits a JSON object adhering to a strict schema instead of free-form prompts.

**How**: System validates input against schema (JSON Schema, Zod, Pydantic) before it reaches the LLM.

**When to use**:
- Need predictable, structured input
- Building forms/wizards that generate AI requests
- Reducing prompt injection surface area

**Trade-offs**:
- (+) Predictable input format, easier validation
- (+) Reduces ambiguity and hallucination risk
- (-) Less flexible for open-ended queries
- (-) Requires upfront schema design

### 2. Prompt Template Pattern

**What**: Treat prompts as source code (version controlled) and user input as variables (injected at runtime).

**How**: Users interact with standard UI (forms, dropdowns, sliders); application constructs prompts using template engines (Jinja2, Mustache, ES6 literals).

**When to use**:
- Users are not prompt-engineering experts
- Need consistent, optimized prompts
- Want to A/B test prompt variations

**Trade-offs**:
- (+) Centralized prompt management
- (+) Version control and optimization by engineers
- (-) Less flexibility for power users
- (-) Risk of indirect prompt injection via variables

**Security Warning**: Always sanitize user variables before interpolation.

### 3. Structured Outputs

**What**: Force AI output to be valid JSON based on a specific schema.

**How**: Use native Structured Outputs (OpenAI/Anthropic) or libraries like Instructor (Python), Vercel AI SDK (TypeScript). These constrain inference to sample only valid tokens.

**When to use**:
- Sending requests to deterministic/legacy APIs
- Need type-safe responses
- Building pipelines where output feeds other systems

**Trade-offs**:
- (+) Guaranteed type safety at generation level
- (+) No post-processing parsing errors
- (-) May reduce model creativity/flexibility
- (-) Schema complexity limits vary by provider

---

## Part 2: Prompting & Context Patterns

### 4. Context Caching

**What**: Cache the static portions of prompts (system instructions, few-shot examples) to reduce token costs and latency.

**How**: Providers offer context caching APIs; static context is cached server-side and reused across requests.

**When to use**:
- Large system prompts reused across requests
- Few-shot examples that don't change
- High-volume applications

**Trade-offs**:
- (+) Significant cost reduction (up to 80%)
- (+) Reduced pre-fill latency
- (-) Cache invalidation complexity
- (-) Provider-specific implementation

### 5. Progressive Summarization

**What**: Recursively compress oldest messages into a "Summary Block" to maintain fixed context size while retaining semantic history.

**How**: When context approaches limit, summarize older exchanges and replace with condensed version.

**When to use**:
- Long-running conversations
- Need "infinite" conversation memory
- Context window constraints

**Trade-offs**:
- (+) Effectively unlimited conversation length
- (+) Fixed context size/cost
- (-) Lossy compression—details may be lost
- (-) Summary quality affects downstream responses

### 6. Memory Management (Episodic vs Semantic)

**What**: Distinguish between episodic memory (conversation events) and semantic memory (facts/knowledge).

**How**: Observer agent summarizes key facts at conversation end, writes to sidecar database, injects into future sessions.

**When to use**:
- Multi-session user interactions
- Personalization requirements
- Building persistent AI assistants

**Trade-offs**:
- (+) Persistent user context across sessions
- (+) Enables personalization
- (-) Privacy/data retention concerns
- (-) Memory retrieval adds latency

---

## Part 3: Routing & Optimization Patterns

### 7. Router Pattern

**What**: Classify user intent before routing to appropriate model/tool.

**How**: Smaller/faster model classifies query, then routes to appropriate handler.

**When to use**:
- Multiple specialized models/tools available
- Cost optimization needed
- Different queries need different capabilities

**Trade-offs**:
- (+) Cost savings (don't use PhD-level model for greetings)
- (+) Latency optimization
- (-) Routing errors cause poor responses
- (-) Added complexity and routing latency

**Example**: Weather queries → Weather Tool; complex reasoning → GPT-4/Claude

### 8. Skills / Lazy Loading

**What**: Load tool definitions on-demand rather than all at once.

**How**: Router classifies intent, loads only relevant tool subset before model call.

**When to use**:
- 10+ tools available (models get confused with 100 tools)
- Want cleaner system prompts
- Need optimized token usage

**Trade-offs**:
- (+) Improved model accuracy (less distraction)
- (+) Lower token usage
- (-) Adds routing step (latency)
- (-) Requires maintaining skill taxonomy
- (-) Risk of misrouting

### 9. Model Selection (Dense vs Sparse)

**What**: Choose appropriate model architecture for the task.

**Types**:
- **Dense Models** (Llama 3 70B): All parameters active per token. High capability, high cost.
- **Sparse/MoE Models** (Mixtral 8x7B): Only fraction of parameters (experts) active per token. Efficiency mechanism.

**When to use**:
- Dense: Complex reasoning, high-stakes decisions
- Sparse: High-volume, cost-sensitive workloads

---

## Part 4: Caching & Performance Patterns

### 10. Semantic Caching

**What**: Use Vector DB as cache; return cached response if semantically similar question was recently answered.

**How**: Embed incoming query, check similarity against cached queries. If similarity > threshold (e.g., 95%), return cached response.

**When to use**:
- Repetitive queries (FAQ-style)
- Cost reduction priority
- Latency-sensitive applications

**Trade-offs**:
- (+) Massive cost reduction (up to 80% for repetitive workloads)
- (+) Sub-100ms latency for cache hits
- (-) Risk of serving stale data
- (-) Complex cache invalidation
- (-) PII leakage risk without strict scoping

**Security Critical**:
- Tenant isolation mandatory
- Never cache PII responses across users
- Cache keys must be scoped: `(User_ID, Query_Vector)` for private data
- Limit to public knowledge base data for shared caches

### 11. LLM Gateway

**What**: Centralized proxy between applications and Model-as-a-Service providers.

**How**: Gateway handles authentication, rate limiting, failover, fallback. If OpenAI returns 429, gateway retries with Azure OpenAI or fails over to Anthropic.

**When to use**:
- Multi-provider strategy
- High availability requirements
- Centralized cost tracking needed

**Trade-offs**:
- (+) Decouples app code from vendor specifics
- (+) Prevents cascading failures
- (+) Centralizes cost tracking and key management
- (-) New single point of failure
- (-) Small latency overhead
- (-) Maintenance overhead

---

## Part 5: Security & Safety Patterns

### 12. Sanitization Middleware (Guardrails)

**What**: Layer between user and model for content filtering. "Just as you wouldn't expose a database directly to the web, don't expose a raw LLM."

**Components**:
- **Input Sanitization**: Filter prompt injection (the SQL injection of AI)
- **Output Sanitization**: Block PII leakage, hallucinated URLs, toxic content

**When to use**:
- Any production AI system
- User-facing applications
- Regulated industries

**Trade-offs**:
- (+) Reduced security/safety risks
- (+) Brand protection
- (-) May block legitimate queries (false positives)
- (-) Added latency
- (-) Requires ongoing tuning

### 13. Prompt Injection Defense

**What**: Prevent attackers from manipulating LLM through crafted inputs.

**Attack types**:
- **Direct**: User input contains malicious instructions
- **Indirect**: Malicious content in retrieved documents/data

**Mitigations**:
- Input validation and sanitization
- Sandboxing unsafe inputs
- Dedicated prompt injection detection tools
- Multi-agent architectures with specialized security agents

### 14. PII Protection

**What**: Prevent personally identifiable information from leaking through AI responses.

**Strategies**:
- Detect and redact PII before storage/caching
- Tenant-isolated caching
- Output scanning before response delivery
- Data minimization in training/fine-tuning

---

## Part 6: Architecture Patterns

### 15. RAG (Retrieval-Augmented Generation)

**What**: Augment LLM with external knowledge retrieval.

**How**:
1. Embed user query
2. Retrieve top-k similar chunks from vector DB
3. Assemble chunks + question into prompt
4. Generate response

**When to use**:
- Domain-specific knowledge needed
- Knowledge base updates frequently
- Reduce hallucinations with grounded responses

**Trade-offs**:
- (+) Up-to-date information
- (+) Reduced hallucination
- (+) Auditable sources
- (-) Retrieval quality affects output
- (-) Added latency and complexity
- (-) Chunking strategy critical

### 16. Multi-Agent Orchestration

**What**: Multiple specialized AI agents collaborating on tasks.

**Patterns**:
- **Sequential**: Agents in pipeline
- **Parallel**: Concurrent execution, results merged
- **Hierarchical**: Orchestrator delegates to specialists
- **Debate**: Multiple agents propose, critic evaluates

**When to use**:
- Complex multi-step tasks
- Need specialized capabilities
- Want checks and balances

**Trade-offs**:
- (+) Specialization improves quality
- (+) Built-in verification possible
- (-) Coordination complexity
- (-) Higher cost (multiple calls)
- (-) Debugging difficulty

### 17. Flow Engineering

**What**: Design multi-step workflows breaking complex tasks into manageable segments.

**How**: Shift from "perfect prompt" to "best flow with correct steps." Parallels System 2 thinking—slow, deliberate reasoning.

**When to use**:
- Complex problem-solving
- Need reliability over creativity
- Auditable decision processes

---

## Quick Reference Matrix

| Pattern | Primary Benefit | Key Risk | Complexity |
|---------|----------------|----------|------------|
| Structured JSON | Predictability | Flexibility loss | Low |
| Prompt Template | Consistency | Injection risk | Low |
| Structured Output | Type safety | Creativity limits | Medium |
| Context Caching | Cost reduction | Invalidation | Medium |
| Semantic Caching | Latency/cost | PII leakage | High |
| Router | Cost optimization | Misrouting | Medium |
| Skills/Lazy Load | Accuracy | Misrouting | High |
| LLM Gateway | Reliability | SPOF | High |
| Guardrails | Safety | False positives | Medium |
| RAG | Grounding | Retrieval quality | High |
| Multi-Agent | Quality | Complexity | Very High |

---

## Implementation Checklist

When reviewing AI/LLM integrations, verify:

- [ ] **Input handling**: Structured inputs or sanitized templates?
- [ ] **Output validation**: Structured outputs or post-processing?
- [ ] **Caching strategy**: Semantic caching with tenant isolation?
- [ ] **Routing**: Appropriate model selection per query type?
- [ ] **Security**: Guardrails for input/output? Prompt injection defense?
- [ ] **Resilience**: LLM gateway or fallback strategy?
- [ ] **Cost optimization**: Context caching? Router pattern?
- [ ] **Memory**: Session/semantic memory strategy?
- [ ] **Observability**: Logging, metrics, evaluation loops?

---

## Sources

- [AI Systems Engineering Patterns - Alex Ewerlöf](https://blog.alexewerlof.com/p/ai-systems-engineering-patterns)
- [Context Engineering for AI Agents - Manus](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)
- [AI Guardrails - Cloud Security Alliance](https://cloudsecurityalliance.org/blog/2025/12/10/how-to-build-ai-prompt-guardrails-an-in-depth-guide-for-securing-enterprise-genai)
