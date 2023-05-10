import atexit
import logging
import sys
from logging.handlers import QueueHandler, QueueListener, RotatingFileHandler
from queue import Queue
from typing import Any, Dict, List

from pythonjsonlogger.jsonlogger import JsonFormatter

# init root logger with null handler
logging.basicConfig(handlers=[logging.NullHandler()])

# init log queue for handler and listener
log_queue: Queue = Queue()
log_qlistener: QueueListener = QueueListener(log_queue, respect_handler_level=True)
log_qlistener.start()
atexit.register(log_qlistener.stop)


class StackdriverFormatter(JsonFormatter):
    def process_log_record(self, log_record: Dict[str, Any]) -> Dict[str, Any]:
        log_record["severity"] = log_record["levelname"]
        return super().process_log_record(log_record)  # type: ignore


def _get_log_formatter() -> StackdriverFormatter:
    # formatter
    log_format = " - ".join(
        [
            "%(asctime)s",
            "%(levelname)s",
            "%(name)s",
            "%(processName)s",
            "%(threadName)s",
            "%(filename)s",
            "%(module)s",
            "%(lineno)d",
            "%(funcName)s",
            "%(message)s",
        ]
    )
    date_format = "%Y-%m-%dT%H:%M:%S"
    log_formatter = StackdriverFormatter(
        fmt=log_format, datefmt=date_format, timestamp=True
    )  # type: ignore
    return log_formatter


def _get_file_handler(
    log_path: str = "main.log", log_level: int = logging.DEBUG
) -> RotatingFileHandler:
    file_handler = RotatingFileHandler(
        log_path,
        maxBytes=2**20,  # 1 MB
        backupCount=10,  # 10 backups
        encoding="utf8",
        delay=True,
    )
    file_handler.setLevel(log_level)
    file_handler.setFormatter(_get_log_formatter())
    return file_handler


def _get_stdout_handler(log_level: int = logging.INFO) -> logging.StreamHandler:
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(log_level)
    stdout_handler.setFormatter(_get_log_formatter())
    return stdout_handler


def configure_log_listener(
    console: bool = True, log_path: str = "main.log"
) -> QueueListener:
    """
    Configure log queue listener to log into file and console.
    Args:
        console (bool): whether to log on console
        log_path (str): path of log file
    Returns:
        log_qlistener (logging.handlers.QueueListener): configured log queue listener
    """
    global log_qlistener
    try:
        atexit.unregister(log_qlistener.stop)
        log_qlistener.stop()
    except (AttributeError, NameError):
        pass

    handlers: List[logging.Handler] = []

    # rotating file handler
    if log_path:
        file_handler = _get_file_handler(log_path)
        handlers.append(file_handler)

    # console handler
    if console:
        stdout_handler = _get_stdout_handler()
        handlers.append(stdout_handler)

    log_qlistener = QueueListener(log_queue, *handlers, respect_handler_level=True)
    log_qlistener.start()
    atexit.register(log_qlistener.stop)
    return log_qlistener


def get_logger(name: str, log_level: int = logging.DEBUG) -> logging.Logger:
    """
    Simple logging wrapper that returns logger
    configured to log into file and console.
    Args:
        name: name of logger
        log_level: log level
    Returns:
        logger: configured logger
    """
    logger = logging.getLogger(name)
    for log_handler in logger.handlers[:]:
        logger.removeHandler(log_handler)

    logger.setLevel(log_level)
    logger.addHandler(QueueHandler(log_queue))

    return logger
