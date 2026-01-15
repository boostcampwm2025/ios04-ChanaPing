import type { Decision, ModerationResult } from "./types.ts";
import { ALLOWED_LABELS } from "./config.ts";

function normalizeDecision(decision: unknown): Decision {
  if (decision === "ALLOW" || decision === "REVIEW" || decision === "BLOCK") return decision;
  return "UNKNOWN";
}

export function validateModerationResult(obj: any): ModerationResult {
  const decision = normalizeDecision(obj?.decision);
  const labelsRaw: unknown = obj?.labels;
  const scoreRaw: unknown = obj?.score;
  const reasonRaw: unknown = obj?.reason;

  const labels = Array.isArray(labelsRaw)
    ? (labelsRaw.filter((x) => typeof x === "string") as string[])
    : [];

  const filteredLabels = labels.filter((l) => ALLOWED_LABELS.has(l));
  const score = typeof scoreRaw === "number" && Number.isFinite(scoreRaw) ? scoreRaw : 0;
  const reason = typeof reasonRaw === "string" ? reasonRaw : "";

  return { decision, labels: filteredLabels, score, reason };
}
