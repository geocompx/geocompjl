# This file was adapted from Documenter.jl's deployconfig.jl function for Github Actions.

function authenticated_repo_url()
    return "https://$(ENV["GITHUB_ACTOR"]):$(ENV["GITHUB_TOKEN"])@github.com/$(ENV["GITHUB_REPOSITORY"]).git"
end

marker(x) = x ? "✔" : "✘"

git() = `git`

github_repository = get(ENV, "GITHUB_REPOSITORY", "") # "JuliaDocs/Documenter.jl"
github_event_name = get(ENV, "GITHUB_EVENT_NAME", "") # "push", "pull_request" or "cron" (?)
github_ref        = get(ENV, "GITHUB_REF",        "") # "refs/heads/$(branchname)" for branch, "refs/tags/$(tagname)" for tags

cfg = (; github_repository, github_event_name, github_ref)

io = stdout

if cfg.github_event_name == "pull_request"
    build_type = :preview
elseif occursin(r"^refs\/tags\/(.*)$", cfg.github_ref)
    build_type = :release
else
    build_type = :devbranch
end

println(io, "Deployment criteria for deploying $(build_type) build from GitHub Actions:")

all_ok = true
is_preview = false

if build_type in (:release, :devbranch)
    event_ok = in(cfg.github_event_name, ["push", "workflow_dispatch", "schedule"])
    all_ok &= event_ok
    println(io, "- $(marker(event_ok)) ENV[\"GITHUB_EVENT_NAME\"]=\"$(cfg.github_event_name)\" is \"push\", \"workflow_dispatch\" or \"schedule\"")
    m = match(r"^refs\/heads\/(.*)$", cfg.github_ref)
    branch_ok = m === nothing ? false : String(m.captures[1]) == devbranch
    all_ok &= branch_ok
    println(io, "- $(marker(branch_ok)) ENV[\"GITHUB_REF\"] matches devbranch=\"$(devbranch)\"")
    is_preview = false
    subfolder = "."
elseif build_type == :preview
    m = match(r"refs\/pull\/(\d+)\/merge", cfg.github_ref)
    pr_number = tryparse(Int, m === nothing ? "" : m.captures[1])
    pr_ok = pr_number !== nothing
    all_ok &= pr_ok
    println(io, "- $(marker(pr_ok)) ENV[\"GITHUB_REF\"] corresponds to a PR number")
    btype_ok = true
    all_ok &= btype_ok
    is_preview = true
    ## deploydocs to previews/PR
    subfolder = "previews/PR$(something(pr_number, 0))"
end

quarto_rendered = success(pipeline(`quarto render`; stdout=stdout, stderr=stderr))

println("$(marker(all_ok)) All environment variables are set correctly.")
println("$(marker(quarto_rendered)) Quarto rendered successfully.")

if !quarto_rendered
    println("$(marker(false)) Quarto rendering failed.")
    exit(1)
end
if !all_ok
    println("$(marker(false)) Deployment failed.")
    exit(0)
end

# Here we know that the site builds to `docs/`, 
# but you could customize this directory in the future.
builddir = "docs"
upstream = "https://github.com/geocompx/geocompjl.git"
branch = "gh-pages"


sha = cd(dirname(@__DIR__)) do
    # Find the commit sha.
    # We'll make sure we run the git commands in the source directory (root), in case
    # the working directory has been changed (e.g. if the makedocs' build argument is
    # outside root).
    try
        readchomp(`$(git()) rev-parse --short HEAD`)
    catch
        # git rev-parse will throw an error and return code 128 if it is not being
        # run in a git repository, which will make run/readchomp throw an exception.
        # We'll assume that if readchomp fails it is due to this and set the sha
        # variable accordingly.
        "(not-git-repo)"
    end
end


"""
    gitrm_copy(src, dst)

Uses `git rm -r` to remove `dst` and then copies `src` to `dst`. Assumes that the working
directory is within the git repository of `dst` is when the function is called.

This is to get around [#507](https://github.com/JuliaDocs/Documenter.jl/issues/507) on
filesystems that are case-insensitive (e.g. on OS X, Windows). Without doing a `git rm`
first, `git add -A` will not detect case changes in filenames.
"""
function gitrm_copy(src, dst)
    # Remove individual entries since with versions=nothing the root
    # would be removed and we want to preserve previews
    if isdir(dst)
        for x in filter!(!in((".git", "previews", "CNAME")), readdir(dst))
            # --ignore-unmatch so that we wouldn't get errors if dst does not exist
            run(`$(git()) rm -rf --ignore-unmatch $(joinpath(dst, x))`)
        end
    end
    # git rm also remove parent directories
    # if they are empty so need to mkpath after
    mkpath(dst)
    # Copy individual entries rather then the full folder since with
    # versions=nothing it would replace the root including e.g. the .git folder
    for x in readdir(src)
        cp(joinpath(src, x), joinpath(dst, x); force=true)
    end
end
# Generate a closure with common commands for ssh and https
function git_commands(sshconfig=nothing)
    # Setup git.
    run(`$(git()) init`)
    run(`$(git()) config user.name "Julia Quarto deployment script"`)
    run(`$(git()) config user.email "documenter@juliadocs.github.io"`)

    # Fetch from remote and checkout the branch.
    run(`$(git()) remote add upstream $upstream`)
    try
        run(`$(git()) fetch upstream`)
    catch e
        @error """
        Git failed to fetch $upstream
        This can be caused by a DOCUMENTER_KEY variable that is not correctly set up.
        Make sure that the environment variable is properly set up as a Base64-encoded string
        of the SSH private key. You may need to re-generate the keys with DocumenterTools.
        """
        rethrow(e)
    end

    try
        run(`$(git()) checkout -b $branch upstream/$branch`)
    catch e
        @info """
        Checking out $branch failed, creating a new orphaned branch.
        This usually happens when deploying to a repository for the first time and
        the $branch branch does not exist yet. The fatal error above is expected output
        from Git in this situation.
        """
        @debug "checking out $branch failed with error: $e"
        run(`$(git()) checkout --orphan $branch`)
        run(`$(git()) commit --allow-empty -m "Initial empty commit for docs"`)
    end

    # Copy docs to `subfolder` directory.
    deploy_dir = subfolder === nothing ? "." : joinpath(".", subfolder)
    gitrm_copy(target_dir, deploy_dir)

    # Add, commit, and push the docs to the remote.
    run(`$(git()) add -A -- ':!.documenter-identity-file.tmp' ':!**/.documenter-identity-file.tmp'`)
    if !success(`$(git()) diff --cached --exit-code`)
        # if !isnothing(archive)
        #     run(`$(git()) commit -m "build based on $sha"`)
        #     @info "Skipping push and writing repository to an archive" archive
        #     run(`$(git()) archive -o $(archive) HEAD`)
        # elseif forcepush
        #     run(`$(git()) commit --amend --date=now -m "build based on $sha"`)
        #     run(`$(git()) push -fq upstream HEAD:$branch`)
        # else
            run(`$(git()) commit -m "build based on $sha"`)
            run(`$(git()) push -q upstream HEAD:$branch`)
        # end
    else
        @debug "new docs identical to the old -- not committing nor pushing."
    end
end


# authentication_method(deploy_config) === HTTPS
# The upstream URL to which we push new content authenticated with token
upstream = authenticated_repo_url()
try
    cd(git_commands, mktempdir())
    # post_status(deploy_config; repo=repo, type="success", subfolder=subfolder)
catch e
    @error "Failed to push:" exception=(e, catch_backtrace())
    # post_status(deploy_config; repo=repo, type="error")
    rethrow(e)
end

