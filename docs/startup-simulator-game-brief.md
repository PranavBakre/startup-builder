# Startup Simulator — Game Design Brief

## Overview

A 2.5D top-down startup simulator where the player builds a digital product company from scratch — from discovering a real-world problem to scaling a billion-dollar business. The camera sits at roughly a 10-degree angle, giving slight depth to a flat X/Y movement plane.

**Tone:** Serious but playful. Grounded and warm — not satirical. Think Stardew Valley meets startup culture.

**End Goal:** The player's company reaches a $1 billion valuation.

---

## Core Gameplay Loop

The player navigates a map, interacts with NPCs and buildings, manages resources, hires employees, builds a product, and grows their startup through multiple phases — all while surviving market cycles, funding rounds, and potential bankruptcy.

**Starting Capital:** $100,000

---

## Phase 1: Problem Discovery

- The player walks around the map and encounters NPCs (bots) who are performing various actions.
- The player can approach any NPC and press a keyboard shortcut (e.g., `C` for Chat) to initiate conversation.
- Each NPC has a predefined message array. The first layer of dialogue always surfaces a **problem** — either with an existing digital product or a real-world pain point.
- The player talks to multiple NPCs, collects multiple problems, and then **chooses one problem to solve** with their startup.
- This choice defines their product direction (but can be changed later via the Pivot mechanic).

**Future Enhancement:** Replace static NPC problems with procedurally generated ones based on real-world problems.

---

## Phase 2: Build Your Product Website (Mini-Game)

- After selecting a problem, the player enters a mini-game to build a website for their product.
- This is the first tangible step toward launching.
- The website serves as the public face of the startup and affects perception, customer acquisition, and launch success.

---

## Phase 3: Hiring

- A **hiring mini-game / job board** becomes available.
- The player can create different job postings.
- NPCs (applicants) periodically apply to open positions.
- Each applicant has attributes: experience level, salary expectations, skill set.
- The player reviews and selects who to hire.

---

## Phase 4: Office Setup

- The map contains a building designated as the **Office**.
- When the player visits the office, they must set it up — furniture, equipment, infrastructure.
- Setup costs are deducted from the $100,000 starting capital.
- Once set up, hired employees are assigned to the office.

---

## Phase 5: Team Management & Product Development

- Each employee is assigned a **role** based on their experience and the player's needs.
- Employees focus on specific aspects of the product (e.g., frontend, backend, design, marketing).
- The player actively directs product development — choosing features to build, prioritizing work, iterating on the product.
- **In-game economics during this phase:**
  - Daily customer trickle (small revenue).
  - Startup funding mechanisms (grants, angel investment, early revenue) to sustain the company while the product is being built.
  - Burn rate from salaries, office costs, and operations.

---

## Phase 6: Product Launch Event

- Once a sufficient iteration of the product is built, an **in-game launch event** is triggered.
- The launch generates a spike in customer reach and attention.
- Post-launch, customer interest **declines over time**, creating pressure to:
  - Build new features.
  - Expand the product.
  - Iterate and improve continuously.

---

## Phase 7: Growth Cycles (Recurring / Endgame Loop)

After the initial launch, the game enters cyclical rounds that repeat with increasing complexity:

- **Market Upturns:** More customers, easier fundraising, higher valuations.
- **Market Downturns:** Customer churn, tighter funding, cost-cutting decisions.
- **Funding Rounds:** Pitch to investors, negotiate terms, dilute equity.
- **Investor Events:** Investors may leave, demand board seats, push for pivots.
- **Scaling Challenges:** Hiring at scale, maintaining culture, managing burn rate.

The player must navigate these cycles strategically to grow toward the $1B valuation goal.

---

## Key Mechanics

### Bankruptcy

- If the player runs out of money, they have **24 hours** (real-time or in-game TBD) to:
  - Come up with a new idea.
  - Secure new funding.
- If they fail to recover within 24 hours, they must **start a new game**.
- **Loyalty Bonus:** When restarting after bankruptcy, a percentage of previous employees are willing to return at reduced salaries (they know and trust the player).

### Pivot

- The player can **pivot** their startup — changing the problem they're solving or the product direction.
- NPCs may react to the pivot ("Oh, you're working on *this* now?").
- Pivoting has costs (lost momentum, possible employee turnover) but opens new opportunities.

### Interaction System

- **Movement:** Pokemon-style tile-based 2.5D. Grid-based movement on a tile map with a fixed elevated camera. Depth is conveyed through sprite layering (buildings you walk behind, trees that overlap the player, shadows for grounding). Not free-roaming isometric — it's classic RPG tile navigation.
- **Map Structure:** The world is a tile map with distinct zones. Buildings (office, hiring center, launch venue) are map locations the player enters, which transition into phase-specific interiors/UIs.
- **NPC Interaction:** NPCs occupy tiles on the map. The player walks up to an NPC and presses a keyboard shortcut (e.g., `C`) to initiate chat.
- **Building Interaction:** Walk onto a building entrance tile to enter and trigger phase-specific mechanics.

---

## Economy Summary

