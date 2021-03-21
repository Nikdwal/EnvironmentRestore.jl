module EnvironmentRestore

    export archiveEnvironment, restoreEnvironment
    using Pkg

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

    restoreEnvironment(dir=pwd()) = Pkg.activate(dir)

end
