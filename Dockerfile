FROM python:3.14-slim-bookworm

WORKDIR /service

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=v1
ENV HEALTH_MODE=healthy

COPY app/requirements.txt ./requirements.txt

RUN python -m pip install --no-cache-dir -r requirements.txt

RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid 10001 \
    --no-create-home --shell /usr/sbin/nologin appuser

COPY --chown=appuser:appuser app/ ./app/

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2)"]

CMD ["gunicorn", "--no-control-socket", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "2", "--access-logfile", "-", "--error-logfile", "-", "app.app:app"]
