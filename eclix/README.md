# Eclixtech Chatwoot fork

Runs https://support.eclixtech.com. It's upstream Chatwoot **Community Edition**
(the `enterprise/` directory is removed at build time, the same way upstream's own
`publish_foss_docker.yml` does it), so everything we build and publish is
MIT-licensed code. Keep upstream's `LICENSE` as it is.

## What we change

Only what's in `eclix/patches/`:

| patch | why |
|---|---|
| `0001-remove-powered-by-footer.patch` | hides the "Powered by Chatwoot" footer in the website/app chat widget and the CSAT survey page (`app/javascript/shared/components/Branding.vue`) |

We do **not** touch `enterprise/` or turn on paid feature flags such as
`disable_branding` in the database. Captain, SLA and custom roles stay
upstream paid features.

## Branches and tags

- `eclix` (default branch): upstream release tag + one commit with this
  directory, our workflows, upstream's workflows removed, and the patches
  applied. `git show eclix` shows the whole diff from upstream.
- `vX.Y.Z-eclixN`: what gets built. A push of one of these tags runs
  `eclix-build.yml` and publishes `ghcr.io/eclix-web/chatwoot:vX.Y.Z-eclixN`.
- `develop` / `master`: untouched upstream mirrors from the fork.

## Upgrading to a new Chatwoot release

`eclix-upstream-check.yml` runs daily. When a new upstream release has no
`-eclix1` tag yet, it opens an issue, or, if the repo secret `SYNC_TOKEN`
(a token with `repo` + `workflow` scope) exists, it runs the sync itself.

To sync by hand:

```bash
eclix/sync.sh v4.19.0      # rebuilds `eclix` on v4.19.0, pushes v4.19.0-eclix1 -> CI builds the image
```

Read the upstream release notes first, then deploy on the server: set the new tag in
`/opt/chatwoot/compose.yaml` (`image: ghcr.io/eclix-web/chatwoot:...`) and run
`docker compose up -d`. Migrations run on rails start (`db:chatwoot_prepare`).

## Changing a patch

Edit the file and regenerate the patch from the upstream tag
(`git diff vX.Y.Z -- <file> > eclix/patches/000N-....patch`), commit, then
`eclix/sync.sh vX.Y.Z 2` to publish `vX.Y.Z-eclix2`.
