_      = require 'underscore'
cmd    = require './git'
Commit = require './commit'
Tree   = require './tree'
Diff   = require './diff'
Tag    = require './tag'
Status = require './status'

{Ref, Head} = require './ref'

module.exports = class Repo
  constructor: (@path, @bare) ->
    if @bare
      @dot_git = @path
    else
      @dot_git = "#{@path}/.git"
    @git  = cmd @path, @dot_git
  
  
  # Public: Get a list of commits.
  # 
  # treeish  - String  (optional).
  # limit    - Integer (optional).
  # skip     - Integer (optional).
  # callback - Function which receives `(err, commits)`, where `commits` is
  #            an Array of Commits.
  # 
  # Examples
  # 
  #   # Get the 10 most recent commits to master.
  #   repo.commits (err, commits) ->
  # 
  #   # Or to a different tag or branch.
  #   repo.commits "v0.0.3", (err, commits) ->
  # 
  #   # Limit the maximum number of commits returned.
  #   repo.commits "master", 30, (err, commits) ->
  # 
  #   # Skip some (for pagination):
  #   repo.commits "master", 30, 30, (err, commits) ->
  # 
  commits: (start, limit, skip, callback) ->
    [skip,  callback] = [callback, skip]  if !callback
    [limit, callback] = [callback, limit] if !callback
    [start, callback] = [callback, start] if !callback
    throw new Error "a callback is required" if !callback
    start ?= "master"
    limit ?= 10
    skip  ?= 0
    
    Commit.find_all this, start, {"max-count": limit, skip}, callback
  
  
  # Public: The tree object for the treeish or master.
  # 
  # treeish - String treeish (such as a branch or tag) (optional).
  # 
  # Returns Tree.
  tree: (treeish="master") ->
    return new Tree this, treeish
  
  
  # Public: Get the difference between the trees.
  # 
  # commitA  - A Commit.
  # commitB  - A Commit.
  # paths    - A list of String paths to restrict the difference to (optional).
  # callback - A Function which receives `(err, diffs)`.
  # 
  diff: (commitA, commitB, paths, callback) ->
    [callback, paths] = [paths, callback] if !callback
    paths ?= []
    @git "diff", {}, _.flatten([commitA, commitB, "--", paths])
    , (err, stdout, stderr) =>
      return callback err if err
      return callback err, Diff.parse(this, stdout)
  
  
  # Public: Get the repository's remotes.
  # 
  # callback - Receives `(err, remotes)`.
  # 
  remotes: (callback) ->
    Ref.find_all this, "remote", Ref, callback
  
  # Public: List the repository's remotes.
  # 
  # callback - Receives `(err, names)`.
  # 
  remote_list: (callback) ->
    @git.list_remotes callback
  
  # Public: Add a remote.
  # 
  # name     - String name of the remote.
  # url      - String url of the remote.
  # callback - Receives `(err)`
  # 
  remote_add: (name, url, callback) ->
    @git "remote", {}, ["add", name, url]
    , (err, stdout, stderr) ->
      callback err
  
  # Public: `git fetch <name>`.
  # 
  # name     - String name of the remote
  # callback - Receives `(err)`.
  # 
  remote_fetch: (name, callback) ->
    @git "fetch", {}, name
    , (err, stdout, stderr) ->
      callback err
  
  
  # Public: Get the repository's status (`git status`).
  # 
  # callback - Receives `(err, callback)`
  # 
  status: (callback) ->
    return new Status(this, callback)
  
  
  # Public: Get the repository's tags.
  # 
  # callback - Receives `(err, tags)`.
  # 
  tags: (callback) ->
    Tag.find_all this, callback
  
  # Public: Create a tag.
  # 
  # name     - String
  # callback - Receives `(err)`.
  # 
  create_tag: (name, callback) ->
    @git "tag", {a: name}, callback
  
  # Public: Delete the tag.
  # 
  # name     - String
  # callback - Receives `(err)`.
  # 
  delete_tag: (name, callback) ->
    @git "tag", {d: name}, callback
  
  
  # Public: Get a list of branches.
  # 
  # callback - Receives `(err, heads)`.
  # 
  branches: (callback) ->
    Head.find_all this, callback
  
  # Public: Create a branch with the given name.
  # 
  # name     - String name of the new branch.
  # callback - Receives `(err)`.
  # 
  create_branch: (name, callback) ->
    @git "branch", {}, name, (err, stdout, stderr) ->
      return callback err
  
  # Public: Delete the branch with the given name.
  # 
  # name     - String name of the branch to delete.
  # callback - Receives `(err)`.
  # 
  delete_branch: (name, callback) ->
    @git "branch", {d: true}, name, (err, stdout, stderr) ->
      return callback err
  
  # Public: Get the Branch with the given name.
  # 
  # name     - String (optional). By default, get the current branch.
  # callback - Receives `(err, head)`
  # 
  branch: (name, callback) ->
    [name, callback] = [callback, name] if !callback
    if !name
      Head.current this, callback
    else
      @branches (err, heads) ->
        return callback err if err
        for head in heads
          return callback null, head if head.name == name
        return callback new Error "No branch named '#{name}' found"
  
  
  # Public: Checkout the treeish.
  checkout: (treeish, callback) ->
    @git "checkout", {}, treeish, callback
  
  
  # Public: Commit some code.
  # 
  # message  - String
  # options  - Object (optional).
  #            "amend" - Boolean
  #            "all"   - Boolean
  # callback - Receives `(err)`.
  # 
  commit: (message, options, callback) ->
    [options, callback] = [callback, options] if !callback
    options = _.extend options, {m: message}
    @git "commit", options, (err, stdout, stderr) ->
      callback err
  
  # Public: Add files to the index.
  # 
  # files    - Array of String paths; or a String path.
  # callback - Receives `(err)`.
  # 
  add: (files, callback) ->
    files = [files] if _.isString files
    @git "add", {}, files, callback
  
  # Public: Remove files from the index.
  # 
  # files    - Array of String paths; or a String path.
  # callback - Receives `(err)`.
  # 
  remove: (files, callback) ->
    files = [files] if _.isString files
    @git "rm", {}, files, callback