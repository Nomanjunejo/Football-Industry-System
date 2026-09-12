# n8n Automation

Four workflows automate notifications around inventory and exports. Each `.json` file in `workflows/` can be
imported directly into n8n.

| Workflow | Trigger | What it does |
|---|---|---|
| `low_stock_alert.json` | Schedule (every 6h) | Calls `GET /api/analytics/low-stock/automation`, formats a message listing any product below its reorder level |
| `new_export_order.json` | Webhook | FastAPI calls this webhook right after `POST /api/export/orders` succeeds; formats a "new order placed" message |
| `shipment_update.json` | Webhook | FastAPI calls this webhook after `PATCH /api/export/orders/{id}/shipment`; formats a "shipment status changed" message |
| `scheduled_report.json` | Schedule (weekly) | Calls `GET /api/analytics/scheduled-report-summary`, formats a weekly digest |

Each workflow ends in a **NoOp "Send Notification" node** as a placeholder — swap it for n8n's built-in
**Email**, **Slack**, **Telegram**, or **Discord** node and point it at wherever you want alerts to land. This
keeps the demo runnable without requiring you to have a real SMTP/Slack account configured.

## Install n8n locally

```bash
npx n8n
```

(or `npm install -g n8n && n8n start`). n8n starts at **http://localhost:5678**.

## Import the workflows

1. Open http://localhost:5678
2. For each file in `workflows/`: **Workflows → Import from File** → select the `.json` file → **Save**
3. Set an environment variable n8n can read as `N8N_AUTOMATION_KEY` (matching the backend's `.env` value) —
   either export it before running `n8n start`, or hardcode the same string directly into the two HTTP
   Request nodes' `X-Automation-Key` header if you'd rather skip environment variables for the demo.
4. **Activate** each workflow (toggle top-right of the workflow editor).

## Wire the webhooks back into the backend

After activating `new_export_order.json` and `shipment_update.json`, each Webhook node's node panel shows a
**Production URL** (e.g. `http://localhost:5678/webhook/new-export-order`). Copy these into the backend's
`.env`:

```
N8N_NEW_EXPORT_ORDER_WEBHOOK=http://localhost:5678/webhook/new-export-order
N8N_SHIPMENT_UPDATE_WEBHOOK=http://localhost:5678/webhook/shipment-update
```

Restart the FastAPI server after editing `.env`. From then on, placing an export order or updating a
shipment's status in the admin panel will trigger the corresponding n8n workflow automatically. If n8n is
offline or a URL is blank, the backend logs a warning and continues normally — a notification failure never
blocks the underlying database operation (see `backend/app/services/n8n_notify.py`).

## Testing without waiting for a real trigger

Every workflow can be run manually from the n8n editor with **Execute Workflow** — useful for demoing to your
instructor without needing to wait 6 hours for the low-stock schedule or place a real order.
