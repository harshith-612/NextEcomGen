import os
from mailjet_rest import Client

mailjet = Client(
    auth=(os.getenv("MAILJET_API_KEY"), os.getenv("MAILJET_API_SECRET")),
    version="v3.1"
)

def send_verification_email(email: str, token: str):
    verification_link = f"http://localhost:8000/users/verify-email?token={token}"

    data = {
        "Messages": [
            {
                "From": {
                    "Email": "hemaharshithreddygulimcherla@gmail.com",
                    "Name": "Your App"
                },
                "To": [
                    {
                        "Email": email
                    }
                ],
                "Subject": "Verify Your Email",
                "HTMLPart": f"""
                    <h2>Welcome to NextEcomGen!</h2>
                    <p>Click the button below to verify your email.</p>
                    <a href="{verification_link}">Verify Email</a>
                """
            }
        ]
    }

    result = mailjet.send.create(data=data)

    if result.status_code != 200:
        raise Exception(f"Mailjet error: {result.status_code} - {result.json()}")