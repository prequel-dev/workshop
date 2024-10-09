package main

import (
	"fmt"
	"log"
	"sync"

	"github.com/prequel-dev/prequel-core/pkg/envz"

	"github.com/rabbitmq/amqp091-go"
)

var (
	address       = envz.MustEnv("RMQ_ADDRESS", "localhost:5672")
	totalQueues   = envz.MustEnv("RMQ_QUEUES", 2000)
	numGoroutines = envz.MustEnv("GOROUTINES", 16)
	jobNumber     = envz.MustEnv("JOB_NUMBER", 0)
	totalJobs     = envz.MustEnv("JOB_TOTAL", 10)
)

func main() {
	// Connect to RabbitMQ server
	conn, err := amqp091.Dial(fmt.Sprintf("amqp://guest:guest@%s/", address))
	if err != nil {
		log.Fatalf("Failed to connect to RabbitMQ: %s", err)
	}
	defer conn.Close()

	queuesPerJob := totalQueues / totalJobs
	startQueue := jobNumber*queuesPerJob + 1
	endQueue := (jobNumber + 1) * queuesPerJob

	// Handle any remaining queues in the last job
	if jobNumber == totalJobs-1 {
		endQueue = totalQueues
	}

	queuesToProcess := endQueue - startQueue + 1
	queuesPerGoroutine := queuesToProcess / numGoroutines

	var wg sync.WaitGroup

	for g := 0; g < numGoroutines; g++ {
		wg.Add(1)
		go func(g int) {
			defer wg.Done()

			// Create a channel for this Goroutine
			ch, err := conn.Channel()
			if err != nil {
				log.Fatalf("Goroutine %d: Failed to open a channel: %s", g, err)
			}
			defer ch.Close()

			// Calculate the range of queues for this Goroutine
			goroutineStartQueue := startQueue + g*queuesPerGoroutine
			goroutineEndQueue := goroutineStartQueue + queuesPerGoroutine - 1

			// Handle any remaining queues in the last Goroutine
			if g == numGoroutines-1 {
				goroutineEndQueue = endQueue
			}

			fmt.Printf("Generating %d queues (%d through %d)\n", queuesPerGoroutine, goroutineStartQueue, goroutineEndQueue)

			// Handle any remaining queues in the last Goroutine
			if g == numGoroutines-1 {
				endQueue = totalQueues
			}

			for i := goroutineStartQueue; i <= goroutineEndQueue; i++ {
				queueName := fmt.Sprintf("pq%d", i)

				// Declare a durable priority queue
				_, err := ch.QueueDeclare(
					queueName, // name
					true,      // durable
					false,     // delete when unused
					false,     // exclusive
					false,     // no-wait
					amqp091.Table{
						"x-max-priority": byte(10), // Enable priority queue with max priority 10
					},
				)
				if err != nil {
					log.Printf("Goroutine %d: Failed to declare queue %s: %s", g, queueName, err)
					continue
				}

				totalMessages := 1

				// Send 100 messages with varying priorities to the queue
				for j := 1; j <= totalMessages; j++ {
					body := fmt.Sprintf("Message %d for %s", j, queueName)
					priority := byte(j % 10) // Assign a priority between 0 and 9

					err = ch.Publish(
						"",        // exchange
						queueName, // routing key (queue name)
						false,     // mandatory
						false,     // immediate
						amqp091.Publishing{
							ContentType: "text/plain",
							Body:        []byte(body),
							Priority:    priority,
						})
					if err != nil {
						log.Printf("Goroutine %d: Failed to publish a message to %s: %s", g, queueName, err)
						continue
					}
				}

				fmt.Printf("Goroutine %d: Sent %d message to %s\n", g, totalMessages, queueName)
			}
		}(g)
	}

	wg.Wait()
	fmt.Println("Successfully sent messages to all queues.")
}
