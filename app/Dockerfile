# syntax=docker/dockerfile:1.6

############################
# Stage 1: builder (wheels)
############################
FROM python:3.11.8-slim-bookworm AS builder
# Tip: for maximum determinism, pin to a digest:
# FROM python:3.11.8-slim-bookworm@sha256:<digest> AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Build tools only in builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Build wheels so runtime doesn't need compilers
RUN python -m pip install --upgrade pip setuptools wheel \
    && pip wheel --wheel-dir /wheels -r requirements.txt


############################
# Stage 2: runtime
############################
FROM python:3.11.8-slim-bookworm AS runtime
# Tip: for maximum determinism, pin to a digest:
# FROM python:3.11.8-slim-bookworm@sha256:<digest> AS runtime

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Patch OS packages (reduces many glibc/openssl/etc CVEs)
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd --create-home --uid 1000 --shell /usr/sbin/nologin appuser

# Install deps from wheels (no compilers here)
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN python -m pip install --no-index --find-links=/wheels -r requirements.txt \
    && rm -rf /wheels

# Copy app code last (better caching)
COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 8000

# Healthcheck WITHOUT requests/curl (lower dependency surface)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).read()" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
