# Dockerfile
FROM python:3.11-slim

# Устанавливаем Tkinter 
RUN apt-get update && \
    apt-get install -y python3-tk && \
    rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копируем файлы
COPY main.py .
COPY src/ ./src/

# Запуск через main.py
CMD ["python", "main.py"]
