from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

@app.get("/", response_class=HTMLResponse)
def root():
    return """
    <html>
    <body style="background:#111;color:#eee;font-family:sans-serif;">
        <h1>Kiosk OK</h1>
        <p>FastAPI działa</p>
    </body>
    </html>
    """