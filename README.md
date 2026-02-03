
# Dumbcourse — a lightweight `/dumb` UI for Discourse

**Dumbcourse** is a Discourse plugin that adds a fast, old-browser friendly forum UI at **`/dumb`**.

It’s built for:
- dumbphones / keypad devices (D-pad navigation)
- older Android WebViews
- “I just need to read/post” situations where the full Discourse UI is too heavy

Demo: https://forums.jtechforums.org/dumb

---

## What you get

- A minimal single-page UI served from the same Discourse instance at **`/dumb`**
- **ES5 / no build step** (intentionally boring JavaScript)
- Same-origin API calls to Discourse JSON endpoints
- Uses your normal Discourse session cookies (no proxy, no separate auth)

---

## How it works

- The plugin serves static assets from `public/` (e.g. `index.html`, `dumbcourse.js`, `dumbcourse.css`)
- The SPA calls Discourse JSON endpoints on the same origin
- Sessions rely on standard Discourse cookies
- `/dumb` uses Discourse data for site title, categories, topics, users, etc.

---

## Features

- Login + signup (via Discourse APIs)
- Topic lists: `latest`, `new`, `top`, `unseen`, `hot`, `my`, plus categories
- Category view: `/dumb/c/:slug/:id`
- Read topics, reply, quote, reactions, and basic moderation actions
- Markdown rendering + emoji
- Search + basic profile views
- D-pad friendly focus/navigation

---

## Admin settings

**Admin → Plugins → Dumbcourse**
- `dumbcourse_enabled`
- `dumbcourse_default_theme` (`dark` / `light`)
- `dumbcourse_default_view` (`latest` / `new` / `top` / `unseen` / `hot` / `my` / `categories`)
- `dumbcourse_sidebar_link_enabled` (adds a sidebar link to `/dumb`)

---

## Install (self-hosted Discourse)

Add the plugin to your `containers/app.yml` under `hooks -> after_code`, then rebuild.

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - sudo -E -u discourse git clone https://github.com/TripleU613/dumbcourse.git
````

Then:

```bash
./launcher rebuild app
```

Reference: Discourse’s plugin install guide:
[https://meta.discourse.org/t/install-plugins-on-a-self-hosted-site/19157](https://meta.discourse.org/t/install-plugins-on-a-self-hosted-site/19157)

---

## Quick test checklist

* Visit `https://your-forum.example/dumb`
* Anonymous users should land on `/dumb/login`
* Logged-in users should see the default view
* Confirm: category navigation, topic load, reply flow, and focus order

---

## Contributing

PRs are welcome — but please keep **three constraints** in mind at all times:

1. **D-pad compatibility comes first**
   A lot of users will navigate with directional keys. If your change breaks “move focus with arrows + press Enter,” it’s a no-go.
   Quick test: use your PC keyboard **arrow keys** like a D-pad and make sure focus movement still makes sense.

2. **Small screens must stay usable**
   Flipphones/dumbphones have tiny displays. Keep layouts simple, readable, and not “scroll forever to find the one button.”
   Avoid dense UI, giant headers, and anything that assumes modern responsive breakpoints.

3. **Old WebViews / old browsers are a hard requirement**
   Assume older Android WebViews and lightweight browsers. Keep it **ES5-safe**, avoid fancy modern APIs, and don’t introduce a build step just to ship one small UI change.

---

## Design goals

This UI is intentionally “low-tech”:

* minimal JS/CSS/DOM work
* avoids modern browser features on purpose
* everything stays on your Discourse host (no external services)

---

## License

GPL-3.0

```

If you post on Meta, the one extra thing that tends to get traction: add **2 screenshots** (topic list + topic view) and one sentence like “This gives old WebViews a usable doorway into Discourse.” That’s the whole pitch, clean and undeniable.
::contentReference[oaicite:2]{index=2}
```

[1]: https://meta.discourse.org/t/install-plugins-on-a-self-hosted-site/19157?tl=en&utm_source=chatgpt.com "Install plugins on a self-hosted site"
[2]: https://developer.android.com/develop/ui/views/touch-and-input/keyboard-input/navigation?utm_source=chatgpt.com "Support keyboard navigation | Views | Android Developers"
