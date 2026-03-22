# Source Code Posture Risk Score
**Status:** Draft v1

## 1. Objective
Create a single score (`0-100`) to measure each repository's security posture, support prioritization, and automate remediation actions with low noise.

## 2. Guiding Principles
- Guardrails, not gatekeepers.
- High signal, low noise.
- End-to-end automation.
- Self-service for developers.
- Integrate with existing developer workflows (GitHub, GitLab, Bitbucket).

## 3. Score Model
### 3.1 Final Formula
```text
Score = (P_controls * 0.40) + (P_governance * 0.30) + (P_risk * 0.30)
```

### 3.2 Pillars
| Pillar | Description | Range | Weight |
|---|---|---:|---:|
| `P_controls` | Automated security controls | 0-100 | 40% |
| `P_governance` | Source code governance quality | 0-100 | 30% |
| `P_risk` | Risks and vulnerabilities | 0-100 | 30% |

## 4. Pillar Definitions
### 4.1 `P_controls` (40%)
Sub-items (`25` points each):
- SCA enabled and configured.
- SAST enabled and configured.
- Secret scanning enabled.
- Security gate / policy enforcement enabled.

Formula:
```text
P_controls = (points_earned / 100) * 100
```

Example: `3/4` controls enabled => `75`.

### 4.2 `P_governance` (30%)
Internal weighted sub-items:

| Sub-item | Weight |
|---|---:|
| Branch protection on default branch | 30% |
| Healthy commit frequency (last 90 days) | 25% |
| Bus factor / multiple contributors (last 90 days) | 20% |
| Required code review (PR + approval) | 15% |
| Required status checks for merge | 10% |

Formula:
```text
P_governance = sum(subitem_score * subitem_weight)
```

Each sub-item score is `0-100`.

### 4.3 `P_risk` (30%)
Based on open alerts (Dependabot, Code Scanning, Secret Scanning), with severity penalties.

Formula:
```text
Penalty = (Critical * 10) + (High * 6) + (Medium * 3) + (Low * 1)
P_risk = max(0, 100 - Penalty)
```

Optional (Phase 2): apply an aging factor so older alerts reduce score more.

## 5. Final Classification
| Score Range | Classification |
|---:|---|
| 85-100 | Low risk |
| 70-84 | Moderate risk |
| 50-69 | High risk |
| 0-49 | Critical |

## 6. Expected Output
### 6.1 Per Repository
- Final score.
- Score by pillar.
- Top factors decreasing score.
- Trend versus previous execution.

### 6.2 Organization-Wide
- Overall average score.
- Distribution by risk band.
- Top 10 repositories for prioritization.

## 7. Automation Rules (Issue vs PR)
### Open an Issue Automatically When
- Score `< 70`.
- Mandatory controls are missing (for example: no SAST/SCA/Secret Scanning).
- Critical open alerts exist.

### Open a Pull Request Automatically When
- A safe mechanical fix is possible.
- A standard file is missing (for example: Dependabot config, workflow, policy file).
- The change is low-risk and reversible.

## 8. Noise Reduction Rules
- Do not open duplicate issues for the same control within a `14-day` window.
- Consolidate multiple findings from one repository into a single issue.
- Ignore alerts formally accepted/suppressed by policy.

## 9. Worked Example
Inputs:
- `P_controls = 75`
- `P_governance = 80`
- `P_risk = 62`

Calculation:
```text
Score = (75 * 0.40) + (80 * 0.30) + (62 * 0.30)
Score = 30 + 24 + 18.6 = 72.6
```

Rounded result: **73 (Moderate risk)**.
