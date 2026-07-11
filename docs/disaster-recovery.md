# Disaster recovery

Until Phase 8 is completed, Git restores declarative configuration but not
stateful services or private keys. The future recovery order is: recreate VM,
install Docker, restore repository, restore encrypted state and secrets, verify
permissions, deploy, then test DNS and services before distributing Lantern DNS.

