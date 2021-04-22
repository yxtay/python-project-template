import multiprocessing
import os

from dotenv import load_dotenv

load_dotenv()

# debugging
reload = True  # default: False

# logging
loglevel = "info"  # default: "info"
worker_tmp_dir = "/dev/shm"  # nosec, default: None

# server socket
host = os.environ.get("HOST", "0.0.0.0")  # nosec
port = os.environ.get("PORT", "8000")
bind = [f"{host}:{port}"]  # default: ["127.0.0.1:8000"]

# workers, default: 1
web_concurrency = os.environ.get("WEB_CONCURRENCY")
if web_concurrency:
    workers = int(web_concurrency)
else:
    cores = multiprocessing.cpu_count()
    workers_per_core = 2
    min_workers = 2
    max_workers = 4
    workers = max(min_workers, min(cores * workers_per_core, max_workers))

# worker processes
worker_class = "uvicorn.workers.UvicornWorker"  # default: "sync"
threads = 4  # default: 1, only for gthread worker_class
worker_connections = 1000  # default: 1000, only eventlet and gevent worker_class
max_requests = 100  # default: 0
max_requests_jitter = 10  # default: 0
timeout = 30  # default: 30
graceful_timeout = 30  # default: 30
keepalive = 2  # default: 2
