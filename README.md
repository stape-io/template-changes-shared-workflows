# template-changes-shared-workflows

This repository contains shared GitHub Actions workflows that can be used across multiple repositories. The workflows are designed to be reusable and can be easily integrated into any repository by referencing them in the `.github/workflows` directory.

## Usage

Add the worklows from [./gtm-templates-specific-workflows](./gtm-templates-specific-workflows) to the `.github/workflows` directory of your template repository.

Any change must be made in the [./github](./github) directory, which will automatically be reflected in all the repositories that reference these workflows. This allows for centralized management of the workflows, ensuring consistency across all repositories that use them.

## Github Variables and Secrets Required

These workflows require the following GitHub variables and secrets to be set at the organization level. They are already set by Ops Team.

| Type         	| Name                   	|
|--------------	|------------------------	|
| Org secret   	| COMMUNITY_API_KEY      	|
| Org secret   	| COMMUNITY_API_USERNAME 	|
| Org variable 	| COMMUNITY_CATEGORY_ID  	|

## Workflows Description

⏺️ Reusable workflows — `.github/workflows/`

- `check-changes.yml` — Detects whether the push touched template.tpl or README.md; outputs those flags plus commit message and URL for downstream jobs.
- `discourse-bootstrap.yml` — On first run, creates a Discourse topic from the README and stores the resulting `COMMUNITY_TOPIC_ID` / `COMMUNITY_POST_ID` in `.github/community-config.json`; on later runs reads the IDs from that file and returns them.
- `discourse-notify.yml` — Diffs template.tpl, asks Copilot (gpt-4o) for a changelog summary, checks GTM Gallery status, and posts a new reply to the bootstrapped Discourse topic.
- `discourse-readme-sync.yml` — Parses the README body, checks Gallery status, and PUTs an updated version (with GitHub + Gallery badges appended) onto the bootstrapped Discourse post.
- `gallery-status.yml` — Compares current vs. desired GTM Gallery badge in README; if they differ, rewrites the badge block and commits the change back to the repo.

⏺️ Per-template caller workflows — `gtm-templates-specific-workflows/.github/workflows/`

- `discourse-notify-and-readme-sync.yml` — Runs on push to main/master: bootstraps the Discourse topic, detects changes, then conditionally calls the **shared** `discourse-notify` (if template.tpl changed) and the shared discourse-readme-sync (if README.md changed).
- `gallery-status.yml` — Runs twice a week at 04:00 UTC (Monday and Thursday) and on README pushes to main/master, calling the **shared** `gallery-status` workflow to keep the README badge in sync.

## Utilities

⏺️ Utility scripts and data — `utils/`

- `fetch-all-template-repos.sh` — Lists repositories in `stape-io` that contain `template.tpl` and writes the result to `all-template-repos.json`.
- `all-template-repos.json` — Snapshot list of repositories with `template.tpl`.
- `repos-and-community-ids.json` — Mapping of repositories to Discourse topic/post IDs.
- `set-repo-community-ids.sh` — Writes IDs from `repos-and-community-ids.json` to each repository's `.github/community-config.json` and removes old `COMMUNITY_TOPIC_ID` / `COMMUNITY_POST_ID` repo variables.