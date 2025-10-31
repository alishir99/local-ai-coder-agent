FROM python:3.11-slim

# Install testing tools once
RUN pip install pytest coverage

WORKDIR /app
