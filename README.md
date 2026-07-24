# Design System Stats

## Install

### Install `gh` and `jq`

### Install `react-scanner`

`npm install`

## Run

1. `npm run find-adopters` to generate `adopting-repos.txt`
2. `npm run scan-org` to clone each repo in the org, scan it, and generate `adoption-report.json`
3. `npm run summarize` to generate a Markdown table showing component usage `summary.md`
