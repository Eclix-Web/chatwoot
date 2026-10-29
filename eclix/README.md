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
| `0002-website-inbox-smtp.patch` | per-inbox outgoing SMTP for **website** inboxes (upstream only has it for Email inboxes). Inbox → Settings → Configuration → "Send emails through this inbox's own SMTP" toggle (`WidgetSmtpSettings.vue`, extends the Email inbox `SmtpSettings.vue`): when it's on, that inbox's emails to visitors (offline replies with `continuity_via_email`, transcripts) go through its own SMTP server and are sent From/Reply-To its "From email". With it off, the global `SMTP_*` from `.env` is used as before. Also fixes `ConversationReplyMailer#channel_email_domain` for website inboxes: upstream raises "Channel email domain not present." (so the email is never sent) when no inbound email domain is configured, because a website channel has no email; it now takes the domain of the address the mail is sent from. Adds 11 `smtp_*` columns to `channel_web_widgets` (migration `20260830235900_eclix_add_smtp_to_channel_web_widgets.rb`; the password is encrypted like Email inboxes'). |
| `0003-archived-conversation-status.patch` | adds an **Archived** conversation status (`archived: 4` in the `status` enum, no migration). Set from the conversation header dropdown ("Archive") or the list's right-click menu ("Archive conversation"); listed under the status filter's "Archived" option (and under "All"); usable in advanced filters and automations. Clears `waiting_since` like Resolved. A new incoming message reopens it exactly like a resolved conversation (`Message#reopen_conversation`). |
| `0004-website-email-reply-threading.patch` | threads email replies back into **website** conversations without upstream's inbound-email (`reply+uuid@`) setup. A website inbox's emails (offline replies, transcripts) are sent from a shared mailbox that an Email inbox reads over IMAP; upstream files the customer's reply there as a new conversation and the link to the website/app is lost. `Imap::ImapMailbox#find_website_conversation` reads the conversation uuid from the reply's `In-Reply-To`/`References` (our own `<conversation/<uuid>/messages/…>` and `<account/<id>/conversation/<uuid>@…>` ids) and, if it belongs to a website inbox **and** the sender is that conversation's contact, adds the reply there instead. `Imap::BaseFetchEmailService#email_already_present?` also checks website inboxes so the next poll doesn't import it again. Replies without our headers (or from another address) still become a conversation in the Email inbox. |

We do **not** touch `enterprise/` or turn on paid feature flags such as
`disable_branding` in the database. Captain, SLA and custom roles stay
upstream paid features.

## Branches and tags

- `eclix` (default branch): upstream release tag + one commit with this
  directory, our workflows, upstream's workflows removed, and the patches
  applied. `git show eclix` shows the whole diff from upstream.
- `vX.Y.Z-eclixN`: releases. A push of one of these tags runs
  `eclix-build.yml` and publishes `ghcr.io/eclix-web/chatwoot:vX.Y.Z-eclixN`.
  This is what the server runs.
- Every push or merged PR to `eclix` (except Markdown-only changes) also runs
  `eclix-build.yml` and publishes `:eclix-<short sha>` and a moving
  `:eclix-latest`, for testing before cutting a release tag. `sync.sh` pushes
  the branch and a tag together, so a sync builds the same commit twice; the
  second build mostly hits the layer cache.
- `develop` / `master`: untouched upstream mirrors from the fork.

## Upgrading to a new Chatwoot release

`eclix-upstream-check.yml` runs daily. When a new upstream release has no
`-eclix1` tag yet, it opens an issue, or, if the repo secret `SYNC_TOKEN`
(a token with `repo` + `workflow` scope) exists, it runs the sync itself.

To sync by hand:

```bash
eclix/sync.sh v4.19.0      # rebuilds `eclix` on v4.19.0, pushes v4.19.0-eclix1 -> CI builds the image
```

Read the upstream release notes first, then deploy (below).

## Deploying

The server runs the Komodo stack `chatwoot` (server `support-chatwoot`, files on
host at `/opt/chatwoot`). The stack logs in to GHCR with the Komodo registry
account `ghcr.io` / `cto836` and pulls before every deploy. The image is private.

1. Wait for the `vX.Y.Z-eclixN` build in Actions to finish.
2. Komodo → Stacks → `chatwoot` → the `compose.yaml` file: change
   `image: ghcr.io/eclix-web/chatwoot:...` to the new tag (it appears once, in `x-base`). Save.
3. Deploy. Komodo pulls the image and recreates rails + sidekiq. Migrations run on
   rails start (`db:chatwoot_prepare`).

The stack has no Komodo environment on purpose. Secrets live only in the server's
`.env`, and Komodo never writes it. Rollback: set the previous tag and deploy.
Before a release that adds a migration, take a `pg_dump -Fc` of the database.

A patch that adds a migration keeps its version **below** the `schema.rb`
version and adds its columns to `schema.rb` without bumping the version. A fresh
schema load then counts it as run, existing databases run it as pending, and
upstream's next `schema.rb` version bump doesn't conflict with the patch.

## Changing a patch

Edit the file and regenerate the patch from the upstream tag
(`git diff vX.Y.Z -- <file> > eclix/patches/000N-....patch`), commit, then
`eclix/sync.sh vX.Y.Z 2` to publish `vX.Y.Z-eclix2`.
