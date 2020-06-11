import os

# debugging
reload = True  # default: False

# logging
loglevel = "info"  # default: "info"

# server socket
port = os.getenv("PORT", 8080)
bind = [":{port}".format(port=port)]  # default: ['127.0.0.1:8000']
backlog = 2048  # default: 2048

# worker processes
workers = 4  # default: 1
worker_class = "uvicorn.workers.UvicornWorker"  # default: "sync"
threads = 4  # default: 1, only for gthread worker_class
worker_connections = 1000  # default: 1000, only eventlet and gevent worker_class
max_requests = 100  # default: 0
max_requests_jitter = 10  # default: 0
timeout = 30  # default: 30
graceful_timeout = 30  # default: 30
keepalive = 2  # default: 2
