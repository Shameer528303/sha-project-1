# syntax=docker/dockerfile:1.6

############################
# Stage 1: builder (wheels)
############################
FROM python:3.11-slim AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN python -m pip install --upgrade pip \
    && pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt


############################
# Stage 2: runtime
############################
FROM python:3.11-slim AS runtime

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Compose healthcheck uses curl, so install it here.
# (Also useful for debugging containers.)
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd --create-home --uid 1000 --shell /usr/sbin/nologin appuser

# Install dependencies from wheels (no compiler needed here)
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN python -m pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt \
    && rm -rf /wheels

# Copy app source last
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8000

# Optional defaults (compose overrides these anyway)
ENV PORT=8000 \
    AWS_REGION=us-east-1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
