#!/usr/bin/env bash

jq -r '
  # Flatten to [{repo, component, count}]
  [ to_entries[] | .key as $repo | (.value.components // .value) | to_entries[] |
    { repo: $repo, component: .key, count: (.value.instances | length) }
  ]
  | group_by(.component)[]
  | { component: .[0].component, total: (map(.count) | add), repos: length }
  | [.component, .total, .repos]
  | @tsv
' adoption-report.json \
| sort -t$'\t' -k2 -rn \
| awk 'BEGIN { print "| Component | Total Instances | Repos Using It |"; print "| --- | --- | --- |" }
       { printf "| %s | %s | %s |\n", $1, $2, $3 }'

echo ""
echo "## React Versions"
echo ""
jq -r '
  [ to_entries[] | .key as $repo | .value.reactVersions[]? |
    [$repo, .packagePath, .section, .version] | @tsv
  ]
  | .[]
' adoption-report.json \
| sort -t$'\t' -k4 -V \
| awk 'BEGIN { print "| Repository | Package | Section | React Version |"; print "| --- | --- | --- | --- |" }
       { printf "| %s | %s | %s | %s |\n", $1, $2, $3, $4 }'
