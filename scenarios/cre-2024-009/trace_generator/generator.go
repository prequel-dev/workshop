package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"strings"
	"sync"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"

	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

func initTracer() func() {
	// Configure the Jaeger exporter to send data to the Otel Collector
	collectorEndpoint := "http://localhost:14268/api/traces"

	exp, err := jaeger.New(
		jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(collectorEndpoint)),
	)
	if err != nil {
		fmt.Printf("Failed to create Jaeger exporter: %v\n", err)
		os.Exit(1)
	}

	// Create a new tracer provider with a batch span processor and the Jaeger exporter
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exp),
		sdktrace.WithResource(resource.NewWithAttributes(
			"service.name", attribute.String("GoJaegerTest", "Go Jaeger Test Service"),
		)),
	)

	// Set the global tracer provider
	otel.SetTracerProvider(tp)

	// Return a function to shutdown the tracer provider
	return func() {
		ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
		defer cancel()
		if err := tp.Shutdown(ctx); err != nil {
			fmt.Printf("Error shutting down tracer provider: %v\n", err)
		}
	}
}

func generateLargeString(size int) string {
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var sb strings.Builder
	sb.Grow(size)
	for i := 0; i < size; i++ {
		sb.WriteByte(letters[rand.Intn(len(letters))])
	}
	return sb.String()
}

func generateTraces(numTraces int, workerID int, wg *sync.WaitGroup) {
	defer wg.Done()

	tracer := otel.Tracer(fmt.Sprintf("worker-%d-tracer", workerID))

	for i := 0; i < numTraces; i++ {
		ctx, span := tracer.Start(context.Background(), fmt.Sprintf("operation_%d", i))
		span.SetAttributes(attribute.Int("iteration", i))

		// Add lots of large tag strings to the span
		for j := 0; j < 1000; j++ { // Number of attributes to add (adjust as needed)
			largeString := generateLargeString(1024*10) // Size of each attribute value in bytes
			span.SetAttributes(attribute.String(fmt.Sprintf("large_attribute_%d", j), largeString))
		}

		// Simulate nested spans (child spans)
		_, childSpan := tracer.Start(ctx, fmt.Sprintf("child_operation_%d", i))
		childSpan.SetAttributes(attribute.String("child_attribute", "value"))
		childSpan.End()

		// End parent span
		span.End()
	}
}

func main() {
	// Seed the random number generator
	rand.Seed(time.Now().UnixNano())

	// Initialize the tracer
	shutdown := initTracer()
	defer shutdown()

	// Number of goroutines (workers) and traces per worker
	numWorkers := 4
	tracesPerWorker := 100 //2500           // Adjust the number of traces per worker
	totalTraces := numWorkers * tracesPerWorker

	fmt.Printf("Generating %d total traces using %d workers...\n", totalTraces, numWorkers)

	var wg sync.WaitGroup

	// Start multiple goroutines to generate traces in parallel
	for workerID := 1; workerID <= numWorkers; workerID++ {
		wg.Add(1)
		go generateTraces(tracesPerWorker, workerID, &wg)
	}

	// Wait for all goroutines to finish
	wg.Wait()

	// Give the exporter some time to flush data
	fmt.Println("All traces generated. Waiting for exporter to flush data...")
	time.Sleep(5 * time.Second)
	fmt.Println("Done.")
}