| Item | Details |
|------|---------|
| Starting Capital | $100,000 |
| Revenue Sources | Daily customers, funding rounds, grants, product sales |
| Costs | Employee salaries, office setup, office rent, operations, marketing |
| Win Condition | Company valuation reaches $1,000,000,000 |
| Fail Condition | Bankruptcy without recovery within 24 hours |

---

## Future Considerations (Not in MVP)

- **Replayability:** Procedurally generated problems, randomized market cycles, different starting conditions.
- **Procedural NPC Problems:** Instead of static dialogue, NPCs surface problems pulled from real-world datasets or generated dynamically.
- **Multiple Endings:** Acqui-hire, IPO, lifestyle business, serial entrepreneur path.
- **Multiplayer / Competitive:** Multiple players building startups in the same market.

---

## Notes for Implementation

This document represents the **full vision** — the dream state of the game. It will be broken into development phases, with the earliest phases focusing on core mechanics (movement, NPC interaction, problem discovery) before layering in the economic simulation and growth cycles.

The game should be structured with **modular systems** so each phase (discovery, hiring, office, product dev, launch, growth) can be built, tested, and iterated independently.

---

## Resolved Design Decisions

### Time Scale
- **24 in-game hours = 48 real-world minutes** (the doubled rate for better pacing).
- **1 in-game month ≈ 24 real-world hours.**
- This mirrors startup timelines realistically — companies are built over years, so a full playthrough spans meaningful real-world time.
- The game **has idle-time elements**. The company runs while the player is away.
- **Future Enhancement:** A time-travel / fast-forward mechanic to let players skip idle periods.

### Bankruptcy Window
- The 24-hour recovery window is **in-game time** (= 48 real-world minutes). Session-friendly, no real-world time pressure.

### Website Builder
- Starts with **drag-and-drop templates**. Players can add and customize elements.
- **The website evolves over time.** Once a designer is hired, the designer NPC will automatically propose website changes. The player's role shifts to **approve or reject** proposed updates.

### Product Development
- **Feature Formation → Resource Allocation.** The player first defines what features to build, then allocates team resources to build them.
- **Tech stack selection** is a mechanic but kept **minimal** — enough to feel meaningful without becoming a coding simulator.
- Every released feature generates a **customer satisfaction score**, which feeds back into retention, growth, and valuation.

### Valuation & Funding
- **Valuation follows real-world formulas** — a combination of revenue, growth rate, user base, market size, and team quality.
- **Funding rounds are pitch-based.** The player delivers a pitch and an **LLM evaluates the pitch in real-time**, scoring it based on clarity, market understanding, financials, and fit with the investor.
- **Investors have personalities and preferences** — some are risk-tolerant, some want profitability, some care about team pedigree, etc. The player must tailor their pitch accordingly.
- **Equity dilution is tracked.** The player sees their ownership percentage change with each round. They can **reject investment offers** if dilution is too high.

### NPCs & World
- **Customer NPCs have simple memory** — basic tracking of whether they've interacted with the player before. They can give **actual feedback on the product** (satisfaction, complaints, feature requests).
- **Mentor and advisor NPCs exist** on the map. They offer guidance, unlock mechanics, or make introductions (e.g., "I know an investor, let me connect you").

### Failure Philosophy
- **No acqui-hire as a failure state.** The game is about winning. Bankruptcy is the failure state, and the recovery mechanic (24 in-game hours + employee loyalty bonus) gives players a fighting chance to come back.

### Market Downturns
- **Market downturns are purely external forces.** The player cannot influence market conditions — they can only react.
- **During downturns, the player manages burn rate.** Key decisions: lay off employees, cut features, reduce office costs, seek emergency funding, pivot. Every downturn requires active decision-making.

### NPC Reactions
- **Problem NPCs react to your product.** If you build a solution to their problem, they respond to it — becoming customers, giving feedback, requesting features. Their feedback directly drives product iteration.

### Idle Mechanics
- **Employees keep building while the player is away.** Customers keep arriving. Market shifts happen. The game world is alive.
- **Auto-pause after 1 week of inactivity.** If the player is absent for 7 real-world days (~7 in-game months), the game enters a **paused state** to prevent passive bankruptcy. This means the player must have a minimum cash reserve that can sustain operations for ~7 months before going idle safely.
- **Notification log exists.** When the player returns, they receive a summary of everything that happened while they were away (features shipped, customers gained/lost, revenue, employee proposals, market changes, etc.).

---

## Remaining Open Questions

These decisions are still unresolved and should be addressed as development progresses.

### Failure & Progression
- **What carries over after bankruptcy:** Employee loyalty (some return at lower salaries), reputation, and map knowledge. These persist across playthroughs.

### Scope & MVP
- **What is Phase 1 of development?** Recommendation: Movement + NPC interaction + problem discovery + problem selection. If that core loop is fun, everything else layers on top.

---

## V2 Features (Out of Scope for V1)

- **Competitor startups** on the map — AI-driven companies solving similar problems, competing for customers, employees, and investors.
- **Difficulty settings** — adjustable starting capital, market volatility, NPC problem quality.
- **Time-travel / fast-forward mechanic** to skip idle periods.
- **Procedurally generated NPC problems** based on real-world data instead of static dialogue.
- **Replayability systems** — randomized market cycles, different starting conditions, multiple endings.
