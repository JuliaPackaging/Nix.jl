# __precompile__()
"""
The Nix module provides access to the [Nix](http://nixos.org/nix/) packages
manager. Its main purpose is to be used as a BinDeps provider, to install binary
dependencies of other Julia packages.

The main functions in Nix are:

- `Nix.add(package)`: install a package;
- `Nix.rm(package)`: remove (uninstall) a package;
- `Nix.update()`: update all installed packages to the latest version;
- `Nix.installed()`: list all installed packages;
- `Nix.available()`: list all available packages;
- `Nix.channels()`: get the current list of channels;
- `Nix.add_channel(channel_url)`: add a channel to the list of channels;
- `Nix.rm_channel(channel_name)`: remove a channel from the list of channels;
- `Nix.update_channel([channel_name])`: obtain the latest Nix expressions available in a channel;
- `Nix.rollback_channel([channel_name])`: revert the previous call to update channel;

"""
module Nix

    function add(pkgname::AbstractString; dryrun::Bool=false)
        cmd = ["nix-env", "--install"]
        dryrun && push!(cmd, "--dry-run")
        if isempty(pkgname)
            error("Plese specify package to remove")
        else
            push!(cmd, pkgname)
        end

        try
            readlines(Cmd(cmd))
        catch
            error("Cannot uninstall package `$pkgname`")
        end
        return nothing
    end

    function rm(pkgname::AbstractString; dryrun::Bool=false)
        cmd = ["nix-env", "--uninstall"]
        dryrun && push!(cmd, "--dry-run")
        if isempty(pkgname)
            error("Plese specify package to remove")
        else
            push!(cmd, pkgname)
        end

        try
            readlines(Cmd(cmd))
        catch
            error("Cannot uninstall package `$pkgname`")
        end
        return nothing
    end

    "List all installed packages."
    function installed(pkgname::AbstractString="")
        cmd = ["nix-env", "--query", "--installed"]
        !isempty(pkgname) && push!(cmd, pkgname)
        try
            pkgs = readlines(Cmd(cmd))
            map(chomp, pkgs)
        catch
            error("Cannot list installed packages")
        end
    end

    "The query operates on the derivations that are available in the active Nix expression."
    function available(pkgname::AbstractString="")
        cmd = ["nix-env", "--query", "--available"]
        !isempty(pkgname) && push!(cmd, pkgname)
        try
            pkgs = readlines(Cmd(cmd))
            map(chomp, pkgs)
        catch
            error("Cannot list installed packages")
        end
    end

    "Adds a channel named `chname` (optional) with URL `churl` to the list of subscribed channels."
    function add_channel(churl::AbstractString, chname::AbstractString="")
        try
            run(`nix-channel --add $churl $chname`)
        catch
            error("Cannot add new channel `$churl`")
        end
    end

    "Returns the names and URLs of all subscribed channels."
    function channels()
        chs = readlines(`nix-channel --list`)
        chsl = map(c->split(c,' '), map(chomp, chs))
        Dict([(ch::AbstractString, url::AbstractString) for (ch, url) in chsl])
    end

    "Removes the channel named `chname` from the list of subscribed channels."
    function rm_channel(chname::AbstractString)
        try
            run(`nix-channel --remove $chname`)
        catch
            error("Cannot remove channel `$chname`")
        end
    end

    "Obtain the latest Nix expressions available in the channel."
    function update_channel(chname::AbstractString="")
        try
            run(`nix-channel --update $chname`)
        catch
            error("Cannot update channel `$chname`")
        end
    end

    """Reverts the previous call to update the channel.

    Optionally, you can specify a specific channel generation number to restore.
    """
    function rollback_channel(gen::Int=0)
        sgen = gen !=0 ? "$gen" : ""
        try
            run(`nix-channel --rollback $sgen`)
        catch
            error("Cannot rollback channel")
        end
    end

    function __init__()
        profiledir = haskey(ENV, "NIX_PROFILE") ? ENV["NIX_PROFILE"] : joinpath(homedir(),".nix-profile")
        !isdir(profiledir) && error("No Nix profile found in $profiledir")
        global const PROFILE = profiledir
        pathdirs = split(ENV["PATH"],':')
        if findfirst(p->contains(p, ".nix-profile"), pathdirs) == 0
            error(""" Nix is not configured on your system.

                - Install Nix, e.g. "curl https://nixos.org/nix/install | sh"
                - Add to \$PATH env. variable a location of your Nix profile, e.g. "source ~/.nix-profile/etc/profile.d/nix.sh"
            """)
        end
    end

end