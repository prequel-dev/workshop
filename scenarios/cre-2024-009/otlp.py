#!/usr/bin/env python3

from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import time
import random
import string
from multiprocessing import Process, current_process

# Function to initialize the tracer for each process
def init_tracer():
    # Set up the tracer provider
    trace.set_tracer_provider(TracerProvider())

    # Configure the Jaeger exporter to send data to the Otel Collector
    jaeger_exporter = JaegerExporter(
        # Point to the Otel Collector's Jaeger HTTP endpoint
        collector_endpoint='http://localhost:14268/api/traces',
        # Optional authentication if required
        # username='your_username',
        # password='your_password',
    )

    # Create a BatchSpanProcessor and add the exporter to it
    span_processor = BatchSpanProcessor(jaeger_exporter)
    trace.get_tracer_provider().add_span_processor(span_processor)

    # Get a tracer
    tracer = trace.get_tracer(__name__)
    return tracer

def generate_large_string(size):
    """Generate a random string of the specified size."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=size))

def generate_traces(num_traces):
    # Initialize tracer in each process
    tracer = init_tracer()
    process_name = current_process().name

    for i in range(num_traces):
        with tracer.start_as_current_span(f"{process_name}_operation_{i}") as span:
            span.set_attribute("iteration", i)
            # Add lots of large tag strings to the span
            for j in range(10000):  # Number of attributes to add (adjust as needed)
                large_string = generate_large_string(1024*10)  # Size of each attribute value in bytes
                span.set_attribute(f"large_attribute_{j}", large_string)
            # Simulate nested spans (child spans)
            with tracer.start_as_current_span(f"{process_name}_child_operation_{i}") as child_span:
                child_span.set_attribute("child_attribute", "value")
            # Simulate some work

if __name__ == "__main__":
    num_processes = 8  # Adjust the number of processes as needed
    traces_per_process = 10000  # Adjust the number of traces per process

    processes = []
    for _ in range(num_processes):
        p = Process(target=generate_traces, args=(traces_per_process,))
        processes.append(p)
        p.start()

    for p in processes:
        p.join()

