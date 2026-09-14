# Evaluating and optimizing coding-agent developer experience

Research date: 2026-09-14.

## Recommendation

**Use Harbor for executable developer-workflow evals, then GEPA `optimize_anything` to optimize `AGENTS.md` and skills against those evals.** Start with manual candidate comparisons before adding automated search.

Harbor already has a Pi adapter, including skill injection, model selection, thinking-level configuration, JSON/session capture, and usage accounting. This is present in the `v0.23.0` source, not just a proposed integration. GEPA provides the optimization engine; a project-specific evaluator must connect candidate files to Harbor trials and return scores plus useful failure evidence. Do not assume this exact Pi + multi-file optimization workflow is turnkey. [H1][H2][G1]

For a lighter, TypeScript-oriented starting point, **Promptfoo** is a good alternative: it documents coding-agent evaluation and side-by-side skill comparisons. Pi execution would need a custom provider; workspace isolation and grading of modified repositories remain integration responsibilities. [P1][P2][P3]

This recommendation interprets “developer experience” as actual workflows: fixing bugs, reviewing changes, following project conventions, making safe configuration edits, and helping developers without unnecessary intervention. “Optimizing models” initially means selecting models and reasoning budgets—not changing model weights.

## The important distinction

Evaluate the deployed combination:

> model + reasoning settings + agent runtime + tools/extensions + instructions + skill bundle + environment

A well-written-looking instruction file is not evidence of better task completion. Nor is a successful final message evidence that the repository is correct. Agent evals should inspect outcomes, traces, and operational costs. Anthropic explicitly distinguishes the transcript from the resulting environment state. [A1]

Also include a minimal-instructions/no-optional-skills control. Research on `AGENTS.md` found no general task-success improvement and increased inference cost in its studied settings. SkillsBench finds benefits from curated skills, but emphasizes matched comparisons and focused bundles. These results support measurement, not a universal conclusion that instructions always help or always hurt. [R1][R2]

## Project shortlist

