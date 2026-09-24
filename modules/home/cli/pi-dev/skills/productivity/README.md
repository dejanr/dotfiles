# Productivity skills

## User-invoked

These skills are hidden from Pi's automatic skill selection. Invoke them explicitly:

| Command                                  | Purpose                                                                                                                            |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| [`/skill:grill-me`](grill-me/SKILL.md)   | Stress-test a plan or design through the shared grilling workflow.                                                                 |
| [`/skill:handoff`](handoff/SKILL.md)     | Save a concise, redacted conversation handoff in the OS temporary directory. Optional arguments describe the next session's focus. |
| [`/skill:wait-what`](wait-what/SKILL.md) | Re-explain the last message with missing context and simpler language.                                                             |

## Model- or user-invoked

| Skill                                             | Purpose                                                                                                                                                                            |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [grilling](grilling/SKILL.md)                     | Interview in rounds of questions whose prerequisites are settled, with recommended answers. Also supplies the shared interview workflow referenced by existing engineering skills. |
| [writing-for-agents](writing-for-agents/SKILL.md) | Write and refine skills, agent instructions, and linked reference documents. Includes [skill mechanics](writing-for-agents/SKILL-MECHANICS.md).                                    |

Pi can discover these automatically, or you can invoke `/skill:grilling` and `/skill:writing-for-agents` directly.
