# Agent instructions

## Approval before work

Before any work, present a concrete plan and wait for the user's explicit
approval. Approval applies only to that plan; obtain renewed approval before
changing its scope. Do not treat a task request alone as plan approval.

## Branch environments

| Branch | Environment | Shell |
| --- | --- | --- |
| `main` | User's Mac | zsh |
| `quartz` | Quartz Slurm cluster | bash |
| `bigred200` | Big Red 200 Slurm cluster | bash |
| `lair` | Lair Slurm cluster | zsh |

These branches intentionally diverge. Preserve each environment's settings
and files. Do not merge `main` wholesale into cluster branches or overwrite
cluster-specific configuration without an explicitly approved plan. Share
only the intended changes through targeted edits or narrowly scoped commits.

`.bash_aliases` is used by both Bash and zsh; shared changes must work in both.
Verify cluster changes with the appropriate shell. Do not submit Slurm jobs
as a verification step without explicit approval.
