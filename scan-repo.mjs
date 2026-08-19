#!/usr/bin/env node
// Usage: node scan-repo.mjs <path-to-repo>
import scanner from "react-scanner";
import { readdir, readFile } from "fs/promises";
import path from "path";

const repoPath = process.argv[2];
if (!repoPath) {
  console.error("Usage: node scan-repo.mjs <path-to-repo>");
  process.exit(1);
}

const ignoredDirectories = new Set([
  "node_modules",
  ".git",
  "dist",
  "build",
  "coverage",
]);
const dependencySections = [
  "dependencies",
  "devDependencies",
  "peerDependencies",
  "optionalDependencies",
];
const designSystemPackage = "@bcgov/design-system-react-components";

async function findDependencyVersions(directory, relativeDirectory = ".") {
  let entries;

  try {
    entries = await readdir(directory, { withFileTypes: true });
  } catch {
    console.warn(
      `No version info for directory ${directory} and relativeDirectory ${relativeDirectory}`,
    );
    return { reactVersions: [], designSystemVersions: [] };
  }

  const reactVersions = [];
  const designSystemVersions = [];

  for (const entry of entries) {
    if (entry.isDirectory() && !ignoredDirectories.has(entry.name)) {
      const child = await findDependencyVersions(
        path.join(directory, entry.name),
        path.join(relativeDirectory, entry.name),
      );
      for (const v of child.reactVersions) reactVersions.push(v);
      for (const v of child.designSystemVersions) designSystemVersions.push(v);
    }

    if (entry.isFile() && entry.name === "package.json") {
      try {
        const packageJson = JSON.parse(
          await readFile(path.join(directory, entry.name), "utf8"),
        );
        const packagePath = path.join(relativeDirectory, entry.name);
        for (const section of dependencySections) {
          const reactVersion = packageJson[section]?.react;
          if (reactVersion) {
            reactVersions.push({ packagePath, section, version: reactVersion });
          }

          const designSystemVersion =
            packageJson[section]?.[designSystemPackage];
          if (designSystemVersion) {
            designSystemVersions.push({
              packagePath,
              section,
              version: designSystemVersion,
            });
          }
        }
      } catch {
        // Ignore malformed package manifests so component scanning can continue.
      }
    }
  }

  return { reactVersions, designSystemVersions };
}

const { reactVersions, designSystemVersions } =
  await findDependencyVersions(repoPath);

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
    importedFrom: designSystemPackage,
    processors: [({ report }) => report],
  });
} catch (e) {
  // scanner throws if no files are found — treat as empty result
  result = {};
}

process.stdout.write(
  JSON.stringify({
    reactVersions,
    designSystemVersions,
    components: result ?? {},
  }),
);
