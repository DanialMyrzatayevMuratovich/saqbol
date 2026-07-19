from concurrent import futures

import grpc

from . import metrics
from .classifier import ScamClassifier
from .generated import ml_pb2, ml_pb2_grpc


class ScamClassifierServicer(ml_pb2_grpc.ScamClassifierServicer):
    def __init__(self, classifier: ScamClassifier):
        self.classifier = classifier

    def Classify(self, request, context):
        result = self.classifier.classify(request.text, request.channel, request.locale)
        metrics.observe(result, request.channel)
        return _to_response(result)

    def ClassifyStream(self, request_iterator, context):
        transcript = []
        for request in request_iterator:
            if request.text:
                transcript.append(request.text)
            window = " ".join(transcript)[-1200:]
            result = self.classifier.classify(window, request.channel, request.locale)
            metrics.observe(result, request.channel)
            yield _to_response(result)


def _to_response(result):
    return ml_pb2.ClassifyResponse(
        verdict=result.verdict,
        probability=result.probability,
        category=result.category,
        triggers=result.triggers,
        advice=result.advice,
        latency_ms=result.latency_ms,
        model_version=result.model_version,
    )


def create_server(classifier: ScamClassifier, port: int) -> grpc.Server:
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    ml_pb2_grpc.add_ScamClassifierServicer_to_server(
        ScamClassifierServicer(classifier), server
    )
    server.add_insecure_port(f"[::]:{port}")
    return server
