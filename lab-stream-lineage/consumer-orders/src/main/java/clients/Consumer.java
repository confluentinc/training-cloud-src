package clients;

import java.io.*;
import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;

public class Consumer {

  static final String KAFKA_TOPIC  = (System.getenv("TOPIC") != null) ?
          System.getenv("TOPIC") : "filtered-orders";
  static final String CLIENT_ID  = (System.getenv("CLIENT_ID") != null) ?
          System.getenv("CLIENT_ID") : "orders-app-consumer";
  static final String API_KEY  = System.getenv("API_KEY");
  static final String API_SECRET  = System.getenv("API_SECRET");
  static final String BOOTSTRAP_SERVERS  = System.getenv("BOOTSTRAP_SERVERS");

  /**
   * Java consumer.
   */
  public static void main(String[] args) throws IOException {
    // Creating the Kafka Consumer
    checkEnvironmentVariables();

    final Properties settings = new Properties();
    settings.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
    settings.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    settings.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    settings.put(ConsumerConfig.GROUP_ID_CONFIG, "orders-consumer-group");
    settings.put(ConsumerConfig.CLIENT_ID_CONFIG, CLIENT_ID);
    settings.put("ssl.endpoint.identification.algorithm", "https");
    settings.put("security.protocol", "SASL_SSL");
    settings.put("sasl.jaas.config", "org.apache.kafka.common.security.plain.PlainLoginModule   required username='" + API_KEY + "'   password='" + API_SECRET + "';");
    settings.put("sasl.mechanism", "PLAIN");

    final KafkaConsumer<String, String> consumer = new KafkaConsumer<>(settings);

    //
    try {
      // Subscribe to our topic
      consumer.subscribe(Arrays.asList(KAFKA_TOPIC));
      while (true) {
        final ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
        for (ConsumerRecord<String, String> record : records) {
          // Do nothing
        }
      }
    } finally {
      // Clean up when the application exits or errors
      System.out.println("Closing consumer.");
      consumer.close();
    }
  }

  private static void checkEnvironmentVariables() {
    if(BOOTSTRAP_SERVERS == null) {
      System.out.println("Bootstrap Servers is not set");
      System.exit(0);
    }
    if(API_KEY == null) {
      System.out.println("API key is not set");
      System.exit(0);
    }
    if(API_SECRET == null) {
      System.out.println("API secret is not set");
      System.exit(0);
    }
  }
}
