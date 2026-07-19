import logging

import uvicorn

from .api import app, classifier, settings
from .grpc_server import create_server

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("saqbol-ml")


def main() -> None:
    grpc_server = create_server(classifier, settings.grpc_port)
    grpc_server.start()
    logger.info("grpc server listening on %d", settings.grpc_port)
    logger.info("http server listening on %d", settings.http_port)

    try:
        uvicorn.run(app, host="0.0.0.0", port=settings.http_port, log_level="info")
    finally:
        grpc_server.stop(grace=5)


if __name__ == "__main__":
    main()
