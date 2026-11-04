import Host

# platform/Bump.roc — host bump buffer policy (Roc heap traffic on pure-Goose host)
Bump := {}.
{
    ## Soft max bytes the host may grow the Roc bump buffer to.
    ## Does not reserve address space up front; growth is still pointer-bump.
    ## Err if limit < current high-water or limit == 0 (policy choice).
    set_limit_bytes! : U64 => Try({}, [BumpErr(Str)])
    set_limit_bytes! = |n| Host.bump_set_limit_bytes!(n)

    ## Bytes already committed in the bump buffer (high-water).
    used_bytes! : {} => Try(U64, [BumpErr(Str)])
    used_bytes! = |_| Host.bump_used_bytes!({})

    ## Current soft limit.
    limit_bytes! : {} => Try(U64, [BumpErr(Str)])
    limit_bytes! = |_| Host.bump_limit_bytes!({})
}
