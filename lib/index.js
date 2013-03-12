(function() {
  var Git, Repo, exec;

  exec = require('child_process').exec;

  Repo = require('./repo');

  module.exports = Git = function(path, bare) {
    if (bare == null) {
      bare = false;
    }
    return new Repo(path, bare);
  };

  Git.init = function(path, callback) {
    return exec("git init .", {
      cwd: path
    }, function(err, stdout, stderr) {
      if (err) {
        return callback(err);
      }
      return callback(err, new Repo(path));
    });
  };

}).call(this);