from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.endpoints import auth, expenses, scenario
from app.db import base  # noqa: F401

app = FastAPI(title="GastoApp API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this once you have a fixed set of clients
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(expenses.router)
app.include_router(scenario.router)


@app.get("/health")
async def health_check():
    return {"status": "online", "app": "GastoApp Backend"}