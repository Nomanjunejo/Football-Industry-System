"""
Run this once after loading the database seed data to produce real
bcrypt hashes for the demo password, then paste the printed UPDATE
statement into SSMS. The seed script ships with a placeholder hash
that will NOT verify correctly against the real passlib/bcrypt
implementation, so this step is required before you can log in.

Usage (from the backend/ directory, with the virtualenv active):
    python -m app.utils.generate_demo_hashes
"""
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

DEMO_PASSWORD = "Passw0rd!"

if __name__ == "__main__":
    hashed = pwd_context.hash(DEMO_PASSWORD)
    print(f"Bcrypt hash for demo password '{DEMO_PASSWORD}':\n{hashed}\n")
    print("Run this in SSMS to update every seeded demo account at once:\n")
    print(f"UPDATE Employee SET PasswordHash = '{hashed}';")
    print(f"UPDATE Customer SET PasswordHash = '{hashed}';")
