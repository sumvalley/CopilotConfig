# ===== Identity =====
git config --global user.name "Sum Valley"
git config --global user.email "sum@valley"

# ===== Editor =====
git config --global core.editor "nvim"

# ===== Line endings =====
if ($IsWindows)
{
    git config --global core.autocrlf true
}
else
{
    git config --global core.autocrlf input
}

# ===== Branch =====
git config --global init.defaultBranch main
git config --global branch.sort -committerdate

# ===== Fetch/Push =====
git config --global fetch.prune true
git config --global push.autoSetupRemote true

# ===== Diff =====
git config --global diff.algorithm histogram
git config --global diff.mnemonicPrefix true
git config --global diff.colorMoved plain

# ===== Merge =====
git config --global merge.conflictstyle zdiff3

# ===== Rebase =====
git config --global rebase.autoStash true
git config --global rerere.enabled true
