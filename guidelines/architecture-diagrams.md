# Architecture Diagram Craft (AWS reference-diagram conventions)

Canonical conventions for producing principal-architect-grade reference/solution
architecture diagrams. Primary authority: the **AWS Architecture Icons deck** (its
built-in style guide) + **AWS Architecture Center** exemplars. Reconciled with the
**C4 model** (for altitude discipline) and adapted for GCP / multi-cloud. Do/don't,
not prose.

> **Scope split.** This guideline covers *visual craft* — what a professional
> diagram looks like and why. For PlantUML *file organization* (modular includes,
> C1/C2/C3 file layout, System-vs-System_Boundary conflicts), see the companion
> [C4-diagramming.md](./C4-diagramming.md). Use both: C4-diagramming for how to
> structure the `.puml` sources, this file for whether the rendered result is
> any good.

## 0. Principles (read first)
- **One diagram, one altitude.** Pick context OR container OR detailed — never mix.
  The "everything on one canvas" mush is the #1 amateur tell.
- **Abstraction-first, notation-second.** Decide what you're communicating and to
  whom before you touch icons. (C4 core principle.)
- **The diagram must stand alone.** Title, legend, and numbered flow let a reader
  who wasn't in the room understand it. If it needs you narrating, it's incomplete.
- **Every line has a direction and a reason.** Unlabeled, undirected lines are noise.
- **Boundaries carry meaning.** A box around things is a claim (same VPC, same
  account/project, same trust zone). Don't draw boundaries you don't mean.
- **Consistency > cleverness.** Same icon set, same arrow style, same callout size
  throughout. Mixing is the second-biggest amateur tell.
- **Distinguish fact from assumption visually.** If parts of the system are inferred
  or unverified, give them a distinct tag/color and collect them in an assumptions
  register. Never let a guess render identically to a confirmed fact.

## 1. Visual grammar checklist
- **Flow direction:** establish one — left→right or top→bottom — and hold it.
  Request/ingress enters from the left (or top); data/persistence sits right (or bottom).
- **Numbered step callouts (the AWS ①②③ pattern):** number the primary flow.
  - Order numbers linearly: left→right, top→bottom, or clockwise.
  - Keep callout placement consistent (e.g. always top-left of the connected element).
  - Pair the numbers with a **side legend / step table** that narrates each step in
    one line ("① User request hits Cloudflare edge → WAF + cache").
  - DON'T mix callout sizes, change color/font inside a callout, use letters instead
    of numbers, or invent new callout shapes.
- **Actors & external systems:** draw human actors and third-party/SaaS systems
  distinctly (person glyph for actors; a plain/greyed box for external systems) and
  place them at the diagram edge, outside your boundaries.
- **Boundaries / grouping:** use grouping containers for trust and infra scope —
  Region, Account/Project, VPC/Network, Subnet, Availability Zone/Zone, On-prem/Corp
  DC, Edge. Nest them correctly (AZ/Zone inside VPC inside Region inside Account/
  Project). Label every boundary. Don't let a boundary cross or overlap another
  ambiguously.
- **Data flow vs control flow:** distinguish them — e.g. solid line = data/request
  path, dashed line = control/async/config/auth. State the convention in the legend.
- **Whitespace & alignment:** align icons to a grid; equalize spacing. Sloppy
  alignment reads as sloppy thinking.

## 2. Icon, color & typography rules
- **Use official service icons for named managed services; generic boxes for generic
  concepts.** Name the *specific* service (e.g. "Application Load Balancer", not
  "load balancer") — different services have different icons and implications.
- **Icon taxonomy (AWS):** *service icons* (square, category-colored) name a service;
  *resource icons* show a sub-resource/state; *category/group* shapes are the boundary
  containers. Don't repurpose one as another.
- **Category color system (AWS) — color = service category, not decoration:**
  - Compute = orange · Storage = green · Database = blue · Networking & Content
    Delivery = purple · Security/Identity/Compliance = red · Analytics = purple/violet ·
    App Integration = pink/magenta · Management = pink/rose.
  - Rule: **never recolor an official icon.** Its color is load-bearing.
