# Dumbcourse (Discourse plugin)

Dumbcourse serves a lightweight, old‑browser friendly forum UI under `/dumb`.
It targets dumbphones, old Android WebViews, and D‑pad navigation where the
standard Discourse UI is too heavy.

## What it is
- A Discourse plugin that exposes a minimal SPA at `/dumb` on the same domain.
- Built for old browsers: ES5, no build step, and minimal DOM/JS/CSS.
- Designed for D‑pad navigation and small screens.

## How it works
- The plugin serves static assets from `public/` (`dumbcourse.js`, `dumbcourse.css`, `index.html`).
- The SPA calls Discourse JSON endpoints on the same origin.
- Sessions rely on standard Discourse cookies; no external proxy is required.
- `/dumb` uses Discourse data for site title, categories, topics, users, etc.

## Features
- Login + signup flows that use Discourse APIs.
- Topic lists (latest/new/top/unseen/hot/my) and category lists.
- Category topic views at `/dumb/c/:slug/:id`.
- Topic reading, replying, quoting, reactions, and basic moderation actions.
- Markdown rendering + emoji support.
- Search and profile views.
- D‑pad navigation and focusable UI elements.

## Settings (Admin > Plugins > Dumbcourse)
- `dumbcourse_enabled` (on/off)
- `dumbcourse_default_theme` (dark/light)
- `dumbcourse_default_view` (latest/new/top/unseen/hot/my/categories)
- `dumbcourse_sidebar_link_enabled` (adds a sidebar link to `/dumb`)

## Install
Typical Discourse plugin install:
1. Add this repo to your `app.yml` `hooks` > `after_code` plugin list.
2. Rebuild the container.

## Testing
- Visit `https://your-forum-domain/dumb`.
- Anonymous users should land on `/dumb/login`.
- Logged‑in users should see the default view.
- Verify D‑pad navigation, search, topic load, and category navigation.

## Notes
- This is intentionally minimal and avoids modern JS features.
- All data is fetched from Discourse; no external services are required.
