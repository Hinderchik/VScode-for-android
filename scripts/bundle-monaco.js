const fs = require('fs-extra');
const path = require('path');

const src = path.join(__dirname, '..', 'node_modules', 'monaco-editor', 'min', 'vs');
const dest = path.join(__dirname, '..', 'assets', 'monaco', 'vs');

fs.removeSync(dest);
fs.copySync(src, dest);
console.log('Monaco Editor bundled to assets/monaco/vs');
