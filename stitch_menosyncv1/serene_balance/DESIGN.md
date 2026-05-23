# The Design System: Editorial Wellness & Tonal Depth

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Serene Curator."** 

We are moving away from the "medical utility" look of traditional trackers and toward a high-end, editorial experience that feels like a premium wellness journal. This system rejects the rigid, boxed-in layouts of standard mobile apps. Instead, we embrace **Intentional Asymmetry** and **Tonal Layering**. 

By utilizing overlapping elements, generous whitespace (the "breathing room"), and a high-contrast typography scale, we create an environment that feels supportive rather than clinical. The goal is to make the user feel seen and cared for, using a visual language that communicates sophistication and calm authority.

---

## 2. Colors: The Art of Tonal Transition
Our palette is rooted in the earth and the sky—Warm Taupe (#9B8B7E) for stability and Soft Lavender (#D8C9E0) for grace.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Traditional "dividers" are a sign of lazy hierarchy. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a `surface-container-low` section should sit directly on a `surface` background to create a soft, edge-less transition.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like fine, heavy-weight paper stacked together.
*   **Base:** `surface` (#fef8f6)
*   **Secondary Content:** `surface-container` (#f2edea)
*   **Elevated Cards:** `surface-container-lowest` (#ffffff) to create a clean, crisp "pop" against the warmer background.

### The "Glass & Gradient" Rule
To elevate the experience beyond "flat design," use **Glassmorphism** for floating elements (like bottom navigation bars or sticky headers). Apply a `surface-variant` with 70% opacity and a `20px` backdrop-blur. 

**Signature Texture:** Main CTAs and Hero backgrounds should use a subtle linear gradient (135°) transitioning from `primary` (#67594e) to `primary-container` (#817266). This adds a "soulful" depth that a flat hex code cannot achieve.

---

## 3. Typography: Editorial Authority
We use a high-contrast pairing to balance empathy with expertise.

*   **Display & Headlines (Noto Serif):** These are our "Editorial Voice." Large-scale serif type conveys trust and a premium feel. Use `display-lg` (3.5rem) for high-impact emotional moments and `headline-md` (1.75rem) for section starts.
*   **Body & Labels (Manrope):** Our "Functional Voice." A clean sans-serif ensures high readability for users in the 45-60 demographic. 
*   **The Hierarchy Shift:** Use `title-lg` (1.375rem) in Manrope for interactive elements, but keep the storytelling to Noto Serif. This distinct separation helps the user intuitively know what is "content" and what is "action."

---

## 4. Elevation & Depth: The Layering Principle
Hierarchy is achieved through **Tonal Layering** rather than structural lines or heavy shadows.

*   **Stacking:** To create a card, place a `surface-container-lowest` shape on a `surface-container` background. This creates a soft, natural lift.
*   **Ambient Shadows:** If an element must "float" (like a FAB), use a shadow with a 24px blur, 0% spread, and 6% opacity. The shadow color must be a tinted version of `on-surface` (#1d1b1a), never pure black.
*   **The "Ghost Border" Fallback:** If a container needs more definition for accessibility, use the `outline-variant` token at **15% opacity**. Never use a 100% opaque border.
*   **Integrated Glass:** Use semi-transparent surface colors for overlays to let the background "glow" through. This makes the UI feel integrated and holistic.

---

## 5. Components: Soft & Intentional

### Buttons
*   **Primary:** Gradient-filled (`primary` to `primary-container`), `xl` (1.5rem) corner radius. Use `title-sm` for the label.
*   **Secondary:** `surface-container-high` background with `on-surface` text. No border.
*   **Tertiary:** Text-only in `primary` weight, used for "Cancel" or "Back" actions.

### Cards & Lists
*   **Anti-Divider Rule:** Forbid the use of divider lines. Separate list items using `spacing-4` (1.4rem) or by alternating background tones between `surface` and `surface-container-low`.
*   **Symptom Cards:** Use `surface-container-lowest` with an `xl` corner radius. Add a subtle `tertiary-fixed` (#ffdad3) accent icon in the top right to indicate the "Peachy Rose" accent.

### Input Fields
*   **Text Inputs:** Use a "Pill" shape (`full` roundedness). The background should be `surface-container-highest` with a `label-md` floating above it. 
*   **Selection Chips:** Use `secondary-container` (#edddf5) for the selected state and `surface-container-high` for unselected.

### Specialized Components
*   **The Progress Veil:** Instead of a standard progress bar, use a soft, expanding gradient "glow" behind the headline to indicate symptom tracking completion.
*   **The Reflection Space:** A dedicated `surface-container-lowest` text area with a Noto Serif italic placeholder, encouraging the user to "Journal your thoughts today."

---

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical padding. Try `spacing-8` on the left and `spacing-6` on the right to create a sophisticated, magazine-like feel.
*   **Do** prioritize whitespace. If a screen feels "full," remove a container background before removing text.
*   **Do** use `rounded-xl` (1.5rem) for most large containers to maintain the "supportive" personality.

### Don’t
*   **Don't** use pure black (#000000) for text. Always use `on-surface` (#1d1b1a) to keep the contrast accessible but soft.
*   **Don't** use standard "Material Design" shadows. They are too aggressive for this brand.
*   **Don't** use 1px dividers. If you need separation, use a `spacing-px` gap that reveals a slightly darker background color.
*   **Don't** crowd the edges. Keep a minimum of `spacing-5` (1.7rem) horizontal margin on all mobile screens.