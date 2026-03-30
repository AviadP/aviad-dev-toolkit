# Example Test Plan: Staggered Backup Scheduling (PROJ-4521)

This is a sample test plan for a backup scheduler feature that staggers execution
times to prevent thundering herd. Use it as a reference for structure, detail
level, and categorization.

**Feature summary**: A multi-tenant database platform runs nightly backups for
all tenants. Previously, all backups started at 00:00 simultaneously, causing
I/O spikes. The new feature applies a deterministic, tenant-ID-based offset
(hash-based jitter) to spread backups across a configurable window (default 2h).
Configurable via `backup-stagger-window` in the platform config. Setting to `0`
disables staggering.

## Scope

Verify that the backup scheduler applies deterministic, ID-based stagger offsets
to tenant backup execution times to prevent thundering herd on shared storage.

---

### Happy Path

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 1 | **Default stagger window value** | 1. Read `backup-stagger-window` from platform config | Value is `"2"` (2 hours) or absent (default applies) |
| 2 | **Backup jobs created with stagger enabled** | 1. Create 3 tenant databases with `backup-schedule=*/3 * * * *` 2. Wait for backup scheduler to pick them up | Scheduled backup job auto-created for each tenant |
| 3 | **Configured schedule unchanged by stagger** | 1. Read `schedule` field from each backup job created in #2 | All show `*/3 * * * *` — stagger is internal, not visible in config |
| 4 | **Backups run at staggered times** | 1. Wait for backup tasks to execute 2. Compare `started_at` timestamps across tenants | Timestamps are NOT all within 5s of each other — spread confirms stagger |
| 5 | **Tenant IDs produce unique offsets** | 1. Collect tenant IDs from each backup job | All IDs distinct (precondition for unique hash-based offsets) |

### Configuration

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 6 | **Disable stagger (window=0)** | 1. Set `backup-stagger-window=0` in config 2. Restart scheduler service 3. Read back value | Value reads `"0"`. Existing backup jobs unaffected |
| 7 | **Custom stagger window** | 1. Set `backup-stagger-window=1` (1 hour) 2. Create tenants with `@daily` schedule 3. Wait for backups | Backups staggered within 1-hour window (not 2-hour default) |
| 8 | **Config update requires service restart** | 1. Set `backup-stagger-window=0` WITHOUT restarting scheduler 2. Observe behavior | Stagger continues using old value until service is restarted |
| 9 | **Invalid config value** | 1. Set `backup-stagger-window=abc` (non-numeric) | Scheduler logs error, falls back to default behavior |

### Schedule Variations

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 10 | **Daily schedule** | 1. Create tenants with `@daily` schedule 2. Check backup status after first run | Stagger window = min(24h, 2h) = 2h. Backups spread across 2-hour window |
| 11 | **Weekly schedule** | 1. Create tenants with `@weekly` schedule 2. Check backup status | Stagger window = min(7d, 2h) = 2h. Same 2-hour spread |
| 12 | **Hourly schedule** | 1. Create tenants with `@hourly` schedule 2. Wait for backups | Stagger window = min(1h, 2h) = 1h. Backups spread across 1-hour window |
| 13 | **Short interval (< stagger window)** | 1. Create tenants with `*/5 * * * *` (5-min) schedule 2. Wait for backups | Stagger window shrinks to 5 minutes (interval < 2h cap) |

### Determinism & Consistency

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 14 | **Same tenant ID produces same offset** | 1. Create tenant, wait for backup 2. Record backup start time 3. Wait for next backup cycle | Second backup offset matches first — deterministic per tenant ID |
| 15 | **Offset survives service restart** | 1. Create tenants, wait for backups, record timestamps 2. Restart scheduler 3. Wait for next round of backups | Same offsets applied — tenant IDs haven't changed |

### Missed Runs

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 16 | **Missed backup bypasses stagger** | 1. Pause a tenant's backup schedule 2. Wait past scheduled time 3. Resume backup schedule | Backup runs immediately (no stagger offset) to catch up on missed window |

### Scale

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 17 | **Many tenants with same schedule** | 1. Create 20+ tenants with `*/5 * * * *` schedule 2. Wait for all backup jobs to execute | Backups spread across stagger window. No I/O spike from simultaneous execution |

### Cross-Feature Interaction

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 18 | **Incremental backups also staggered** | 1. Enable incremental backup mode for tenants 2. Wait for incremental backup jobs | Incremental backups staggered with same logic as full backups |
| 19 | **Stagger with schedule override** | 1. Set platform default to `@daily` 2. Override one tenant to `@hourly` 3. Verify stagger applies to each tenant's effective schedule | Each tenant's stagger window matches its own schedule interval |

### Negative / Edge Cases

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 20 | **Single tenant (no spread to measure)** | 1. Create 1 tenant with short schedule 2. Wait for backup job | Backup created and runs at offset time. No error with single tenant |
| 21 | **Delete tenant while backup scheduled** | 1. Create tenant, wait for backup job 2. Delete tenant | Backup job is cleaned up. No orphaned backup tasks |

---

### Priority Matrix

| Priority | Test Cases | Rationale |
|----------|-----------|-----------|
| **P0 — Must have** | #1-6 (happy path + disable) | Core feature validation |
| **P1 — Should have** | #7, #13, #14, #17 | Custom window, interval capping, determinism, scale |
| **P2 — Nice to have** | #10-12, #15, #16, #18, #19 | Schedule variations, service resilience, cross-feature |
| **P3 — Low priority** | #8, #9, #20, #21 | Edge cases, negative tests |

---

## Key Patterns in This Example

1. **Happy path first** — the simplest proof the feature works
2. **Configuration next** — default, custom, disable, invalid
3. **Variations** — different schedules, intervals, scales
4. **Cross-feature** — interaction with other system features
5. **Negative/edge last** — what can go wrong
6. **Steps are atomic** — one action per numbered step
7. **Expected results are specific** — "Value reads '2'" not "it works"
8. **Implemented tests marked** — *(implemented)* tag for done items
9. **Priority matrix** — P0-P3 with rationale