- **Legend is mandatory** when you use any non-obvious icon, color, or line style.
  A reader should never have to guess.
- **Typography:** one font family. Element labels = name + type/technology + short
  description (C4: `name` / `[type]` / one-line purpose). Keep labels terse and
  parallel. No paragraphs inside boxes.
- **Arrows:** use the preset arrow style throughout. Prefer straight lines and right
  angles; a single diagonal only when a right angle is impossible. One arrowhead,
  one direction, one label per relationship.

## 3. Layering — C4 ↔ AWS reference reconciliation
C4 gives you the *altitude ladder*; AWS gives you the *visual polish at each rung*.
Use both: C4 to decide scope, AWS conventions to render it.

| C4 level | What it answers | AWS reference-diagram analog |
|---|---|---|
| **L1 System Context** | Who/what uses the system; external systems | "Solution overview" — your system as one box, actors + external SaaS around it |
| **L2 Container** | Deployable/runtime units & data stores | The classic AWS reference architecture: services, queues, datastores, with VPC/account/region boundaries and numbered flow |
| **L3 Component** | Internals of one container | Detailed service-internal diagram; rarely needed for a solution overview |
| **L4 Code** | Classes/functions | Almost never draw; let the IDE generate it |

- For a "solution architecture diagram a principal SA would be proud of," the target
  is usually **L2 (Container) rendered with AWS reference-diagram polish**: real
  service icons, infra boundaries, numbered flow + step legend.
- Keep C4's discipline even when using cloud icons: every element gets name + type +
  description; every relationship gets a labeled directional arrow; the diagram gets a
  title and a legend.
- Add C4 *supplementary* views as separate diagrams when warranted: **System
  Landscape** (multi-system), **Deployment** (infra/runtime mapping), **Dynamic** (a
  sequence/flow for one scenario). One concern per diagram.

