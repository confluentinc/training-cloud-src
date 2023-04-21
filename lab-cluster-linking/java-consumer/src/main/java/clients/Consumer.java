package clients;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;

public class Consumer {
  static final String KAFKA_TOPIC = "courier-positions";

  /**
   * Java consumer.
   * @throws IOException
   * @throws InterruptedException
   */
  public static void main(String[] args) throws IOException, InterruptedException {
    System.out.println("Starting Java Consumer.");

    // Configure the group id, location of the bootstrap server, default deserializers,
    // Confluent interceptors
    final Properties settings = loadConfig(args[0]);
    settings.put(ConsumerConfig.GROUP_ID_CONFIG, "courier-consumer");
    settings.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
    settings.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    settings.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    settings.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");


    final KafkaConsumer<String, String> consumer = new KafkaConsumer<>(settings);

    try {
      // Subscribe to our topic
      consumer.subscribe(Arrays.asList(KAFKA_TOPIC));
      while (true) {
        final ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
        for (ConsumerRecord<String, String> record : records) {
          System.out.printf("Consumed Key:%s Value:%s  --  Partition:%s Offset:%s\n",
              record.key(), record.value(), record.partition(), record.offset());   
        }
        Thread.sleep(500);  // Not needed in real applications. Just for Lab 5 of the course.
        consumer.commitSync();
      }
    } finally {
      // Clean up when the application exits or errors
      System.out.println("Closing consumer.");
      consumer.close();
    }
  }

  public static Properties loadConfig(final String configFile) throws IOException {
    if (!Files.exists(Paths.get(configFile))) {
      throw new IOException(configFile + " not found.");
    }
    final Properties cfg = new Properties();
    try (InputStream inputStream = new FileInputStream(configFile)) {
      cfg.load(inputStream);
    }
    return cfg;
  }
}
