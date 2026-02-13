# Version Roadmap

Breaking down the [full game vision](startup-simulator-game-brief.md) into incremental, playable sub-versions. Each version builds on the last.

**Philosophy:** The game brief describes the dream. This roadmap describes the path. Cut ruthlessly. Ship playable increments.

Iteration details, acceptance criteria, and implementation plans live in feature docs (`docs/features/`), not here.

---

## v0.1 — Walk & Talk

The core exploration loop. Player moves around a tile map, encounters NPCs, and discovers startup problems through conversation.

- Tile map with a single zone (ground, buildings exterior, props)
- Pokemon-style grid-based player movement with collision
- 2.5D camera (~10-degree angle) with sprite layering for depth
- 3–5 NPCs placed on the map
- Chat interaction — walk up to NPC, press interact key, read dialogue
- Each NPC's dialogue surfaces a distinct real-world problem

**Brief references:** Phase 1 (Problem Discovery), Interaction System

---

## v0.2 — The Idea

The player collects problems, reviews them, and picks one to build a company around.

- Problem journal — tracks all discovered problems
- Problem selection — commit to one problem from the journal
- Company founding — name the company, see the "founded" moment
- Basic HUD — company name + starting capital ($100,000) displayed
- Multi-layer NPC dialogue (first message = problem, follow-ups = context)

**Brief references:** Phase 1 (problem selection), Economy Summary (starting capital)

---

## v0.3 — Tick Tock

Time starts passing. The economy infrastructure exists even before there are expenses.

- In-game clock (24 in-game hours = 48 real-world minutes) on HUD
- Day/night visual tint cycle
- Economy foundation — live balance tracking, burn rate display (starts at $0)
- Save/load game state (position, company, problems, time)
- Pause/unpause

**Brief references:** Time Scale, Economy Summary

---

## v0.4 — The Team

Hiring comes online. Employees cost money — the burn rate becomes real.

- Job board building on the map (enterable)
- Create job postings (role + salary range)
- NPC applicants arrive over in-game time with varied attributes (experience, skills, salary expectation)
- Hire/reject flow
- Salary adds to monthly burn rate
- Employee roster UI

**Brief references:** Phase 3 (Hiring)

---

## v0.5 — Home Base

The office becomes a physical place. Employees have a home.

- Office building on the map (enterable)
- Office interior as a separate tile map scene
- Office setup — purchase furniture/equipment, costs deducted
- Hired employees appear in the office
- Office rent as recurring burn rate cost
- Building interiors system (enter/exit transitions between overworld and interiors)

**Brief references:** Phase 4 (Office Setup)

---

## v0.6 — Ship It

The core economic engine. Build features, attract customers, generate revenue.

- Feature planning — define product features with complexity/effort
- Resource allocation — assign employees to features
- Build progress over in-game time
- Feature release — shipped features generate customer satisfaction scores
- Customer trickle — shipped features attract customers
- Revenue — customers generate daily income
- Minimal tech stack selection (2–3 choices, affects build speed)

**Brief references:** Phase 5 (Team Management & Product Development), Product Development design decisions

---

## v0.7 — Storefront

The website mini-game. Website quality directly affects customer discovery.

- Drag-and-drop website builder (templates, sections, text customization)
- Website quality score based on completeness and design choices
- Quality score multiplies customer acquisition rate
- Designer NPC proposes website changes over time — player approves/rejects

**Brief references:** Phase 2 (Build Your Product Website), Website Builder design decisions

---

## v0.8 — Pitch Day

Funding rounds. Investors evaluate the player's pitch and offer terms.

- Valuation formula (revenue, growth rate, user base, market size, team quality) on HUD
- Investor NPCs with distinct personalities, risk tolerance, and investment theses
- Pitch mechanic — player delivers pitch, LLM evaluates for quality and investor fit
- Funding offers — amount for equity percentage, or rejection
- Accept/reject/negotiate flow
- Equity tracking and dilution display
- Accepted funding adds to cash balance

**Brief references:** Valuation & Funding design decisions, Phase 7 (funding rounds)

---

## v0.9 — Rocket Ship

The launch event and market cycles. The endgame loop takes shape.

- Product launch event — triggers customer/attention spike
- Post-launch decay — customer interest declines, creating pressure to keep building
- Market cycles — random upturns (more customers, easier funding) and downturns (churn, tight funding)
- Downturn management — active choices: layoffs, cost cuts, emergency funding
- Growth loop — build → launch → grow → survive downturns → raise → repeat

**Brief references:** Phase 6 (Product Launch Event), Phase 7 (Growth Cycles), Market Downturns design decisions

---

## v1.0 — The Full Game

Win/lose conditions, recovery mechanics, idle systems, and polish. A complete game.

- Bankruptcy — $0 cash triggers 24 in-game hour recovery window. Fail = game over
- Loyalty bonus — after bankruptcy restart, some previous employees return at reduced salaries
- Pivot mechanic — change product direction with costs (lost momentum, possible turnover, NPC reactions)
- Win condition — $1B valuation
- Idle mechanics — game runs while player is away
- Auto-pause after 7 real-world days of inactivity
- Notification log — summary of events during absence
- Mentor/advisor NPCs — guidance, mechanic unlocks, investor introductions
- Customer feedback NPCs — product reactions, feature requests, satisfaction
- Balance and polish pass

**Brief references:** Bankruptcy, Pivot, Idle Mechanics, Failure Philosophy, NPC Reactions design decisions

---

## Pre-V2 — Art Pass

Replace AI-generated 2D sprites with 3D models before V2 feature work begins.

**Why:** AI-generated images have two fundamental problems:
1. **Baked shadows** — each tile has its own shadow direction/intensity, preventing consistent lighting and blocking true HD-2D (renderer-driven shadows, depth of field, bloom)
2. **Inter-tile variance** — independently generated textures don't seamlessly match at boundaries; roads, grass, and building edges all have subtle mismatches

**What changes:**
- Tiles, buildings, props → 3D models rendered by Godot (consistent lighting, deterministic UVs, seamless tiling)
- Characters → either 3D models or hand-drawn sprite sheets (TBD)
- Remove `generate_sprites.py` dependency — assets become source-controlled models

**What stays:** Map layout, game logic, NPC system, dialogue — all code carries forward unchanged.

---

## V2+ (Parked)

Out of scope until V1 is complete. Documented in the [game brief](startup-simulator-game-brief.md) under "V2 Features" and "Future Considerations."

- Competitor startups (AI-driven)
- Difficulty settings
- Time-travel / fast-forward
- Procedurally generated NPC problems
- Randomized market cycles for replayability
- Multiple endings (acqui-hire, IPO, lifestyle business, serial entrepreneur)
- Multiplayer / competitive mode