| Project | What is verified | Fit and limitation |
| --- | --- | --- |
| **[Harbor](https://github.com/harbor-framework/harbor)** · [Docs](https://www.harborframework.com/docs) | Containerized tasks, arbitrary executable verifiers, multiple agent runtimes, local/git skills, recorded skill provenance; built-in Pi adapter. [H1–H4] | Best foundation for real repository workflows. You still author tasks and candidate-configuration plumbing. |
| **[GEPA](https://github.com/gepa-ai/gepa)** · [gskill guide](https://github.com/gepa-ai/gepa/blob/main/docs/docs/guides/gskill.md) · [Docs](https://gepa-ai.github.io/gepa/) | Reflective text optimization; evaluator returns scores and diagnostics; gskill combines SWE-smith tasks with repository-skill optimization. [G1–G3] | Best optimizer/reference pipeline for this question. gskill's bug-fixing distribution is narrower than general developer experience. |
| **[Promptfoo](https://github.com/promptfoo/promptfoo)** · [Docs](https://www.promptfoo.dev/docs/intro/) | Coding-agent providers, skill-version comparisons, trigger/output/cost/latency checks, custom TypeScript providers. [P1–P3] | Best lighter YAML/TS-oriented option, particularly for review and response workflows. Not automatically a hermetic repo-task runner. |
| **[Microsoft SkillOpt](https://github.com/microsoft/SkillOpt)** · [Docs](https://github.com/microsoft/SkillOpt/blob/main/docs/index.md) | Bounded edits to a skill document, scored rollouts, validation-gated updates, deployable `best_skill.md`. [S1] | Worth comparing with GEPA for individual skills. Custom DX tasks need adapters; built-in benchmarks are not a complete software-engineering suite. |
| **[SkillOpt-Sleep](https://github.com/microsoft/SkillOpt/tree/main/skillopt_sleep)** · [Guide](https://github.com/microsoft/SkillOpt/blob/main/docs/sleep/README.md) | Transcript mining, replay, staged skill/memory proposals; Pi source/backend support on `main`. [S2] | Closest to improving from daily sessions. Its Pi backend disables tools, skills, context files, and extensions: not proof of end-to-end coding behavior. Pi support requires source newer than PyPI 0.2.0. |
| **[Anthropic skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator)** | With/without or old/new skill runs, assertions, time/token summaries, human-review viewer, description-trigger optimization. [A2] | Excellent authoring workflow to borrow. Claude-oriented, not a universal isolated eval service. |
| **[Inspect AI](https://github.com/UKGovernmentBEIS/inspect_ai)** · [Docs](https://inspect.aisi.org.uk/) | Native/custom agents and bridges to external agents, including sandboxed CLIs. [I1] | Strong general-purpose alternative when custom multi-turn experiments and model plumbing dominate. More framework integration than this initial need requires. |
| **[NVIDIA SkillEvaluator](https://github.com/NVIDIA/SkillEvaluator)** · [Docs](https://docs.nvidia.com/skills/skillevaluator/) | Static validation, overlap checks, dataset generation, Harbor-backed live skill evaluation. [N1] | Useful for a skill-library quality pipeline; explicitly experimental. Not a replacement for your workflow definitions or an optimizer. |
| **[Tangle agent-eval](https://github.com/tangle-network/agent-eval)** · [Docs](https://github.com/tangle-network/agent-eval/tree/main/docs) | TypeScript execution/judging contracts, paired comparisons, evidence controls, Python bridges to GEPA/SkillOpt/DSPy. [T1] | Interesting TS-first integrated evaluation/optimization layer. Still requires your executor and host-enforced isolation; assess API/dependency complexity before adoption. |
| **[CodexOpt](https://github.com/SuperagenticAI/CodexOpt)** · [Docs](https://superagenticai.github.io/CodexOpt/) | Instruction scanning, heuristic scores, reflective optimization, optional executable/Codex rollout tasks. [C1] | Relevant but not the default choice for Pi. Its default benchmark is mostly document-quality scoring; legacy `--engine gepa` is deprecated and falls back. |

Related libraries used by these pipelines: [SWE-smith](https://swesmith.com/) for verifiable task generation, [mini-SWE-agent](https://github.com/SWE-agent/mini-swe-agent) for a lightweight coding runtime, and [DSPy](https://dspy.ai/) for programmable model pipelines and optimization.

### Most useful existing examples

- **GEPA gskill:** the closest research implementation of “run coding tasks, inspect failures, evolve reusable skills, evaluate held-out performance.” It uses SWE-smith, Docker, and mini-SWE-agent, with separate Claude Code evaluation paths. Reported gains on Jinja/Bleve are authors' benchmark results, not a prediction for these dotfiles. [G2][G3]
- **Harbor `hello-skills`:** small task illustrating injected skills and an executable outcome verifier. Because the prompt explicitly names the skill, it is an execution smoke test, not a natural-discovery eval. [H5]
- **Promptfoo's Test Agent Skills guide:** side-by-side skill fixtures, explicit loading checks, expected-result assertions, and neighboring-skill negative cases. [P2]
- **Anthropic skill-creator:** a ready-made human-review and iteration workflow. Its description optimizer selects using the split it calls “test”; for rigorous reporting, treat that as selection/validation and add a separate untouched final set. [A2]

## First-hand case studies with measured outcomes

The following are reports by the people doing the work, not tool-directory summaries. **All scores are author-reported and were not reproduced here.** Most are offline evaluations of real developer workflows, not randomized production experiments measuring developer productivity. Percentages also measure different things across posts: whole-task success, assertion satisfaction, or benchmark accuracy. Do not compare them as one leaderboard.

### 1. Firebase: eval-driven development of skills and developer tooling

**[Eval-driven development: How we build better agent skills for Firebase](https://firebase.blog/posts/2026/08/eval-driven-development-agent-skills/)** — Charlotte Liang, Firebase, August 11, 2026; results captured July 2026.

Closest match to the requested **developer-experience use-case evals**. Firebase evaluates Critical User Journeys, separates single-skill/activation/multi-skill E2E cases, establishes a no-skills baseline, and iterates skills against observed failures. E2E tasks use real Firebase projects, including creating and deploying an app with authentication, Firestore, and security rules.

| Metric | Without skills | With tuned skills |
| --- | --- | --- |
| Reported pass rate | 31.7% | 78.0% |
| Average input tokens | 285.1k | 169.5k |
| Average output tokens | 9.5k | 5.8k |
| Average duration | 144.3s | 101.2s |

**Real product outcome:** eval failures also led to changes in the CLI, not just prompt edits: [help text](https://github.com/firebase/firebase-tools/pull/10772), [login flow](https://github.com/firebase/firebase-tools/pull/10777), and [interactive-prompt handling](https://github.com/firebase/firebase-tools/pull/10856). The article links those changes as examples and describes a separate CLI suite of roughly 50 cases.

**Boundary:** the post does not supply a complete model/repetition/held-out-split specification for the headline table. Its ~50 CLI cases should not be assumed to be that table's denominator. This demonstrates a product team's eval-driven process and concrete tooling changes, not a measured production-wide productivity increase. [Firebase skills](https://github.com/firebase/agent-skills).

### 2. Vercel: optimizing where documentation lives in AGENTS.md versus skills

**[AGENTS.md outperforms skills in our agent evals](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)** — Jude Gao, January 27, 2026.

They evaluated code using newer Next.js APIs, repaired ambiguous/leaky evals, and compared the same tests across documentation configurations.

| Configuration | Reported pass rate |
| --- | --- |
| No documentation | 53% |
| Skill, default invocation | 53% |
| Skill with explicit invocation guidance | 79% |
| Compressed docs index in `AGENTS.md` | 100% |

The skill went unused in **56%** of cases. An **8 KB** docs index achieved the strongest result; compression from approximately **40 KB to 8 KB** preserved the reported score. The change also became an [official Next.js codemod](https://github.com/vercel/next.js/pull/88961).

**What to copy:** test context placement and discovery, not just prose. An always-loaded compact index plus on-demand reference files may outperform a skill the agent never opens.

**Boundary:** a targeted framework/API eval, not proof that `AGENTS.md` always beats skills. The post says configurations were retried but does not fully disclose sample size, repeat counts, or a sealed final split. Vercel explicitly retains skills as useful for action-specific workflows.

### 3. LangChain: an actual skills-benchmark project to study

**[Evaluating Skills](https://www.langchain.com/blog/evaluating-skills)** — Robert Xu, March 5, 2026.

Claude Code's reported task-completion rate was **9% without skills versus 82% with skills** on their LangChain/LangSmith tasks. They tested different content splits, used Docker isolation and LangSmith traces, and iterated with human review of agent-generated failure summaries. Around **20 similar skills** caused selection mistakes; a **12-skill** configuration selected the intended skills consistently in their tests.

**Most useful artifact:** [langchain-ai/skills-benchmarks](https://github.com/langchain-ai/skills-benchmarks). Its inspected README documents:

- Tasks separate from instruction/skill “treatments,” including no-skills controls.
- `CLAUDE.md` variations, merged/split skills, and distractor skills.
- Docker execution, artifact validators, local reports, and LangSmith integration.
- Repeated runs through pytest and a TypeScript validation scaffold.

This is one of the closest existing **project layouts** to borrow, rather than another generic evaluation library.

**Boundary:** Claude Code and LangChain-specific tasks; the article's aggregate is not an independently reproduced result or a generic coding-success score. The current repository's defaults may differ from the March experiment. Inspect individual task criteria before reusing the aggregate.

### 4. LangChain: improve the agent harness while keeping the model fixed

**[Improving Deep Agents with harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering)** — Vivek Trivedy, February 17, 2026.

With **GPT-5.2-Codex fixed**, Deep Agents improved from **52.8% to 66.5%** on **Terminal-Bench 2.0's 89 tasks**: **+13.7 percentage points**. The setup used **Harbor + Daytona + LangSmith**.

Changes included verification reminders before completion, environment context, loop detection, time-budget awareness, and reasoning-budget allocation. They also report **53.9% at xhigh** versus **63.6% at high** in the described comparisons: more reasoning was not automatically better under timeouts.

**What to copy:** inspect failed traces, classify failure causes, change a specific runtime/prompt behavior, and rerun. This directly supports evaluating extensions and reasoning settings alongside `AGENTS.md` and skills. [Code](https://github.com/langchain-ai/deepagents) · [Published trace dataset](https://smith.langchain.com/public/29393299-8f31-48bb-a949-5a1f5968a744/d?tab=2).

**Boundary:** benchmark-guided harness engineering, not an isolated skill-text experiment or evidence of sealed-test generalization. Multiple components changed; the full improvement cannot be attributed to a single prompt instruction.

### 5. GEPA gskill: automated repository-skill optimization

**[Automatically Learning Skills for Coding Agents](https://gepa-ai.github.io/gepa/blog/2026/02/18/automatically-learning-skills-for-coding-agents/)** — the gskill authors, February 18, 2026.

Using **mini-SWE-agent + GPT-5-mini**, repository-specific skills improved held-out resolve rates:

| Repository | Baseline | Optimized skills |
| --- | --- | --- |
| Jinja | 55% | 82% |
| Bleve | 24% | 93% |

The authors describe approximately 300 generated tasks per repository, train/validation/test splits, and an optimization budget below 300 rollouts. Skills learned on the smaller agent were also evaluated in Claude Code. [Implementation guide](https://github.com/gepa-ai/gepa/blob/main/docs/docs/guides/gskill.md).

**What to copy:** executable task feedback plus traces drives an optimizer that changes a reusable skill—not model weights.

**Boundary:** real repositories, but **SWE-smith-generated repair tasks**, not a stream of naturally occurring production issues. Stronger agents have less headroom. The post is internally inconsistent about the final Bleve/Haiku transfer score (100% near the start, 98.3% in its conclusion), so use the consistent mini-SWE results above rather than silently selecting the largest transfer claim.

### 6. BuidlGuidl: skill pruning and a candid grading failure

**[Evaluating agent skills: testing whether they are actually useful](https://buidlguidl.com/blog/evaluating-agent-skills)** — BuidlGuidl, June 2026.

They evaluated skills for adding integrations to Scaffold-ETH 2. After correcting rubric leakage/self-grading and cleaning the baseline context, their third iteration used **four skills × two configurations × five runs = 40 executions**:

| Metric | Without skills | With skills |
| --- | --- | --- |
| Average assertion score | 42% | 97% |
| Average time | 365s | 217s |
| Average tokens | 27k | 21k |

They also found negative or negligible deltas for some other skills, removed low-value material, and reduced EIP-712/SIWE content from **2,123 to 365 lines**. An earlier self-grading setup had inflated baseline scores; a later expert review found important checks their generated rubric had missed.

**What to copy:** independently grade artifacts, audit the rubric with a domain expert, and allow the outcome to be “delete this skill.” [Project and skills](https://github.com/scaffold-eth/scaffold-eth-2).

**Boundary:** **assertion scores**, not 97% end-to-end task success. With-skill prompts explicitly request the skill, so this does not establish natural triggering. The article's time/token improvements precede the final pruning; it does not establish that every trimmed skill preserved those scores afterward.

### 7. Independent practitioner: useful quality uplift with an efficiency penalty

**[Skills Without Evals Are Just Markdown and Hope](https://dev.to/danielsogl/skills-without-evals-are-just-markdown-and-hope-3a71)** — Daniel Sogl, May 1, 2026.

A real `@ngrx/signals` skill was tested on **five coding tasks and 41 assertions** using Anthropic skill-creator:

- Mean per-task assertion pass rate: **84% → 100%**. Raw assertions: **34/41 → 41/41**; 34/41 is 82.9%, so the headline uses a different aggregation.
- Mean time: **49.0s → 62.7s**.
- Mean tokens: **19,927 → 32,343**.
- Three description-optimization iterations **did not improve** the original description's reported held-out trigger score of **3/7 (42.9%)**.

**What to copy:** evaluate execution and triggering separately, and report latency/token regressions alongside quality. [Skill source](https://github.com/danielsogl/skills/tree/main/skills/ngrx-signals).

**Boundary:** only one execution per task/configuration; reported standard deviations are across tasks, not repeated trials. Many assertions encode preferred idioms rather than demonstrated functional failures. The repeatedly consulted “test” split is selection data, not an untouched final test.

### 8. Databricks: model selection plus prompt optimization, outside coding

**[Building State-of-the-Art Enterprise Agents 90x Cheaper with Automated Prompt Optimization](https://www.databricks.com/blog/building-state-art-enterprise-agents-90x-cheaper-automated-prompt-optimization)** — Databricks AI Research Team, September 24, 2025.

On their held-out **IE Bench** information-extraction evaluation, GEPA-optimized GPT-OSS-120B gained **4.3 score points** over its baseline and exceeded baseline Claude Opus 4.1 by **2.2 points**, at approximately **90× lower serving cost** in their comparison. Optimizing Opus itself improved its score by **6.4 points**.

**What to copy:** optimize the quality/cost frontier across models, with a separate stronger proposer if useful, rather than choosing a model from a public coding leaderboard alone.

**Boundary:** enterprise document extraction, **not coding, `AGENTS.md`, or skill discovery**. The 90× headline is a model-serving comparison, not 90× cheaper total experimentation or a measured customer deployment saving. The article separately discusses optimization expense and lifetime cost.

### Videos worth watching

1. **[Don't Ship Skills Without Evals — Philipp Schmid, Google DeepMind](https://www.youtube.com/watch?v=0vphxNt4wyk)**, AI Engineer. The indexed transcript describes a **117-case** Python/TypeScript Gemini API suite and reports reaching **almost 90%** for the Interactions API example. It explains positive/negative trigger cases, deterministic code checks, clean environments, and regression gates. **Best video match for designing your own skill evals.**
   - [Related first-hand Google blog](https://developers.googleblog.com/closing-the-knowledge-gap-with-agent-skills/) describes the Gemini API skill and test setup. It is related evidence, not necessarily the identical run/version as the talk. Its SDK-pattern checks are narrower than executing every generated app end to end.
2. **[SkillOpt — Controllable Text-Space Optimization for Agent Skills](https://www.youtube.com/watch?v=JUBMDTCiM0M)**. This is the project video linked by the [official Microsoft repository](https://github.com/microsoft/SkillOpt), covering scored rollouts, bounded edits, and validation-gated skill updates. The project reports best/tied-best results in **52 evaluated settings** across its chosen models/benchmarks/harnesses. **Useful optimizer overview, not a production DX case study.** Consult the paper's per-benchmark results rather than interpreting that count as a universal win rate.
3. **[Evals Are Broken, Use Them Anyway — Ara Khan, Cline](https://www.youtube.com/watch?v=QuuIywMG4s8)**, AI Engineer. A first-hand discussion of Cline's Terminal-Bench work with Harbor, failure-trace analysis, container resource limits, timeouts, and model-specific prompting. Useful for understanding why a changed score may reflect environment/harness fixes rather than model ability. No precise before/after pair is claimed here because the full result was not verified from the inspected primary transcript.

Video notes are based on indexed transcripts where available and the official project's linked description, not on watching the complete videos or reproducing their demonstrations.

### Suggested reading order and conclusion

Start with **Firebase → LangChain Evaluating Skills and its benchmark repo → Vercel → GEPA gskill**. Add the Deep Agents article when evaluating runtime/extensions and reasoning settings; read BuidlGuidl and the NgRx report before trusting your own grader.

These provide concrete evidence that eval-driven iteration can improve targeted developer workflows. They do **not** establish that automatic text optimization consistently beats a careful manual edit, or that benchmark gains transfer unchanged to daily Pi use. The strongest practical pattern is still: real failure → reviewed eval → measured change → regression check, whether the proposed fix changes a skill, `AGENTS.md`, a tool, or the harness.

## Proposed project setup

This is a suggested layout, not a generated scaffold or a framework-prescribed schema:

```text
devx-evals/
├── pyproject.toml
├── uv.lock
├── flake.nix
├── tasks/
│   ├── fix-parser-regression/
│   │   ├── instruction.md
│   │   ├── task.toml
│   │   ├── environment/Dockerfile
│   │   ├── tests/test.sh
│   │   └── solution/solve.sh
│   ├── review-auth-change/
│   └── add-home-manager-module/
├── splits/
│   ├── train.json
│   ├── validation.json
│   └── test.json
├── candidates/
│   ├── baseline/
│   └── candidate-001/
├── experiments/
├── runner/
│   ├── materialize_candidate.py
│   └── evaluate.py
├── optimization/
│   └── optimize_instructions.py
└── results/
```

Use a standalone repo if evaluating shared skills across multiple projects; use a local `evals/` directory if the scope stays confined to one repo. Pin fixture repositories by commit. Nix can pin development tools; container images and their contents must also be pinned. Keep large traces outside Git and store compact manifests/reports with content hashes.

### Task contract

Harbor supplies the task-directory structure. Each task contains an instruction, environment definition, configuration, and executable verifier. The verifier writes a numeric reward or a map of numeric metrics. Reference solutions are optional but useful for checking the evaluator. [H3]

For each DX case, additionally record:

- A realistic user request and the repository state before the work began.
- Outcome criteria, permissible scope, and prohibited side effects.
- A deterministic verifier wherever feasible; a calibrated rubric for genuinely subjective dimensions.
- Required tools, network dependencies, credentials policy, and time limits.
- A task-family label and fixed split assignment.

Keep private verifiers/reference solutions out of agent-visible fixtures. Run trusted grading against exported artifacts in a separate environment when shared-environment tampering is a concern; Harbor supports separate verifier environments. A container alone does not guarantee sound grading. [H3]

### Candidate contract

A candidate should identify:

- Runtime version and extension/tool bundle hash.
- Provider, exact model identifier, reasoning level, and generation limits.
- Global instructions, repository instructions, and each skill bundle by content hash.
- Image/repository revisions and any explicitly enabled external resources.

Materialize a **fresh candidate copy per trial**, never edit live installed skills. Keep experiment control files, final cases, and the optimizer outside the agent workspace. Declare which files/sections the optimizer may change. Safety constraints and verifier code are not optimization targets.

### Execution and optimization

```text
real incidents → reviewed tasks → baseline trials → failure analysis
                                       ↓
                         manual edit or GEPA candidate
                                       ↓
                fresh environment + candidate instructions/skills
                                       ↓
                       real agent → artifacts + trace
                                       ↓
                        trusted verifiers + rubric
                                       ↓
                 score + diagnostic feedback → optimizer
                                       ↓
                    validation selection → sealed final eval
                                       ↓
                          human-reviewed adoption
```

GEPA's evaluator accepts candidate text/components and returns a score plus diagnostic side information. Feed it test failures, relevant trace excerpts, scope violations, and measured costs—not just a pass/fail number. The existing GEPA Terminal-Bench adapter inspected in this research invokes the older `tb run` interface; it is not a ready-made Pi/Harbor multi-file adapter. Prefer a small evaluator around the current Harbor runner. [G1][G4]

Harbor's documented CLI shape is:

```bash
harbor agent schema pi
harbor run -p ./tasks -a pi -m '<provider>/<model>' --skill ./candidate-skills
```

These are starting-point commands, not a complete experiment configuration: model credentials, candidate `AGENTS.md`, version pins, repetitions, limits, and fixture isolation must also be configured. [H1][H2][H4]

## What the evals should measure

Suggested initial cases:

| Use case | Primary evidence | Important negative check |
| --- | --- | --- |
| Fix a regression | Hidden regression tests and existing tests pass | No test deletion or unrelated rewrite |
| Add a small feature | Acceptance tests and backward compatibility | No unnecessary dependencies or public API changes |
| Review a change | Recall **and precision** against seeded defects; valid file/line evidence | Does not invent findings or edit the repo |
| Diagnose a failure | Correct cause and reproducible evidence | Does not claim a check ran when it did not |
| Modify Nix configuration | Targeted evaluation plus expected option/module placement | No rebuild/switch, secret access, or unrelated host edits |
| Follow a workflow skill | Requested artifact and required observable actions | Does not merely mention the steps |
| Select a skill naturally | Appropriate skill-file loading on realistic prompts | Avoids neighboring skills on near-misses |
| Handle ambiguity | Appropriate clarification or conservative action | Does not stall on questions whose answers are already available |

Separate three skill questions:

1. **Discovery:** is the right skill loaded under normal prompting, with neighboring skills present?
2. **Execution:** when explicitly supplied, does it produce the intended behavior?
3. **Net utility:** does having it available improve outcomes enough to justify latency, tokens, and interventions?

Do not equate loading a skill with success. In Pi, normal skill loading is a file read, not a dedicated `Skill` tool call; cross-harness trigger metrics need normalization. Pi's documentation describes the metadata-first, on-demand loading behavior. [L2]

For developer experience, keep at least these dimensions separate:

- Correctness / task completion.
- Safety and scope compliance, with hard gates where appropriate.
- Reviewability and unnecessary work, assessed by a calibrated rubric.
- Cost, token usage, wall-clock latency, and human interventions.
- Skill discovery/selection quality.

Prefer correctness and safety gates followed by cost/latency comparisons over one opaque weighted score that can reward cheap failures. Report setup time separately from agent time. Local models with zero configured token prices still consume compute; missing cost must not silently become “free.” The Harbor Pi adapter only reports a monetary total when parsed usage contains positive cost. [H2]

## Experimental discipline

These are recommendations, not guarantees provided by a framework:

1. **Begin with 10–20 real cases** to find runner/verifier defects, not to claim statistical superiority.
2. Include known-good reference outcomes and deliberately bad/no-op outcomes to check graders.
3. Compare current instructions, a minimal-policy baseline, and a focused candidate on identical tasks.
4. Change one axis at a time initially: skill body, trigger description, `AGENTS.md`, then model/reasoning settings. Later test interactions.
5. Repeat trials. Start with roughly three repetitions for noisy cases and increase when decisions remain uncertain.
6. Report paired task-level outcomes, regressions, and uncertainty. Repeated trials on one task are not independent new tasks.
7. Split by underlying issue/task family, not prompt paraphrase. For global skills, hold out entire repositories where possible.
8. Keep train, selection/validation, and final test distinct. Reusing final results to guide edits turns that set into development data.
9. Freeze graders and acceptance criteria before comparison; blind subjective graders to candidate/model identity and calibrate against human review.
10. Apply hard trial timeouts, concurrency limits, and an explicit spending cap covering agent, proposer, and judge calls. A metric-call limit alone is not a dollar cap.
11. Separate infrastructure errors from agent failures; define retry/exclusion handling before running.
12. Keep transcript-derived task material private until reviewed and redacted. Do not publish raw session traces by default.

Model optimization should start with a quality/cost frontier across a few fixed models and reasoning budgets. Test whether a smaller model plus improved instructions meets the same quality gates. Do not assume learned skills transfer across models without testing. Actual weight optimization is a later project: Harbor documents SFT/RL workflows and SkyRL integration, but that requires training infrastructure and suitable rollout/token data. [H6]

## Fit with these dotfiles

Existing integration points:

- `modules/home/cli/pi-mono.nix` installs the Pi package and exposes global instructions, skills, extensions, and settings through Home Manager.
- `modules/home/cli/pi-mono/AGENTS.md` and `modules/home/cli/pi-mono/skills/` are the source-controlled instruction assets.
- `modules/home/cli/pi-mono/skills/improve-skill/SKILL.md` already describes extracting Pi/Claude/Codex sessions and proposing improvements. It does **not** currently gate changes on executable evals. Treat it as a source of candidate tasks/edits, not evidence of improvement.
- `modules/home/cli/pi-mono/nix/package.nix` builds Pi from pinned release source; Harbor's stock adapter instead installs an npm package. Matching the model alone will not reproduce the local setup. [L1][H2]

For faithful local-setup evaluation:

1. Start with Harbor's Pi adapter rather than writing an agent loop.
2. Explicitly supply the relevant instruction files, skills, extensions, provider settings, and Pi version.
3. Use a clean home/config directory and fresh fixture for every trial; do not mount the real home, SSH keys, secret store, or Docker socket into the agent.
4. Account for Pi project trust: non-interactive runs can ignore project-local skills/settings/extensions without an applicable trust decision. Trust only the curated fixture/resources intended for that trial. Context-file loading has its own behavior. [L2]
5. Check resource-loading evidence before measuring improvements. The stock adapter does not reproduce this repository's entire Nix-managed configuration automatically.
6. Adopt reviewed changes back into the source files, never through optimizer writes to Home Manager symlinks.

**Practical first milestone:** build five trustworthy cases covering a bug fix, a review, a Nix module edit, a skill-trigger near-miss, and a regression from a real session. Compare the current configuration against one manually improved candidate on the same model. Add GEPA only after the measurements are credible.

## Research boundaries and version checks

This is primary-source/documentation and source-code research. No live agent benchmarks, paid optimization, package installs, or Nix rebuilds were run. The proposed combined setup has not been implemented or validated here.

At research time, PyPI reported Harbor **0.23.0** (Python >=3.12), GEPA **0.1.4**, and SkillOpt **0.2.0**. Harbor's `v0.23.0` Pi source was directly checked. The downloaded GEPA 0.1.4 wheel contains both `gepa/optimize_anything.py` and `gepa/gskill/`; older third-party installation warnings about their absence should not be applied blindly. Presence is not an end-to-end compatibility test.

Observed `main` revisions for reproducible follow-up:

- Harbor: `0d67ca4b59206aca2734bf9fe0260ca79e08acb4`
- GEPA: `15ee314f9c7d34ec153b809d401f42f55c4dcd76`
- SkillOpt: `79124b37e9a6371e13b753f8bcd7adb1e493ade1`
- Tangle agent-eval: `47efa374628b991c38d8d585612452beef98f156`

Pin compatible releases/commits and smoke-test the exact combination before adoption. In particular, SkillOpt-Sleep's Pi support is newer than its published 0.2.0 release. [S2]

## Sources

- [H1] [Harbor agents and custom-agent interface](https://www.harborframework.com/docs/agents)
- [H2] [Harbor Pi adapter, v0.23.0](https://github.com/harbor-framework/harbor/blob/v0.23.0/src/harbor/agents/installed/pi.py)
- [H3] [Harbor task structure and verifier isolation](https://www.harborframework.com/docs/tasks)
- [H4] [Harbor skills and provenance](https://www.harborframework.com/docs/run-jobs/skills)
- [H5] [Harbor hello-skills example](https://github.com/harbor-framework/harbor/tree/main/examples/tasks/hello-skills)
- [H6] [Harbor RL workflows](https://www.harborframework.com/docs/training-workflows/rl)
- [G1] [GEPA quick start / optimize_anything](https://github.com/gepa-ai/gepa/blob/main/docs/docs/guides/quickstart.md)
- [G2] [GEPA gskill guide](https://github.com/gepa-ai/gepa/blob/main/docs/docs/guides/gskill.md)
- [G3] [GEPA authors: Automatically Learning Skills for Coding Agents](https://gepa-ai.github.io/gepa/blog/2026/02/18/automatically-learning-skills-for-coding-agents/)
- [G4] [GEPA legacy Terminal-Bench adapter](https://github.com/gepa-ai/gepa/blob/main/src/gepa/adapters/terminal_bench_adapter/terminal_bench_adapter.py)
- [P1] [Promptfoo: Evaluate Coding Agents](https://www.promptfoo.dev/docs/guides/evaluate-coding-agents/)
- [P2] [Promptfoo: Test Agent Skills](https://www.promptfoo.dev/docs/guides/test-agent-skills/)
- [P3] [Promptfoo JavaScript/TypeScript providers](https://www.promptfoo.dev/docs/providers/custom-api/)
- [S1] [Microsoft SkillOpt documentation](https://github.com/microsoft/SkillOpt/blob/main/docs/index.md)
- [S2] [SkillOpt-Sleep: Pi integration, boundaries, and version caveats](https://github.com/microsoft/SkillOpt/blob/79124b37e9a6371e13b753f8bcd7adb1e493ade1/docs/sleep/README.md)
- [A1] [Anthropic: Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [A2] [Anthropic skill-creator source](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md)
- [I1] [Inspect AI Agent Bridge](https://inspect.aisi.org.uk/agent-bridge.html)
- [N1] [NVIDIA SkillEvaluator](https://github.com/NVIDIA/SkillEvaluator)
- [T1] [Tangle agent-eval README at inspected revision](https://github.com/tangle-network/agent-eval/blob/47efa374628b991c38d8d585612452beef98f156/README.md)
- [C1] [CodexOpt README, scoring and optimization behavior](https://github.com/SuperagenticAI/CodexOpt)
- [R1] [Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988)
- [R2] [SkillsBench](https://arxiv.org/abs/2602.12670)
- [L1] Local files inspected: `modules/home/cli/pi-mono.nix`, `modules/home/cli/pi-mono/nix/package.nix`, and `modules/home/cli/pi-mono/skills/improve-skill/SKILL.md`.
- [L2] Installed Pi **0.85.1** documentation inspected in full: `README.md`, `docs/skills.md`, and `docs/environment-variables.md` under the installed package. [Upstream documentation](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/docs).
