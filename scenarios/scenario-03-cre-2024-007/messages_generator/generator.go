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
	totalQueues   = envz.MustEnv("RMQ_QUEUES", 4000)
	numGoroutines = envz.MustEnv("GOROUTINES", 32)
)

func main() {
	// Connect to RabbitMQ server
	conn, err := amqp091.Dial(fmt.Sprintf("amqp://guest:guest@%s/", address))
	if err != nil {
		log.Fatalf("Failed to connect to RabbitMQ: %s", err)
	}
	defer conn.Close()

	// Number of Goroutines to use
	queuesPerGoroutine := totalQueues / numGoroutines

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
			startQueue := g*queuesPerGoroutine + 1
			endQueue := (g + 1) * queuesPerGoroutine
			// Handle any remaining queues in the last Goroutine
			if g == numGoroutines-1 {
				endQueue = totalQueues
			}

			for i := startQueue; i <= endQueue; i++ {
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

				// Send 100 messages with varying priorities to the queue
				for j := 1; j <= 1; j++ {
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

				fmt.Printf("Goroutine %d: Sent 1 message to %s\n", g, queueName)
			}
		}(g)
	}

	wg.Wait()
	fmt.Println("Successfully sent messages to all queues.")
}
