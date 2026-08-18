#!/usr/bin/env bash

# A repo counts as an adopter if it imports components or declares the library as a dependency.
USES_LIBRARY='def uses_library: ((.components // {}) | length > 0) or (((.designSystemVersions // []) | length) > 0);'

echo ""
echo "## Component usage"
echo ""
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
echo "## React versions for repos using the component library"
echo ""
jq -r "$USES_LIBRARY"'
  [ to_entries[] | select(.value | uses_library) | .key as $repo | .value.reactVersions[]? |
    [$repo, .packagePath, .section, .version] | @tsv
  ]
  | .[]
' adoption-report.json \
| sort -t$'\t' -k4 -V \
| awk 'BEGIN { print "| Repository | Package | Section | React Version |"; print "| --- | --- | --- | --- |" }
       { printf "| %s | %s | %s | %s |\n", $1, $2, $3, $4 }'

echo ""
echo "## React versions for all \`bcgov\` repos"
echo ""
jq -r "$USES_LIBRARY"'
  [ to_entries[] | .key as $repo | (.value | uses_library) as $uses |
    .value.reactVersions[]? |
    [$repo, .packagePath, .section, .version, (if $uses then "✅" else "❌" end)] | @tsv
  ]
  | .[]
' adoption-report.json \
| sort -t$'\t' -k4 -V \
| awk -F'\t' 'BEGIN { print "| Repository | Package | Section | React Version | Uses Component Library |"; print "| --- | --- | --- | --- | --- |" }
       { printf "| %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5 }'
