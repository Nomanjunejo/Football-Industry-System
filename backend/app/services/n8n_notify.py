"""
Fire-and-forget calls to n8n webhooks. Notifications must never break the
main request: if n8n is offline or a URL isn't configured, we log and move
on rather than raising, so placing an export order or updating a shipment
always succeeds from the user's point of view even if n8n is down.
"""
import logging
import httpx
from app.config import settings

logger = logging.getLogger("n8n_notify")


def _post(url: str, payload: dict):
    if not url:
        return
    try:
        httpx.post(url, json=payload, timeout=5.0)
    except httpx.HTTPError as e:
        logger.warning("n8n webhook call to %s failed: %s", url, e)


def notify_new_export_order(order) -> None:
    _post(settings.N8N_NEW_EXPORT_ORDER_WEBHOOK, {
        "event": "new_export_order",
        "export_order_id": order.ExportOrderID,
        "destination_country": order.DestinationCountry,
        "total_amount": float(order.TotalAmount),
        "client_id": order.ClientID,
    })


def notify_shipment_update(shipment) -> None:
    _post(settings.N8N_SHIPMENT_UPDATE_WEBHOOK, {
        "event": "shipment_update",
        "export_order_id": shipment.ExportOrderID,
        "shipment_status": shipment.ShipmentStatus,
        "tracking_number": shipment.TrackingNumber,
    })
