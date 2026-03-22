# Feature Orchestrator for Claude CLI

A drop-in multi-agent orchestration setup for Laravel + Angular + SaaS projects.

## What this version adds

This version can now:
- auto-generate the next feature folder from a title
- run the latest draft feature automatically
- generate `prompt.final.txt`
- save the full Claude response to `raw-output.md`
- auto-split the Claude response into:
  - `plan.md`
  - `execution.md`
  - `qa.md`
  - `docs.md`
- mark the feature as completed and update `features/latest.txt`

## Main workflow

### Bash
```bash
bash scripts/new-feature.sh "Public Pages Redesign"
# edit features/<generated-feature-id>/request.txt
bash scripts/run-feature.sh
bash scripts/finish-feature.sh
```

### PowerShell
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\new-feature.ps1 "Public Pages Redesign"
# edit features\<generated-feature-id>\request.txt
powershell -ExecutionPolicy Bypass -File .\scripts\run-feature.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\finish-feature.ps1
```

## What `run-feature` does

1. Finds the latest feature with `status.txt = draft`
2. Reads `request.txt`
3. Injects it into `prompts/run-feature.txt`
4. Creates `prompt.final.txt`
5. Runs Claude CLI if available
6. Saves the full reply to `raw-output.md`
7. Auto-splits the reply into:
   - `plan.md`
   - `execution.md`
   - `qa.md`
   - `docs.md`
8. Updates `outputs/last-run.md`
9. Sets `status.txt = running`

## If Claude CLI is not available

The script still generates `prompt.final.txt`.
You can then run:

```bash
claude
```

Then paste the contents of:

```text
features/<feature-id>/prompt.final.txt
```

After Claude responds, paste the full response into:

```text
features/<feature-id>/raw-output.md
```

Then run the split helper:

### Bash
```bash
bash scripts/split-output.sh
```

### PowerShell
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\split-output.ps1
```

## Auto-split rules

The splitter looks for these headings in the Claude response:
- Feature Summary
- Implementation Plan
- Backend Tasks
- Frontend Tasks
- SaaS Validation
- QA Checklist
- Documentation Updates
- Risks / Assumptions
- Final Execution Summary

It places them into files like this:
- `plan.md`:
  - Feature Summary
  - Implementation Plan
  - Backend Tasks
  - Frontend Tasks
  - SaaS Validation
  - Risks / Assumptions
- `execution.md`:
  - Final Execution Summary
- `qa.md`:
  - QA Checklist
- `docs.md`:
  - Documentation Updates

## Notes

- This setup does not force all MCP servers or tools to be used.
- Planning stays mandatory before implementation.
- Existing auth and SaaS logic should remain intact unless the feature explicitly changes them.
