# JTech Forums Crash Postmortem

## What happened

The SSE push endpoint (`/dumb/push/sse/:topic`) used `ActionController::Live` + `Redis SUBSCRIBE`, which **held one Pitchfork worker per connection** for up to 120 seconds.

With only 8 workers on production, a handful of SSE clients consumed all of them. The site became unresponsive, load spiked to 55+, SSH stopped working, and forced restarts corrupted PostgreSQL WAL — causing a cascading failure loop.

## Root cause

```
SSE clients connect → workers held → no workers left → site down →
forced restart → PG WAL corrupted → container crash loop → repeat
```

The irony: the SPA client had already switched to 30s polling. The SSE endpoint was dead code that only served as a worker-exhaustion surface.

## Fix (2026-02-26)

- Gutted the SSE controller — returns `503` immediately, holds zero workers
- Defaulted `dumbcourse_push_enabled` to `false`
- Fixed Dislike plugin directory name mismatch (`dislike` vs `discourse-no-likes`)
- Ran `pg_resetwal` + cleaned corrupted WAL segments
- Full container rebuild with both plugins baked in correctly

## Status

Stable. Load ~1.0, all 8 workers healthy, SSE safely neutered.
