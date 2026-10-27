Orbit
======

My personal time tracking and goal setting app

## Backend HTTP requests

Set `BACKEND_BASE_URL` in `Config/development.xcconfig` (see the example file).
The checked-in Info.plist passes it to `BackendClient`. For the iOS Simulator,
use `http:/$()/localhost:8000`; the `/$()/` syntax preserves URL slashes in xcconfig.
Start the backend with `make dev` in the sibling `Orbit_backend` repository.

On a physical iPhone or iPad, use your Mac's local hostname, for example
`http:/$()/My-Mac.local:8000`, and connect both devices to the same network.
Run the backend listening on `0.0.0.0` and allow incoming connections through
the Mac firewall. Accept Orbit's local-network permission prompt on the device.
The app permits local HTTP via `NSAllowsLocalNetworking`; use an HTTPS backend
URL for deployment. No global App Transport Security bypass is enabled.

## Development Prerequisites

This project uses a `Makefile` to run tests, linting, and formatting tasks. Make sure `make` is installed and available on your `PATH` before using the project commands.

On macOS, `make` is typically provided by Xcode Command Line Tools:

```bash
xcode-select --install
```

Common development commands:

```bash
make test
make test-unit
make test-ui
make lint
make format
make style
```

## Coding Agent Skills

The repository includes four coding agent skills in [`.agents/skills`](.agents/skills). Each skill provides a `SKILL.md` entry point and supporting reference material for writing and reviewing Swift code. These are development guidance for coding agents, not app dependencies.

| Skill | When to use it |
| --- | --- |
| [swiftui-pro](.agents/skills/swiftui-pro/SKILL.md) | Building or reviewing SwiftUI views, data flow, navigation, accessibility, and performance across the app's platform-specific surfaces. |
| [swift-concurrency-pro](.agents/skills/swift-concurrency-pro/SKILL.md) | Working with async/await, actor isolation, structured concurrency, task cancellation, and Swift 6.2 concurrency diagnostics. |
| [swift-testing-pro](.agents/skills/swift-testing-pro/SKILL.md) | Writing or reviewing Swift Testing unit and integration tests, including assertions, dependency injection, and async behavior. Its guidance retains XCTest for UI tests. |
| [swiftdata-pro](.agents/skills/swiftdata-pro/SKILL.md) | Adding or reviewing SwiftData persistence, including models, relationships, predicates, indexing, and CloudKit constraints when applicable. |

To request a focused review, name the relevant skill in your coding agent prompt. For example:

```text
Use swift-concurrency-pro to review TimerEngine for actor isolation and cancellation issues.
Use swift-testing-pro to add unit tests for timer phase transitions.
Use swiftui-pro to review the timer views for accessibility and data flow.
```

Agents should read the relevant `SKILL.md` and load the supporting references needed for the task. Use these skills alongside [AGENTS.md](AGENTS.md), which documents the repository's architecture, coding conventions, and testing expectations.

The bundled skills are authored by Paul Hudson and distributed under the MIT license. [skills-lock.json](skills-lock.json) records their upstream GitHub sources, skill paths, and content hashes; consult it when tracking the installed skill sources or reviewing updates.

## Continuous integration

[App CI](.github/workflows/ci.yml) runs on pushes, pull requests, and manual
workflow dispatches. It builds and runs unit tests on iOS 26 Simulator and macOS
using Xcode 26.6 on `macos-26`. The shared Orbit scheme is checked in so fresh
clones can run tests. Each platform uploads its build log and `.xcresult` bundle
for 14 days, including when tests fail. UI tests remain available locally.

CI copies the example configuration using placeholder credentials; no GitHub
secrets or signing certificates are required. These checks do not deploy the app.

### Run GitHub Actions locally

Install [act](https://nektosact.com/installation/) to use the `make act*`
commands (`brew install act` on macOS). Run these from this repository:

```sh
make act              # Run all CI jobs for a push
make act-pr           # Run all CI jobs for a pull request
make act-list         # List workflow jobs
make act-dryrun       # Preview execution without running job steps
make act-style        # Formatting and lint
make act-test         # Unit tests and analysis for iOS and macOS
make act-test-ios     # iOS only
make act-test-macos   # macOS only
```

The `macos-26` runner maps to your Mac using `-self-hosted`; these jobs run
directly on the host and can install Homebrew tools. Install Xcode and an iOS 26
simulator first. The workflow currently expects Xcode at
`/Applications/Xcode_26.6.app/Contents/Developer`. It also copies the example
configuration over `Config/development.xcconfig` in act's execution workspace.
Docker is not required for these native host jobs.

Pass additional options with `ACT_FLAGS`, for example:

```sh
make act-style ACT_FLAGS="--verbose"
```

`ACT` overrides the executable. Uploaded workflow artifacts are saved under
`/tmp/Orbit-act-artifacts`; override this with `ACT_ARTIFACT_DIR`.
The commands use `--env-file /dev/null` so act does not automatically load the
application's `.env`. Supply an explicit env file through `ACT_FLAGS` if needed.
Local runs use your working tree; GitHub-hosted CI remains the final check for
runner and action compatibility.
