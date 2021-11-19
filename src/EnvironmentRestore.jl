module EnvironmentRestore

    export archiveEnvironment, restoreEnvironment, requireGitCommit, requireCleanWorkingTree
    using Pkg

    """
        archiveEnvironment(packages :: Pair{String, String}...)

    Creates a Julia environment that can use your package at a specific commit. The environment
    is defined by the files Project.toml and Manifest.toml.

    Arguments:
    - `packages`: specified in the form `path1 => commitHash1, path2 => commitHash2, ...` where the paths are the file paths to your repositories.

    Keyword arguments are
    - `dir :: String`: the directory in which to store the environment
    - `force :: Bool`: whether or not any existing environment should be overwritten
    """
    function archiveEnvironment(packages :: Pair{String, String}... ;dir=pwd(), force=false)
        projectFiles = ["Project.toml", "Manifest.toml"]
        if !force && !isempty(intersect(readdir(dir), projectFiles))
           print("Directory already contains Julia project files.\nRun with keyword argument ")
           printstyled("force = true", color=:cyan)
           println(" to overwrite.")
           return
        end

        # Start from a copy of the default environment (normally ~/.julia/environments/vX.Y)
        env = dirname(Base.active_project())
        for projFile ∈ projectFiles
            cp(joinpath(env, projFile), joinpath(dir, projFile); force=true)
        end

        # Add packages to the new environment
        try
            Pkg.activate(dir)
            for (path, commit) ∈ packages
                Pkg.add(path=path, rev=commit)
            end
        catch e
            printstyled(stderr, "\nERROR: ", bold=true, color=:red)
            println("Modifying the new environment " * dir * " caused the following error: ")
            throw(e)
        finally
            Pkg.activate(env)
        end

        printstyled(" Successfully archived ", bold=true, color=:green)
        println("environment in ", joinpath(dir, "Manifest.toml"), ".")
    end

    """
        restoreEnvironment(dir=pwd())

    Restore the environment to the specified directory.
    """
    function restoreEnvironment(dir=pwd())
        Pkg.activate(dir)
        Pkg.instantiate(verbose=true)
    end

    """
        requireGitCommit(commit; strict=true)

    Check if the current commit matches the given (full) commit hash.
    If there is a match, this does nothing.
    Otherwise, if strict = true, this causes an error that interrupts the program.
    If strict = false, this asks the user for permission to continue instead of showing an error.
    """
    function requireGitCommit(commit; strict=true)
        currentCommit = chomp(read(`git rev-parse HEAD`, String))
        currentCommit ==  commit && return

        printstyled("┌ Required commit: ", bold=true, color=:yellow)
        println(commit)
        printstyled("└ Active commit:   ", bold=true, color=:yellow)
        println(currentCommit)

        if !strict
            print("Proceed anyway? (y/N) ")
            readline() == "y" && return
        end
        println("")
        error("Commit requirement not satisfied.")
    end

    """
        requireCleanWorkingTree(;strict=true)

    Check if the Git working tree is clean.
    If it is clean, this does nothing.
    Otherwise, if strict = true, this causes an error that interrupts the program.
    If strict = false, this asks the user for permission to continue instead of showing an error.
    """
    function requireCleanWorkingTree(;strict=true)
        cmd = `git status --short`
        modifiedFiles = read(cmd, String)
        isempty(modifiedFiles) && return

        printstyled("Working tree is not clean. The following files have been changed:\n", color=:yellow)
        run(cmd)
        if !strict
            print("Proceed anyway? (y/N) ")
            readline() == "y" && return
        end
        println("")
        error("Working tree requirement not satisfied.")
    end

end
