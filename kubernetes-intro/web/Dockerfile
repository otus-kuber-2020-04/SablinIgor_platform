FROM python:3.7-alpine

RUN useradd -r -u 1001 -g appuser appuser

USER appuser

WORKDIR /app

COPY app/* /app

EXPOSE 8000

CMD python -m http.server


