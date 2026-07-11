# Uptime Kuma

Runtime state is stored in the `uptime_kuma_data` Docker volume and is never
committed. Initial monitor creation remains a Phase 6 task because Uptime Kuma's
database is stateful. Export monitor configuration before upgrades and include
the volume in encrypted backups.

