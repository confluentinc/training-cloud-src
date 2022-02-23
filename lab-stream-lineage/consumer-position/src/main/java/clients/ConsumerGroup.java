package clients;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class ConsumerGroup {
    static final String NUM_CONSUMERS  = (System.getenv("NUM_CONSUMERS") != null) ?
            System.getenv("NUM_CONSUMERS") : "4";
    static final String KAFKA_TOPIC  = (System.getenv("TOPIC") != null) ?
            System.getenv("TOPIC") : "user-position";
    static final String AUTO_OFFSET_RESET  = (System.getenv("AUTO_OFFSET_RESET") != null) ?
            System.getenv("AUTO_OFFSET_RESET") : "earliest";
    static final String APP_ID  = (System.getenv("APP_ID") != null) ?
            System.getenv("APP_ID") : "gps-app";
    static final String API_KEY  = System.getenv("API_KEY");
    static final String API_SECRET  = System.getenv("API_SECRET");
    static final String BOOTSTRAP_SERVERS  = System.getenv("BOOTSTRAP_SERVERS");

    public static void main(String[] args) throws IOException {
        checkEnvironmentVariables();

        int numConsumers = Integer.parseInt(NUM_CONSUMERS);
        ExecutorService executor = Executors.newFixedThreadPool(numConsumers);

        List<String> topics = Arrays.asList(KAFKA_TOPIC);

        final List<ConsumerLoop> consumers = new ArrayList<>();
        for (int i = 0; i < numConsumers; i++) {
            ConsumerLoop consumer = new ConsumerLoop(i, topics);
            consumers.add(consumer);
            executor.submit(consumer);
        }

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            for (ConsumerLoop consumer : consumers) {
                consumer.shutdown();
            }
            executor.shutdown();
            try {
                executor.awaitTermination(5000, TimeUnit.MILLISECONDS);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }));
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
