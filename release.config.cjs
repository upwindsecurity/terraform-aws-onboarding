// Using release.config.cjs at root level because no --config flag is available
// to specify the actual config location in .config directory.
module.exports = require("./.config/.releaserc.json");
