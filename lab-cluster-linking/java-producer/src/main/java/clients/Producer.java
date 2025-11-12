package clients;

import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Properties;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

public class Producer {
  static final String COURIER_FILE_PREFIX = "./couriers/";
  static final String KAFKA_TOPIC = "courier-positions";

  /**
   * Java producer.
   */
  public static void main(String[] args) throws IOException, InterruptedException {
    System.out.println("Starting Java producer.");

    // Load a courier id from an environment variable
    // if it isn't present use "courier-1"
    String courierId  = System.getenv("COURIER_ID");
    courierId = (courierId != null) ? courierId : "courier-1";

    // Configure the location of the bootstrap server, default serializers,
    // Confluent interceptors
    final Properties settings = loadConfig(args[0]);
    settings.put(ProducerConfig.CLIENT_ID_CONFIG, courierId);
    settings.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    settings.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);

    final KafkaProducer<String, String> producer = new KafkaProducer<>(settings);
    
    // Adding a shutdown hook to clean up when the application exits
    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      System.out.println("Closing producer.");
      producer.close();
    }));

    // Read the offset position, defaulting to 0 if file doesn't exist or is empty
    int pos = 0;
    try {
      String offsetContent = Files.readString(Paths.get("commits/commit-offset.csv")).trim();
      if (!offsetContent.isEmpty()) {
        pos = Integer.parseInt(offsetContent);
      }
    } catch (IOException | NumberFormatException e) {
      System.out.println("Warning: Could not read commit-offset.csv, starting from position 0");
      // Ensure the commits directory exists
      Files.createDirectories(Paths.get("commits"));
      // Initialize the file with 0
      Files.writeString(Paths.get("commits/commit-offset.csv"), "0");
    }
    
    final String[] rows = Files.readAllLines(Paths.get(COURIER_FILE_PREFIX + courierId + ".csv"),
      Charset.forName("UTF-8")).toArray(new String[0]);

    // Loop over the courier CSV file..
    while (true) {
      final String key = courierId;
      final String value = rows[pos];
      final ProducerRecord<String, String> record = new ProducerRecord<>(KAFKA_TOPIC, key, value);
      producer.send(record, (md, e) -> {
        if (e != null)
          e.printStackTrace();
        else
          System.out.printf("Produced Key:%s Value:%s  --  Partition:%s Offset:%s\n", key, value, md.partition(), md.offset());
          try (BufferedWriter writer = new BufferedWriter(new FileWriter("commits/commit-offset.csv"))) {
            writer.write(String.valueOf(md.offset() + 1));
            writer.close();
          } catch (IOException exception) {
            exception.printStackTrace();
          }
      });
      pos = pos + 1;
      Thread.sleep(1000);
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
