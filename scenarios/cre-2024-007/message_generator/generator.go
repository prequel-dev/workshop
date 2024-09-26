package main

import (
    "fmt"
    "log"

    "github.com/rabbitmq/amqp091-go"
)

func main() {
    // Connect to RabbitMQ server
    conn, err := amqp091.Dial("amqp://test:test@localhost:5672/")
    if err != nil {
        log.Fatalf("Failed to connect to RabbitMQ: %s", err)
    }
    defer conn.Close()

    // Create a channel
    ch, err := conn.Channel()
    if err != nil {
        log.Fatalf("Failed to open a channel: %s", err)
    }
    defer ch.Close()

    // Loop to create 1,000 queues and send messages
    for i := 1; i <= 1000; i++ {
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
            log.Fatalf("Failed to declare queue %s: %s", queueName, err)
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
                log.Fatalf("Failed to publish a message to %s: %s", queueName, err)
            }
        }

        fmt.Printf("Sent 100 messages to %s\n", queueName)
    }

    fmt.Println("Successfully sent messages to all queues.")
}
