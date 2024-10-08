package main

import (
    "fmt"
    "log"
    "sync"

    "github.com/rabbitmq/amqp091-go"
)

func main() {
    // Connect to RabbitMQ server
    conn, err := amqp091.Dial("amqp://guest:guest@localhost:5672/")
    if err != nil {
        log.Fatalf("Failed to connect to RabbitMQ: %s", err)
    }
    defer conn.Close()

    // Number of Goroutines to use
    numGoroutines := 8
    totalQueues := 1000
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
                queueName := fmt.Sprintf("queue-%d", i)

                // Declare a durable quorum queue
                _, err := ch.QueueDeclare(
                    queueName, // name
                    true,      // durable
                    false,     // delete when unused
                    false,     // exclusive
                    false,     // no-wait
                    amqp091.Table{
                        "x-queue-type": "quorum", // Set queue type to 'quorum'
                    },
                )
                if err != nil {
                    log.Printf("Goroutine %d: Failed to declare queue %s: %s", g, queueName, err)
                    continue
                }

                // Send 100 messages to the queue
                for j := 1; j <= 100; j++ {
                    body := fmt.Sprintf("Message %d for %s", j, queueName)
                    err = ch.Publish(
                        "",        // exchange
                        queueName, // routing key (queue name)
                        false,     // mandatory
                        false,     // immediate
                        amqp091.Publishing{
                            ContentType: "text/plain",
                            Body:        []byte(body),
                        })
                    if err != nil {
                        log.Printf("Goroutine %d: Failed to publish a message to %s: %s", g, queueName, err)
                        continue
                    }
                }

                fmt.Printf("Goroutine %d: Sent 100 messages to %s\n", g, queueName)
            }
        }(g)
    }

    wg.Wait()
    fmt.Println("Successfully sent messages to all queues.")
}

