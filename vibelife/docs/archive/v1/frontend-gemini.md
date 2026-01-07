# Frontend Engineering Guide: VibeLife "Luminous Paper"
> **Target Status**: World Class Mobile-First Experience + Agent-Driven PC Immersion
> **Aesthetic Benchmark**: Apple Journal / Apple Books / Paper by WeTransfer
> **Core Metaphor**: Magical Realism (Oriental Mysticism meets Modern Physics)

## 1. Design Philosophy & Physics

### 1.1 "Luminous Paper" Texture
*   **Grain & Surface**: CSS Noise Texture + `mix-blend-mode: multiply` on `#FBF7F1`.
*   **Lighting**: Diffuse, warm backlighting. No neon.
*   **Ink Physics**: `blur(4px) -> blur(0)` text rendering animation.

### 1.2 "Zen Breath" Motion
*   **Frequency**: Very low (0.05Hz).
*   **Physics**: Spring-based (framer-motion). No linear easing.

---

## 2. Component Architecture (Mobile First)

### 2.1 "Ritual" Input Capsule (**P0**)
*   **Interaction**: Expansion on focus, breathing easing.
*   **Feedback**: Subtle haptics (where available).

### 2.2 "Deduction" Transition (**P0**)
*   **Bridge**: 1.5s - 2s animation linking Input to Insight.
*   **Variants**:
    *   `bazi`: Concentric Rings (Stone/Jade).
    *   `zodiac`: Star Connection (Constellation Lines).
    *   `mbti`: Spectrum Shift (Prism).

### 2.3 Insight Cards: "Gems in the Stream" (**P0**)
*   **Visual**: Inline with chat, distinct sheen, subtle shadow.
*   **Interaction**: **Click to Expand** via **Bottom Sheet (Vaul)**. Never use center modals.

### 2.4 Proactive Care: "In-App Presence" (**P0**)
*   **Strategy**: **No Push Notifications**.
*   **Implementation**: **"Daily Vibe Greeting"**.
    *   On app open, check `DailyFortuneState`.
    *   If significant event (e.g., Solar Term, Mercury Retrograde), render a special **"Greeting Card"** at the top of the chat or landing page.
    *   *Example*: "Happy Li Chun. The energy of Wood rises today."

### 2.5 Native Mobile Nav (**P0**)
*   **Structure**: `BottomNav` (Chat | Chart | Journey | Me).
*   **Feel**: App-like persistence.

---

## 3. PC Deep Optimization: Agent-Driven Workbench

### 3.1 Layout: The Context-Aware Study
*   **Left**: Navigation & History.
*   **Center**: Focus Chat (`max-w-3xl`).
*   **Right**: **Dynamic Insight Panel (Agent-Driven UI)**.

### 3.2 Agent-to-UI (A2UI) Concept
*   **Philosophy**: The Agent controls the UI state, not just text generation.
*   **Mechanism**:
    *   Backend sends `ui_directive` alongside message stream.
    *   *Example*: `{"view": "transit_chart", "focus": "2026"}`.
    *   **Frontend Reaction**: Right panel smoothly transitions to the requested view.
*   **Granularity**: **Scheme A (View Level)**. Switch entire views (e.g., `DefaultChart` -> `TransitGraph`) for stability.
*   **Protocol**: **Vercel AI SDK 6 Data Stream**.

---

## 4. Advanced Features: Identity, Social & Action (New)

### 4.1 "The Mirror Toggle": Jungian Identity Framework
*   **Core Concept**: Map all skills to a **Persona (Outer)** vs **Self (Inner)** structure.
*   **UI Implementation**:
    *   A physical toggle on the Profile/Chart page.
    *   **State A (Outer/Yang)**: The Mask. (Bazi: Pattern/Structure, Zodiac: Rising). Bright, crisp UI.
    *   **State B (Inner/Yin)**: The Soul. (Bazi: Day Master/Root, Zodiac: Moon). Darker, softer, glowing UI.

### 4.2 "Relationship Simulator": Privacy-First Connection
*   **Visual First**: Before text, show the physics.
    *   Two Vibe Glyphs colliding/merging.
    *   Result: A **"Third Glyph"** representing the relationship itself.
*   **Modes**:
    *   **Solo**: Input partner's data manually.
    *   **Vibe Link (P2P)**: Share a link/QR.
        *   **Privacy**: **Zero Data Exchange**. Only the computed *Synergy Score* & *Dynamics* are shared. Underlying birth data remains local/private.
        *   **View**: Each user sees "How *I* should treat *Them*".

### 4.3 "The Action Step": Micro-Quests & Journey
*   **Dual Layer Architecture**:
    *   **Layer 1 (Chat)**: **Micro-Quest Cards**.
        *   "Today's Challenge: Reject one unreasonable request." (For weak Boundaries).
        *   Simple checkbox interaction. Visual reward (Glyph brightness up).
    *   **Layer 2 (Journey Tab)**: **Evolution Tree**.
        *   Long-term plans (e.g., "7-Day Confidence Bootcamp").
        *   Visualizes growth over time.

---

## 5. Engineering Roadmap

### Phase 1: The "Feel" & "Ritual" (Foundation) - **Current**
1.  **Luminous Paper Layout**: Global texture & typography.
2.  **Birth Input Capsule**: The ritual entry point.
3.  **Deduction Overlay**: The transition animation.
4.  **Bottom Nav**: Mobile app structure.

### Phase 2: The "Insight" & "Care" (Value)
5.  **Insight Card + Drawer**: `vaul` integration.
6.  **Daily Vibe Greeting**: Logic to fetch and display proactive in-app messages.
7.  **Markdown Ink Blur**: Text streaming physics.

### Phase 3: The "Workbench" (PC Mastery)
8.  **A2UI Panel**: Implement Vercel AI SDK Data Stream handler & Dynamic Panel.

### Phase 4: Expansion (Identity & Action)
9.  **Mirror Toggle**: Jungian view switching logic.
10. **Action System**: Quest card component & Journey Tab layout.

### Phase 5: Social (Connection)
11. **Relationship Simulator**: Glyph physics engine & Vibe Link flow.

---

This document serves as the implementation source of truth.