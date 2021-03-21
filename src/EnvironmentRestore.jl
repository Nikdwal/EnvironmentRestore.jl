module EnvironmentRestore

    using TOML
    export verify_uuid, restore_commit!, @useRestored

    repo      = chomp(String(read(`git rev-parse --show-toplevel`)))
    toml_file = joinpath(repo, "Project.toml")
    pkg_info  = TOML.parsefile(toml_file)

    Base.active_project() == toml_file || @warn "Environment is not set up to " * pkg_info["name"] * ". Start Julia with \" julia --project="*repo*"\"."

    function verify_uuid(uuid)
        uuid == pkg_info["uuid"]
    end

    function restore_commit!(commit)
        cur_commit = chomp(String(read(`git rev-parse HEAD`)))
        if cur_commit == commit
            println("Already on commit ", commit)
        else
            printstyled("┌-- Restoring commit ", "-"^20, "\n| ", bold=true, color=:green)
            printstyled("Current HEAD: ", bold=true, color=:magenta)
            write(stdout, read(`git log --oneline -n 1`))
            printstyled("| ", bold=true, color=:green)
            printstyled("Restoring to: ", bold=true, color=:magenta)
            write(stdout, read(Cmd(["git", "log", "--oneline", "-n", "1", commit])))
            printstyled("└", "-"^40, "\n", bold=true, color=:green)
            run(Cmd(["git", "checkout", "--quiet", commit]))
        end
    end    

    macro useRestored(expr)
        expr.args[1] == :(:) || error("Cannot parse expression.")
        pkg = expr.args[2]
        String(pkg) == pkg_info["name"] || error("Cannot restore a package other than "*pkg_info["name"])
        commit = String(expr.args[3])
        restore_commit!(commit)
        :(using $pkg)
    end

end
