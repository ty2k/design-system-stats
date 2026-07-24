#!/usr/bin/env node
// Requires: npm install -g react-scanner
// Usage: node scan-repo.mjs <path-to-repo>
import scanner from "react-scanner";
import path from "path";

const repoPath = process.argv[2];
if (!repoPath) {
  console.error("Usage: node scan-repo.mjs <path-to-repo>");
  process.exit(1);
}

// react-scanner unconditionally console.log()s a timing line to stdout:
// "Scanned X files in Y seconds"
// Intercept it so it doesn't corrupt our JSON output.
const originalLog = console.log;
console.log = (...args) => {
  const msg = args[0];
  if (typeof msg === "string" && msg.startsWith("Scanned ")) {
    console.error(msg); // redirect to stderr so scan-org.sh can still show it
    return;
  }
  originalLog(...args);
};

let result;
try {
  result = await scanner.run({
    crawlFrom: repoPath,
    exclude: ["node_modules", ".git", "dist", "build", "coverage"],
    globs: ["**/*.{js,jsx,ts,tsx}"],
    includeSubComponents: true,
    importedFrom: "@bcgov/design-system-react-components",
    processors: [({ report }) => report],
  });
} catch (e) {
  // scanner throws if no files are found — treat as empty result
  result = {};
}

process.stdout.write(JSON.stringify(result ?? {}));
