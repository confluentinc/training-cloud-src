package clients;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Properties;

public class Producer {
  static final String DATA_FILE_PREFIX = "./data/";
  static final String PROPERTIES_FILE = (System.getenv("PROPERTIES_FILE") != null) ? System.getenv("PROPERTIES_FILE") : "./java-producer.properties";
  static final String KAFKA_TOPIC = (System.getenv("TOPIC") != null) ? System.getenv("TOPIC") : "user-data";
  static final int NUM_RECORDS = Integer.parseInt((System.getenv("NUM_RECORDS") != null) ? System.getenv("NUM_RECORDS") : "1000000");

  /**
   * Java producer.
   */
  public static void main(String[] args) throws IOException, InterruptedException {
    System.out.println("Starting Java producer.");

    // Creating the Kafka producer
    final Properties settings = loadPropertiesFile();
    settings.put(ProducerConfig.CLIENT_ID_CONFIG, "training-java-producer");
    settings.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    settings.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);

    final KafkaProducer<String, String> producer = new KafkaProducer<>(settings);

    // Adding a shutdown hook to clean up when the application exits
    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      System.out.println("Closing producers.");
      producer.close();
    }));

    int pos = 0;
    // Format of users-data.csv (1000 records) --> Id|FirstName|LastName|Email|Birthday|RegistrationTimestamp|ActiveAccount
    final String[] rows = Files.readAllLines(Paths.get(DATA_FILE_PREFIX + "user-data.csv"),
            StandardCharsets.UTF_8).toArray(new String[0]);

    for (int i = 0; i < NUM_RECORDS; i++) {
      final String value = rows[pos];
      final String[] values = value.split("\\|");
      final String key = values[0];

      final ProducerRecord<String, String> record = new ProducerRecord<>(KAFKA_TOPIC, key, value);
      producer.send(record);
      System.out.println("Message sent: " + value);
      Thread.sleep(1000);
      pos = (pos + 1) % rows.length;
    }
  }

  public static Properties loadPropertiesFile() throws IOException {
    if (!Files.exists(Paths.get(PROPERTIES_FILE))) {
      throw new IOException(PROPERTIES_FILE + " not found.");
    }
    final Properties properties = new Properties();
    try (InputStream inputStream = new FileInputStream(PROPERTIES_FILE)) {
      properties.load(inputStream);
    }
    return properties;
  }
}