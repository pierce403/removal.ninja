const fs = require('node:fs');
const path = require('node:path');

const buildDir = path.resolve(process.argv[2] || 'client/build');
const index = path.join(buildDir, 'index.html');
const staticDir = path.join(buildDir, 'assets');

if (!fs.existsSync(index) || !fs.statSync(index).isFile()) {
  throw new Error(`Missing build index: ${index}`);
}
if (!fs.existsSync(staticDir) || !fs.statSync(staticDir).isDirectory()) {
  throw new Error(`Missing Vite assets: ${staticDir}`);
}

function sizeOf(entry) {
  const stat = fs.statSync(entry);
  if (stat.isFile()) return stat.size;
  if (!stat.isDirectory()) return 0;
  return fs.readdirSync(entry).reduce((sum, name) => sum + sizeOf(path.join(entry, name)), 0);
}

const entries = fs.readdirSync(buildDir).map((name) => ({
  name,
  bytes: sizeOf(path.join(buildDir, name)),
}));
entries.sort((a, b) => b.bytes - a.bytes);
for (const { name, bytes } of entries) {
  console.log(`${(bytes / 1024).toFixed(1)} KiB\t${name}`);
}
console.log('Build assets verified.');
