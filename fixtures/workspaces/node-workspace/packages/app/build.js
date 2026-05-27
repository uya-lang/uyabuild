const fs = require("fs");
const path = require("path");

const message = require("@sample/lib");
const outDir = path.resolve(__dirname, "..", "..", "dist", "app");

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, "message.txt"), `${message}\n`);
