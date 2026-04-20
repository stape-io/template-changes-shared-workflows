# template-changes-shared-workflows

This repository contains shared GitHub Actions workflows that can be used across multiple repositories. The workflows are designed to be reusable and can be easily integrated into any repository by referencing them in the `.github/workflows` directory.

## Usage

Add the worklows from [./gtm-templates-specific-workflows](./gtm-templates-specific-workflows) to the `.github/workflows` directory of your template repository.

Any change must be made in the [./github](./github) directory, which will automatically be reflected in all the repositories that reference these workflows. This allows for centralized management of the workflows, ensuring consistency across all repositories that use them.

## Workflows Description

⏺️ Reusable workflows — `.github/workflows/`

- `check-changes.yml` — Detects whether the push touched template.tpl or README.md; outputs those flags plus commit message and URL for downstream jobs.
- `discourse-bootstrap.yml` — On first run, creates a Discourse topic from the README and stores the resulting `topic_id` / `post_id` as repo variables; on later runs just returns the existing IDs.
- `discourse-notify.yml` — Diffs template.tpl, asks Copilot (gpt-4o) for a changelog summary, checks GTM Gallery status, and posts a new reply to the bootstrapped Discourse topic.
- `discourse-readme-sync.yml` — Parses the README body, checks Gallery status, and PUTs an updated version (with GitHub + Gallery badges appended) onto the bootstrapped Discourse post.
- `gallery-status.yml` — Compares current vs. desired GTM Gallery badge in README; if they differ, rewrites the badge block and commits the change back to the repo.

⏺️ Per-template caller workflows — `gtm-templates-specific-workflows/.github/workflows/`

- `discourse-notify-and-readme-sync.yml` — Runs on push to main/master: bootstraps the Discourse topic, detects changes, then conditionally calls the **shared** `discourse-notify` (if template.tpl changed) and the shared discourse-readme-sync (if README.md changed).
- `gallery-status.yml` — Runs daily at 03:00 UTC and on README pushes to main/master, calling the **shared** `gallery-status` workflow to keep the README badge in sync.