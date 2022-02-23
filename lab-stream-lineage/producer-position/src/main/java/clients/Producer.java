package clients;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Properties;
import java.util.concurrent.ThreadLocalRandom;

public class Producer {
  static final String DATA_FILE_PREFIX = "./data/";
  static final String KAFKA_TOPIC  = (System.getenv("TOPIC") != null) ?
          System.getenv("TOPIC") : "user-position";
  static final String CLIENT_ID  = (System.getenv("CLIENT_ID") != null) ?
          System.getenv("CLIENT_ID") : "app-position-producer";
  static final String API_KEY  = System.getenv("API_KEY");
  static final String API_SECRET  = System.getenv("API_SECRET");
  static final String BOOTSTRAP_SERVERS  = System.getenv("BOOTSTRAP_SERVERS");

  /**
   * Java producer.
   */
  public static void main(String[] args) throws IOException, InterruptedException {
//    System.out.println("Starting Java producer.");

    checkEnvironmentVariables();

    // Configure the location of the bootstrap server, default serializers, security
    final Properties settings = new Properties();
    settings.put(ProducerConfig.CLIENT_ID_CONFIG, CLIENT_ID);
    settings.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
    settings.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    settings.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    settings.put("ssl.endpoint.identification.algorithm", "https");
    settings.put("security.protocol", "SASL_SSL");
    settings.put("sasl.jaas.config", "org.apache.kafka.common.security.plain.PlainLoginModule   required username='" + API_KEY + "'   password='" + API_SECRET + "';");
    settings.put("sasl.mechanism", "PLAIN");


    final KafkaProducer<String, String> producer = new KafkaProducer<>(settings);

    // Adding a shutdown hook to clean up when the application exits
    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      System.out.println("Closing producer.");
      producer.close();
    }));

    int pos = 0;
    // Format of inputData.csv (100 records) --> FirstName,LastName,Email,RegistrationDate,Country
    final String[] rows = Files.readAllLines(Paths.get(DATA_FILE_PREFIX + "inputData.csv"),
            StandardCharsets.UTF_8).toArray(new String[0]);

    // Loop forever over the driver CSV file..
    String numRecordsString  = System.getenv("NUMBER_RECORDS");
    numRecordsString = (numRecordsString != null) ? numRecordsString : "1000000";
    int numRecords = Integer.parseInt(numRecordsString);

    for (int i = 0; i < numRecords; i++) {
      int randomUser = ThreadLocalRandom.current().nextInt(1, 21);
      final String key = "user" + randomUser;
      final String value = rows[pos];

      final ProducerRecord<String, String> record = new ProducerRecord<>(KAFKA_TOPIC, key, value);
      producer.send(record);
      Thread.sleep(500);
      pos = (pos + 1) % rows.length;
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
