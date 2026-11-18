---
name: release-buffbot
description: Release a new BuffBot version end to end - checks, in-game test checklist, release branch, changelog, TOC bump, fast-forward main, v* tag, push, watch the release workflow, clean up branches, then branch off for the next thing. Use when the user says "release", "cut a release", "ship it", or "/release-buffbot".
---

# Release BuffBot

Walk the release in order. Stop and ask at every **Ask** step; never push,
tag-push or delete branches without the user saying so in this run.

Background:
- `main` is the Forever port. Releases come from a `v*` tag: `.github/workflows/release.yml`
  runs the tests, then the BigWigs packager builds `BuffBot-vX.Y.Z-forever.zip`
  and uploads it to CurseForge and a GitHub release.
- The packager uses `CHANGELOG.md` as the release notes (`.pkgmeta` `manual-changelog`),
  so the top section is what players see.
- History is linear: main is fast-forwarded, tags are lightweight (like `v2.6.10`).
- Commits use Conventional Commits and end with the attribution line from the
  session's system reminder.

## 1. Check the work

```sh
export PATH="$HOME/.luarocks/bin:$PATH"
luacheck . -q
busted
```

Both must be clean. Show `git status --short` and `git log --oneline main..HEAD`
so the user sees what goes out. If there's nothing new since the last tag
(`git describe --tags --abbrev=0`), say so and stop.

## 2. In-game test

Run `./deploy.sh` (copies to `BuffBot_Dev`; `/reload`, or restart the client for new files or TOC changes).

From `git diff <last tag>` build a short checklist of what the tests can't prove,
specific to this release: new UI and icons, saved settings surviving `/reload`,
Settings window Defaults, migrations of old saved values, buffing with an
untouched profile, combat taint (open any new settings pages, then fight and
use the button). Say plainly which logic changed and how confident the tests
make you.

**Ask** which items they tested. Note what's left for after release
(e.g. a class they don't have); don't block on it if they accept that.

## 3. Version

Last version: `grep '^## Version' BuffBot.toc`. Suggest the next one from the
changes since the last tag: any `feat:` means a minor bump (2.6.10 to 2.7.0), only fixes means a patch.
**Ask** if it's not obvious.

## 4. Release branch and commit

```sh
git switch -c release/X.Y.Z
```

Commit any uncommitted work there, split into sensible Conventional Commits.

## 5. Changelog

The top of `CHANGELOG.md` should be `## X.Y.Z` (rename `## Unreleased`).
Check the bullets against what shipped; point out anything stale (renamed
pages, behaviour that changed during the work). The user often rewrites
the section themselves: **Ask** whether to edit it or wait for their edit,
and commit their text as written.

## 6. Bump and commit

```sh
sed -i 's/^## Version: .*/## Version: X.Y.Z/' BuffBot.toc
git add BuffBot.toc CHANGELOG.md
git commit -m "chore: release X.Y.Z" -m "<attribution>"
```

## 7. Merge and tag

```sh
git switch main
git merge --ff-only release/X.Y.Z
git tag vX.Y.Z
```

If the fast-forward fails, stop and ask; don't make a merge commit or rebase on your own.

## 8. Push

**Ask** before pushing: the tag publishes to CurseForge. Then:

```sh
git push origin main vX.Y.Z
```

## 9. Watch the release

```sh
gh run list --limit 3
gh run watch <release run id> --exit-status
gh release view vX.Y.Z
```

Report: the release run's result, the tests run on main, and the GitHub
release with its `BuffBot-vX.Y.Z-forever.zip` asset. On failure, show the
log (`gh run view <id> --log-failed`). CurseForge may lag a few minutes.

## 10. Clean up

**Ask**, then delete the merged local branches (the feature branch and
`release/*`) with `git branch -d`, never `-D`. They are usually local only;
check `git branch -a` before touching remotes.

## 11. Start the next thing

**Ask** what's next, to name the branch (`feat/<short-name>`, or `fix/...`
for a bug). If they don't know yet, suggest `feat/next`, which can be renamed
later with `git branch -m`. Then branch off the released main and check it out:

```sh
git switch main
git switch -c feat/<short-name>
git status -sb
```

Confirm the branch is on the release commit (`git log --oneline -1` shows `vX.Y.Z`).
