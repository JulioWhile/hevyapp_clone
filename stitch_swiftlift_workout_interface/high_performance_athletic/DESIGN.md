---
name: High-Performance Athletic
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c1c6d7'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8b90a0'
  outline-variant: '#414755'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e69'
  primary-container: '#4b8eff'
  on-primary-container: '#00285c'
  inverse-primary: '#005bc1'
  secondary: '#53e16f'
  on-secondary: '#003911'
  secondary-container: '#05b046'
  on-secondary-container: '#003a11'
  tertiary: '#ffb874'
  on-tertiary: '#4b2800'
  tertiary-container: '#d47b00'
  on-tertiary-container: '#412200'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004493'
  secondary-fixed: '#72fe88'
  secondary-fixed-dim: '#53e16f'
  on-secondary-fixed: '#002107'
  on-secondary-fixed-variant: '#00531c'
  tertiary-fixed: '#ffdcbf'
  tertiary-fixed-dim: '#ffb874'
  on-tertiary-fixed: '#2d1600'
  on-tertiary-fixed-variant: '#6a3b00'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-metric:
    fontFamily: Lexend
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Lexend
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Lexend
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.5'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-bold:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '700'
    lineHeight: '1.2'
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 20px
  gutter: 12px
  touch-target-min: 44px
---

## Brand & Style

The design system is engineered for elite performance and focus. It adopts a **Minimalist-High-Contrast** style, stripping away visual noise to prioritize biometric data and progress tracking. The personality is professional and efficient, mirroring the mindset of a dedicated athlete. 

The interface utilizes a "dark-first" philosophy to reduce eye strain in varying gym lighting conditions while allowing primary action colors to pop with maximum vibrance. The aesthetic is clean, utilizing sharp data visualizations and a rigorous grid to convey a sense of precision and reliability.

## Colors

This design system utilizes a deep monochromatic base to create a high-contrast environment. 

- **Primary (Electric Blue):** Reserved for core interactions, primary buttons, and active state indicators.
- **Success (Green):** Specifically used for completed sets, workout finishers, and "Goal Met" states.
- **Accent (Warm Orange):** Applied to time-sensitive elements like rest timers, personal records (PRs), and high-intensity alerts.
- **Neutrals:** The background is a near-black (#121212) to ensure OLED efficiency and readability. Grays are used strictly for hierarchy in labels and borders.

## Typography

The typography system prioritizes legibility at a distance. 

- **Lexend** is used for headings and key performance metrics (Weight, Reps, Time) due to its athletic, open character design and superior readability. 
- **Inter** handles all body copy and functional labeling to maintain a clean, systematic feel.
- **Metric Emphasis:** Key numbers should always use `display-metric` with a bold weight to ensure they are the first thing a user sees while training.

## Layout & Spacing

This design system employs a **Fluid Grid** model with a base-4 rhythm. 

- **Margins:** 20px side margins are used on mobile to keep content away from the bezel.
- **Touch Targets:** A strict minimum of 44px for all interactive elements, though 56px is preferred for primary workout actions to accommodate sweaty or shaky hands.
- **Thumb Zone:** Primary actions (Start Workout, Log Set, Finish) must be placed in the bottom 30% of the screen for effortless one-handed use.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** rather than heavy shadows. 

1. **Background (#121212):** The furthest back layer.
2. **Surface (#1C1C1E):** Used for cards and primary content containers.
3. **Surface-Elevated (#2C2C2E):** Used for modal overlays or active input fields.
4. **Borders:** Subtle 1px solid borders (#38383A) define card boundaries.

Shadows should be used sparingly, only to lift floating action buttons or active drag-and-drop elements, using a 15% opacity black with a 12px blur and 4px offset.

## Shapes

The design system uses **Soft (0.25rem)** roundedness to maintain a disciplined, professional appearance that isn't overly playful. 

- **Standard Buttons & Inputs:** 4px (0.25rem) radius.
- **Cards:** 8px (0.5rem) radius to distinguish them from smaller UI elements.
- **Status Indicators:** Fully rounded (pill) shapes for "Resting" or "Active" tags to provide a soft visual contrast to the rigid metrics.

## Components

- **Buttons:** Primary buttons use `Electric Blue` with white text. High-priority "Log Set" buttons should span the full width of the container.
- **Workout Cards:** Use a background of `#1C1C1E` with a `#38383A` border. Headers within cards should use `label-bold` in a muted gray.
- **Metric Toggles:** Large, segmented controls for switching between Lbs/Kgs or RPE scales.
- **Status Indicators:** Use `Success Green` for completed set dots and `Warm Orange` for the countdown timer progress bar.
- **Inputs:** Numeric inputs for weight/reps should trigger the numeric keypad immediately and feature large "-" and "+" steppers (min 44x44px).
- **Progress Bars:** Thin, high-contrast lines that fill with color as the workout completion percentage increases.