# EnvironmentRestore.jl

`EnvironmentRestore.jl` creates a Julia environment that can use your package at a specific commit, instead of the latest version. For example, this can be used to set up reproducible numerical experiments.

## Usage
`archiveEnvironment(packages :: Pair{String, String}...)` takes arguments of the form `path1 => commitHash1, path2 => commitHash2, ...` where the paths are the file paths to your repositories.

Optional keyword arguments are 
- `dir :: String`: the directory in which to store the environment
- `force :: Bool`: whether or not any existing environment should be overwritten

`restoreEnvironment` Restores the archived environment, with the directory as an optional argument. The environment will only be active during the current Julia session.

You can also enforce that the current working directory is on a specific commit and there are no untracked changes. This can be done with the commands `requireGitCommit(commit; strict=true)` and `requireCleanWorkingTree(;strict=true)`.
