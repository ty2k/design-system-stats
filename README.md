# Design System Stats

This is used to generate stats about the B.C. Design System's React component library and its use in the `bcgov` GitHub organization.

Note that this will use your `gh` credentials to pull each repo using the library from GitHub, so you'll likely get rate-limited trying to run it too frequently.

## Install

### Install `gh` and `jq`

### Install `react-scanner`

`npm install`

## Run

1. `npm run find-react-repos` to generate `react-repos.txt`, which lists every repo in the org whose `package.json` declares `react` and/or the component library
2. `npm run scan-org` to clone each repo in the org, scan it, and generate `adoption-report.json`
3. `npm run summarize` to generate Markdown tables showing component usage and each project's declared React version in `summary.md`

The scan records every `react` and `@bcgov/design-system-react-components` declaration in `dependencies`, `devDependencies`, `peerDependencies`, and `optionalDependencies`, including manifests in monorepos.

`summary.md` contains three tables: component usage, React versions for repos using the component library, and React versions for all React repos with a ✅/❌ column indicating whether the component library is used.
