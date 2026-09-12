import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    SECRET_KEY: str = os.getenv("SECRET_KEY", "insecure_dev_key_change_me")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "120"))
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "http://localhost:5173")

    # n8n webhook URLs (leave blank to disable a given notification)
    N8N_NEW_EXPORT_ORDER_WEBHOOK: str = os.getenv("N8N_NEW_EXPORT_ORDER_WEBHOOK", "")
    N8N_SHIPMENT_UPDATE_WEBHOOK: str = os.getenv("N8N_SHIPMENT_UPDATE_WEBHOOK", "")
    N8N_AUTOMATION_KEY: str = os.getenv("N8N_AUTOMATION_KEY", "")


settings = Settings()
