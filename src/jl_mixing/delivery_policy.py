"""Shared policy gate for delivery planning and creation."""

from __future__ import annotations

from dataclasses import replace

from .delivery import DeliveryCreateRequest, DeliveryCreateResult, create_delivery as _create_delivery
from .errors import ValidationError


def _validate_requested_deliverables(result: DeliveryCreateResult) -> None:
    delivery = result.manifest.get("delivery")
    requested = delivery.get("requested_deliverables") if isinstance(delivery, dict) else None
    if not isinstance(requested, list):
        return
    requested_types = {
        item for item in requested
        if isinstance(item, str) and item
    }
    selected_types = {item.deliverable_type for item in result.plan.selected}
    missing = sorted(requested_types - selected_types)
    if missing:
        raise ValidationError(
            "Delivery is missing required deliverable types: " + ", ".join(missing)
        )


def create_delivery(request: DeliveryCreateRequest) -> DeliveryCreateResult:
    """Plan, validate project delivery requirements, then mutate if requested."""
    preview_request = request if request.dry_run else replace(request, dry_run=True)
    preview = _create_delivery(preview_request)
    _validate_requested_deliverables(preview)
    if request.dry_run:
        return preview
    return _create_delivery(request)
