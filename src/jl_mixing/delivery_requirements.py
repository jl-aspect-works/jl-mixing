"""Reconcile managed delivery status against current project delivery requirements."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def reconcile_delivery_requirements(project: Path, data: dict[str, Any]) -> dict[str, Any]:
    """Mark existing delivery state stale when current project requirements differ.

    Delivery artifacts are deliberately not mutated. Reconciliation is read-side:
    every delivery.status call compares the current project manifest to the
    persisted delivery manifest, so project.update cannot leave readiness falsely
    current.
    """
    project_path = project / "00_Admin" / "project-manifest.json"
    delivery_path = project / "05_Final_Delivery" / "delivery-manifest.json"
    if not delivery_path.is_file() or delivery_path.is_symlink():
        return data
    try:
        project_doc = json.loads(project_path.read_text(encoding="utf-8"))
        delivery_doc = json.loads(delivery_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return data
    project_delivery = project_doc.get("delivery") if isinstance(project_doc, dict) else None
    built_delivery = delivery_doc.get("delivery") if isinstance(delivery_doc, dict) else None
    files = delivery_doc.get("files") if isinstance(delivery_doc, dict) else None
    if not isinstance(project_delivery, dict) or not isinstance(built_delivery, dict) or not isinstance(files, list):
        return data

    expected_method = project_delivery.get("method")
    built_method = built_delivery.get("method")
    requested = project_delivery.get("requested_deliverables")
    requested_set = set(requested) if isinstance(requested, list) else set()
    built_types = {
        item.get("deliverable_type")
        for item in files
        if isinstance(item, dict) and isinstance(item.get("deliverable_type"), str) and item.get("deliverable_type") != "unclassified"
    }

    issues = data.setdefault("issues", [])
    mismatch = False
    if expected_method != built_method:
        mismatch = True
        issues.append({
            "code": "DELIVERY_METHOD_CHANGED",
            "message": "Project delivery method changed after the managed delivery was built.",
        })
    if requested_set != built_types:
        mismatch = True
        missing = sorted(requested_set - built_types)
        extra = sorted(built_types - requested_set)
        details: list[str] = []
        if missing:
            details.append("missing required types: " + ", ".join(missing))
        if extra:
            details.append("previously requested types still present: " + ", ".join(extra))
        issues.append({
            "code": "DELIVERY_REQUIREMENTS_CHANGED",
            "message": "Project requested deliverables changed after the managed delivery was built" + (f" ({'; '.join(details)})" if details else "") + ".",
        })

    if mismatch:
        data["state"] = "needs_attention"
        if data.get("package_state") == "current":
            data["package_state"] = "stale"
            data["current_package"] = None
    return data
