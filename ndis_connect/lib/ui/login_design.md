# Login Screen — BMAD Blueprint

Blueprint

- Purpose: Offer a clear, accessible entry for participants and providers to sign in.

- Audience: users with a wide range of abilities including low vision, cognitive impairments, and motor differences.

- Success criteria:
  - WCAG AA contrast for all text and interactive controls.
  - Touch targets >= 44pt.
  - Keyboard / screen reader friendly.
  - Fast path for returning users (e.g., biometric / persistent session).

Design tokens

- Spacing: use DesignTokens.spacing / spacingSmall

- Primary action: PrimaryButton (strong, filled)

- Secondary action: GhostButton (outlined)

Layout

- Top area: app logo + friendly heading

- Middle: email field, password field with show/hide, 'forgot password' link

- Bottom: primary sign-in button, secondary 'create account' link

Accessibility notes

- Form fields must have labels and error text.

- Use AccessibleIconButton for 'show password' and other icons.

- Announce form errors with semantics.

Make

- Implement `LoginScreen` using `InputField`, `PrimaryButton`, and `AccessibleIconButton`.

Assess

- Run `flutter analyze` and manual keyboard & screen-reader checks.

Deliver

- Finalize files: `login_design.md` (this file), updated `login_screen.dart`, and unit test stubs.