## 4. Annotation patterns
- **Title block:** every diagram states its type and scope ("Damar CV Pipeline —
  Container view (L2)"), plus version/date and author.
- **Numbered-step legend table:** the numbered callouts on the canvas map to a short
  ordered list beside or below the diagram. This is the single highest-leverage
  professionalism move.
- **Legend/key:** icon meanings, line-style meanings (data vs control, sync vs async),
  boundary meanings, and the assumed/unverified tag.
- **Assumptions / notes box:** call out non-obvious choices, out-of-scope items, and
  trust assumptions. Pair with an assumptions register in the surrounding doc.
- **Don't annotate on the lines** beyond a short verb phrase; push detail to the legend.

## 5. Anti-patterns (the amateur tells)
- Icon soup: many icons, no flow, no grouping, no numbers.
- No flow direction / arrows pointing every which way / crossing lines.
- No legend; non-standard or recolored icons; mixed icon sets (2018 + 2020 AWS).
- Mixed altitudes (context boxes next to class-level detail).
- Boundaries that don't mean anything, or overlap ambiguously.
- Single-AZ/single-zone drawn as if it were HA (the diagram advertises the SPOF).
- Database in a public subnet / outside a network boundary.
- Walls of text inside boxes; inconsistent fonts/sizes; manual-stretched callouts.
- "Logo parade" — vendor logos used decoratively instead of service icons that mean
  something.
- Inferred elements rendered identically to confirmed ones.

## 6. Tooling notes
- **PlantUML + C4-PlantUML** (`plantuml-stdlib/C4-PlantUML`, actively maintained, in
  PlantUML stdlib): diagram-as-code, diffable, PR-reviewable. Best when the diagram
  lives in a repo and must stay in sync with the system.
  - Includes: `C4_Context/Container/Component/Dynamic/Deployment.puml`.
  - Macros: `Person/Person_Ext`, `System/System_Ext/SystemDb`, `Container*`,
    `Component`, `Rel`/`Rel_U/D/L/R`/`BiRel`, `Boundary`/`System_Boundary`/
    `Container_Boundary`, `LAYOUT_LEFT_RIGHT`/`LAYOUT_TOP_DOWN`, `SHOW_LEGEND`,
    `AddElementTag`/`UpdateElementStyle` for custom styling (use a tag for `assumed`).
  - Sprites/icons: `$sprite=` on any element; combine with cloud icon sprite libs
    (awslib/azure/gcp in stdlib, or `tupadr3/plantuml-icon-font-sprites`).
- **Cloud sprite libs in PlantUML stdlib:** `awslib` (legacy 2018 + current 2020 set —
  use 2020), Azure, and GCP. AWS is most mature; **GCP coverage is thinner**.
- **When to switch to diagrams.net (draw.io) / Lucidchart / Cloudcraft:** when the
  audience is executives/customers and you need pixel-perfect official icons, precise
  layout, and a polished single canvas. PlantUML auto-layout fights you past ~15 nodes;
  hand-layout tools win for the "hero" diagram.
- **Rule of thumb:** PlantUML/C4 for living engineering diagrams in-repo; draw.io/Lucid
  with the official icon deck for the customer-facing hero diagram. Keep them
  consistent; don't let the hero diagram drift from the code-truth one.
- For sandboxed PlantUML rendering, the bundled GCP/Cloudflare sprite sets can be
  fragile when combined; fall back to C4 notation + colored boundaries + legend, and
  test each `!include` in isolation before relying on it.

## 7. GCP / multi-cloud adaptation
AWS owns the *conventions*; honor them with GCP's *own* assets — don't paint AWS
orange onto GCP.
- **Icons:** use the official Google Cloud icon set (`cloud.google.com/icons`) for GCP
  services; Cloudflare's brand icons for Cloudflare; a neutral building/rack glyph for
  on-prem. One set per vendor, never AWS icons standing in for GCP.
- **Boundary mapping:** Region (same name) · **Project** replaces AWS Account · **VPC
  network** (GCP VPCs are global; subnets are regional — draw subnets inside regions,
  VPC spanning regions) · **Zone** replaces AZ · on-prem/corp DC as its own boundary ·
  Cloudflare edge as an external boundary in front of ingress.
- **Multi-cloud diagram:** one clearly-labeled boundary per provider; a single
  consistent arrow/flow convention across all of them; legend states which icon set is
  which. Numbered flow crosses boundaries to show the request path edge→cloud→on-prem.
- Everything else (numbered callouts, step legend, one-altitude, labeled directional
  arrows, no recoloring, mandatory legend/title) applies unchanged.

## 8. Critique rubric (grade a diagram before you ship it)
Score each 0/1/2 (absent / partial / fully meets). Items 16–20 are GCP/multi-cloud.

| # | Criterion | Pass condition |
|---|---|---|
| 1 | Single altitude | Declares and holds one C4 level; no class-level detail mixed with context. |
| 2 | Title block | Title states system + diagram type + scope; version/date present. |
| 3 | Legend/key | Every icon, color, line style, and the assumed tag explained. |
| 4 | Numbered flow | Primary path numbered ①②③, ordered linearly. |
| 5 | Step legend table | Numbers map to a short ordered narrative beside/below the canvas. |
| 6 | Consistent flow direction | One dominant direction; ingress one side, persistence the other. |
| 7 | Directional, labeled arrows | Every relationship one-directional with a verb-phrase label; no bare lines. |
| 8 | Data vs control distinction | Sync/data vs async/control shown via line style, stated in legend. |
| 9 | Meaningful boundaries | Region/Project/VPC/Subnet/Zone/on-prem/edge drawn, correctly nested, labeled. |
| 10 | External actors & systems | Humans and third-party/SaaS drawn distinctly, at the edge, outside boundaries. |
| 11 | Element labels complete | Each element has name + type/technology + one-line purpose. |
| 12 | Official, correctly-colored icons | Named services use official icons; category colors intact; generic concepts generic. |
| 13 | One icon set per vendor | No mixed/legacy sets; no cross-cloud icon substitution. |
| 14 | Layout cleanliness | Grid-aligned, minimal/zero crossing lines, right-angle connectors. |
| 15 | Assumptions/notes & scope | Non-obvious choices, trust assumptions, out-of-scope called out; inferred elements tagged. |
| 16 | GCP boundary mapping | Uses **Project** (not Account), **Zone** (not AZ); VPC spans regions, subnets nested. |
| 17 | GCP-native icons | Official GCP icons for GCP; Cloudflare brand icons; neutral glyph for on-prem. |
| 18 | Cloudflare edge represented | CF drawn as external edge boundary in front of ingress, role labeled. |
| 19 | On-prem boundary | On-prem box in its own labeled boundary; link to cloud (tunnel/RTSP/upload) directional + labeled. |
| 20 | Multi-cloud legend clarity | Legend states which icon set = which provider; one arrow convention; numbered flow crosses boundaries. |

Scoring: 36–40 principal-grade · 28–35 solid, minor polish · 20–27 amateur tells
present, rework · <20 restart from altitude/flow.

## 9. Reference assets
Official/primary first; mirrors and how-tos after.

| Asset | URL | What / why | Cost |
|---|---|---|---|
| **AWS Architecture Icons** | https://aws.amazon.com/architecture/icons/ | The canonical source: PowerPoint decks (light/dark) + raw SVG/PNG icon package, grouping shapes, callouts, arrows. The deck embeds AWS's own **Do/Don't style guide** and the category-color legend. Released ~quarterly (Jan/Apr/Jul; no Q4). Use the **2020 set**. | Free |
| AWS icon deck (dark mirror) | https://www.slideshare.net/slideshow/awsarchitectureiconsdeckfordarkbg02062024pptx/266328392 | Read the verbatim callout/group/arrow rules without downloading. Light mirror: https://www.slideshare.net/slideshow/aws-architecture-icons-deck_for-light-bg_02062024-pptx/267890370 | Free |
| **AWS Architecture Center** | https://aws.amazon.com/architecture/ | Library of official reference diagrams + Well-Architected. Exemplars to emulate. | Free |
| Exemplar — Serverless Web/Mobile (PDF) | https://d1.awsstatic.com/architecture-diagrams/ArchitectureDiagrams/mobile-web-serverless-RA.pdf | A canonical RA diagram (numbered flow, icons, boundaries) — the quality bar. | Free |
| Exemplar — App Runner web hosting | https://docs.aws.amazon.com/architecture-diagrams/latest/serverless-web-hosting-aws-app-runner/serverless-web-hosting-aws-app-runner.html | Shows ①②③ + side-legend table done right. | Free |
| **C4 model** | https://c4model.com | Altitude discipline; reconciles with C4-PlantUML diagrams. | Free |
| **C4-PlantUML** | https://github.com/plantuml-stdlib/C4-PlantUML | C4 macros for diagram-as-code (~7k★, in stdlib). | Free/OSS |
| PlantUML stdlib | https://plantuml.com/stdlib | Bundled `awslib`/`azure`/`gcp`/`logos`/`C4` sprite sets. | Free/OSS |
| Hitchhiker's Guide to PlantUML | https://crashedmind.github.io/PlantUMLHitchhikersGuide/ | Best how-to for combining C4 + cloud sprites. | Free |
| **Google Cloud Icons + guidelines** | https://cloud.google.com/icons | Official GCP icon library + zone/title style guidance — the GCP-native equivalent of the AWS deck. | Free |
| GCP icons for draw.io | https://drawio-app.com/blog/updated-google-cloud-platform-icons-and-templates/ | Official GCP icons + templates inside draw.io, for the hand-laid hero diagram. | Free |
| tupadr3 icon-font sprites | https://github.com/tupadr3/plantuml-icon-font-sprites | DevIcons/FontAwesome/Material sprites — fills gaps (Cloudflare, on-prem, protocols). | Free/OSS |

Maturity note: AWS PlantUML coverage is most complete; Azure solid; **GCP sprite
coverage in PlantUML stdlib is thin** — for a polished GCP hero diagram prefer the
official GCP icon set in draw.io/Lucid over PlantUML GCP sprites.

## Version
Created 2026-06-05. Sourced from AWS Architecture Icons deck + Architecture Center,
the C4 model, and PlantUML stdlib docs. Companion to C4-diagramming.md.
