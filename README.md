NDIS Connect – Flutter App (VS Code + BMAD)

Vision: An accessible, trustworthy companion for NDIS participants and providers to navigate plans, track budgets, access services, collaborate, and stay informed — with offline-first resilience for rural users and enhanced voice accessibility.

BMAD Roles

- Master (M): Set NDIS vision, define user stories, ensure WCAG 2.2 AA compliance and privacy.
- Scrum Master (SM): Orchestrate sprints, manage VS Code Tasks, uphold CI checks.
- Developer (DEV): Implement Flutter MVVM features, integrate Firebase/Maps/Dialogflow/Stripe.
- QA: Test accessibility, performance, offline sync, unit/integration, and user journeys.

BMAD Phases

- Brainstorm (B):
  - Core: Dual dashboards, budget tracker, smart calendar, plan checklist, service map, provider hub, support circle.
  - Accessibility: Voice input/output (speech_to_text, flutter_tts), high-contrast, resizable text, TalkBack/VoiceOver labels.
  - Trust & Safety: Biometric unlock, data encryption at rest (Hive + encrypt + secure storage), privacy controls.
  - Engagement: NDIS Champion points, A/B badges via Remote Config, community forum, wearable goal tracking.
  - Resilience: Offline caches (Hive), conflict resolution, queued writes, retry/backoff, background sync.
  - Compliance: Clear consent, auditable logs, least-privilege access rules.
  - Extra: Emergency Support button, tutorial walkthroughs for low digital literacy.
- Map (M):
  - Architecture: Flutter + MVVM with Provider; Firebase (Auth, Firestore, Functions, Messaging, Analytics, Remote Config, Storage); Google Maps API; Dialogflow via Cloud Functions; Stripe for premium subscriptions.
  - Layers: models → services → viewmodels → widgets/screens. DI with get_it or simple factories. Feature flags via Remote Config.
- Analyze (A):
  - Risks: Offline conflicts, data privacy, cost scaling, quota limits, rural connectivity, accessibility regressions, wearable OAuth, vendor dependence.
  - Mitigations: Local-first writes + backoff; encryption + minimum PII; budget sharding strategy; Remote Config kill switches; a11y checklists in PRs; token rotation.
- Develop (D):
  - Sprint 0: Scaffold app, theming, localization, auth/analytics/remote-config stubs, emergency button.
  - Sprint 1: Dual dashboards + role-based auth.
  - Sprint 2: Smart scheduling + reminders.
  - Sprint 3: Budget tracker + alerts.
  - Sprint 4: AI chatbot + voice.
  - Sprint 5: Service map + offline.
  - Sprint 6: Support circle + collaboration.
  - Sprint 7: Plan snapshot + PDF export.
  - Sprint 8: Provider hub + NDIA submissions.

Setup – Prereqs

- Install: Flutter SDK, Android Studio/Xcode, VS Code, Android/iOS toolchains.
- VS Code extensions (auto-recommended): Flutter, Dart, Firebase, GitLens, Prettier, Bracket Pair Colorizer, Accessibility Insights (axe-linter), GitHub Copilot.
- CLIs: Node.js LTS, Firebase CLI, FlutterFire CLI, Git.

Terminal Commands (Windows PowerShell)

1. Create project
   flutter create ndis_connect
   cd ndis_connect

2. Add FlutterFire CLI and core Firebase libs
   dart pub add firebase_core firebase_auth cloud_firestore firebase_messaging firebase_analytics firebase_storage firebase_functions firebase_remote_config

3. Maps, AI, voice, localization, payments, a11y, offline, security
   dart pub add google_maps_flutter dialog_flowtter flutter_tts speech_to_text flutter_localizations intl flutter_stripe provider get_it http connectivity_plus hive hive_flutter path_provider encrypt flutter_secure_storage local_auth charts_flutter timeline_tile pdf url_launcher share_plus

4. Wearables (optional) + testing
   dart pub add wear
   dart pub add --dev flutter_test integration_test build_runner

5. Firebase tooling
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   flutterfire configure # then add iOS/Android apps

6. Stripe setup (flutter_stripe)

   # Android: add payment activity + Gradle config per docs

   # iOS: add URL scheme and merchant ID

7. Google Maps keys

   # Android/iOS manifest and AppDelegate entitlements per plugin docs

8. Run
   flutter pub get
   flutter run -d chrome # or connected device

9. Git (version control)
   git init
   git add .
   git commit -m "chore: scaffold NDIS Connect"

Workspace Structure

- .vscode: editor settings, tasks
- ndis_connect/pubspec.yaml: Flutter deps
- ndis_connect/lib/main.dart: app entry
- ndis_connect/lib/app.dart: MaterialApp + theming + l10n
- ndis_connect/lib/screens/: splash, login, dashboard, settings, feedback, tutorial
- ndis_connect/lib/services/: auth, analytics, remote_config, storage_encryption, tts, maps, chatbot, wearable, payments
- ndis_connect/lib/l10n/: ARB files, generated localizations

Firestore Structure (proposed)

- users/{uid}: profile, role, settings
- plans/{uid}/years/{yyyy}: budgets, goals
- tasks/{uid}/{taskId}: checklist items
- schedules/{uid}/{eventId}: appointments
- messages/{threadId}/{messageId}: forum/support circle
- points/{uid}: gamification
- feedback/{uid}/{feedbackId}

Remote Config (examples)

- points_enabled: true
- ai_assist_level: basic|premium
- ab_badge_variant: A|B

Security & Privacy

- Auth: Firebase Auth + local_auth biometrics gate.
- Data: Encrypt local Hive boxes using key in secure storage; encrypt sensitive payloads as needed.
- Rules: Firestore rules enforcing role-based access and least privilege.
- Telemetry: Firebase Analytics with privacy toggles and minimal PII.

Testing & Release

- Tests: flutter test, golden tests for widgets, integration_test for Firebase flows.
- a11y: Semantics, labels, large fonts, color contrast checks.
- Beta: Firebase App Distribution.
- Stores: Play Store/App Store submissions with privacy details.

Notes

- Dialogflow packages vary; if dialog_flowtter is unavailable, consider dialogflow_grpc via Functions proxy.
- Stripe: prefer flutter_stripe; stripe_platform_interface is low-level.
- Indigenous languages require community review; ARB placeholders provided.
