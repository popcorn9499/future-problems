package com.gobison.backend.features.rides.application.geocoding;

import com.gobison.backend.features.rides.domain.model.GeoLocation;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

@Service
public class NominatimGeocoder implements Geocoder {
    private static final Pattern HOUSE_NUMBER = Pattern.compile("^([0-9]+[a-zA-Z]?)\\s+.+$");
    private static final long TTL = Duration.ofHours(24).toMillis();
    private final HttpClient client;
    private final ObjectMapper mapper = new ObjectMapper();
    private final String url;
    private final String userAgent;
    private final Clock clock;
    private final Semaphore outbound = new Semaphore(1, true);
    private long lastStart;
    private final Map<String, Entry> cache = new LinkedHashMap<>(16, .75f, true);
    private final Map<String, CompletableFuture<GeoLocation>> pending = new HashMap<>();

    @org.springframework.beans.factory.annotation.Autowired
    public NominatimGeocoder(
            @Value("${gobison.geocoding.url:https://nominatim.openstreetmap.org/search}") String url,
            @Value("${gobison.geocoding.user-agent:GoBison-Demo/1.0}") String userAgent) {
        this(url, userAgent, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build(), Clock.systemUTC());
    }

    NominatimGeocoder(String url, String userAgent, HttpClient client, Clock clock) {
        this.url = url;
        this.userAgent = userAgent;
        this.client = client;
        this.clock = clock;
    }

    @Override
    public GeoLocation locate(String street, String city) {
        String key = normalize(street) + "|" + normalize(city) + "|ca";
        CompletableFuture<GeoLocation> future;
        boolean owner;
        synchronized (cache) {
            Entry cached = cache.get(key);
            if (cached != null && cached.expiresAt > clock.millis()) return cached.result();
            cache.remove(key);
            future = pending.get(key);
            owner = future == null;
            if (owner) {
                if (pending.size() >= 1000) throw new GeocodingException(false);
                future = new CompletableFuture<>();
                pending.put(key, future);
            }
        }
        if (!owner) {
            try {
                return future.get(11, TimeUnit.SECONDS);
            } catch (ExecutionException e) {
                if (e.getCause() instanceof GeocodingException failure) throw failure;
                throw new GeocodingException(false);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new GeocodingException(false);
            } catch (Exception e) {
                throw new GeocodingException(false);
            }
        }
        try {
            GeoLocation location;
            try {
                location = fetch(street, city);
            } catch (GeocodingException e) {
                if (!e.isInvalidAddress()) throw e;
                location = null;
            }
            synchronized (cache) {
                cache.put(key, new Entry(location, clock.millis() + TTL));
                while (cache.size() > 1000) cache.remove(cache.keySet().iterator().next());
            }
            if (location == null) throw new GeocodingException(true);
            future.complete(location);
            return location;
        } catch (RuntimeException e) {
            future.completeExceptionally(e);
            throw e;
        } finally {
            synchronized (cache) { pending.remove(key); }
        }
    }

    private GeoLocation fetch(String street, String city) {
        var house = HOUSE_NUMBER.matcher(street.trim());
        if (!house.matches()) throw new GeocodingException(true);
        boolean acquired = false;
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        try {
            acquired = outbound.tryAcquire(5, TimeUnit.SECONDS);
            if (!acquired) throw new GeocodingException(false);
            long delay = lastStart == 0 ? 0 : TimeUnit.SECONDS.toNanos(1) - (System.nanoTime() - lastStart);
            if (delay > 0) {
                if (System.nanoTime() + delay > deadline) throw new GeocodingException(false);
                TimeUnit.NANOSECONDS.sleep(delay);
            }
            var uri = URI.create(url + "?street=" + encode(street.trim()) + "&city=" + encode(city.trim())
                    + "&countrycodes=ca&format=jsonv2&addressdetails=1&limit=2");
            var request = HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(5))
                    .header("User-Agent", userAgent).header("Accept", "application/json").GET().build();
            lastStart = System.nanoTime();
            var response = client.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) throw new GeocodingException(false);
            return parse(response.body(), house.group(1));
        } catch (GeocodingException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new GeocodingException(false);
        } catch (Exception e) {
            throw new GeocodingException(false);
        } finally {
            if (acquired) outbound.release();
        }
    }

    GeoLocation parse(String body, String houseNumber) {
        try {
            JsonNode results = mapper.readTree(body);
            if (!results.isArray()) throw new GeocodingException(false);
            if (results.size() != 1) throw new GeocodingException(true);
            var result = results.get(0);
            var address = result.path("address");
            int rank = result.path("place_rank").asInt();
            String returnedHouseNumber = address.path("house_number").asText();
            boolean exactAddress = rank == 30
                    && normalize(houseNumber).equals(normalize(returnedHouseNumber));
            boolean streetMatch = rank == 26 && returnedHouseNumber.isBlank();
            if (!"ca".equals(address.path("country_code").asText())
                    || address.path("road").asText().isBlank()
                    || !(exactAddress || streetMatch)) {
                throw new GeocodingException(true);
            }
            return new GeoLocation(Double.parseDouble(result.path("lon").asText()),
                    Double.parseDouble(result.path("lat").asText()));
        } catch (GeocodingException e) {
            throw e;
        } catch (Exception e) {
            throw new GeocodingException(false);
        }
    }

    private static String normalize(String value) {
        return value.trim().replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
    }

    private static String encode(String value) { return URLEncoder.encode(value, StandardCharsets.UTF_8); }

    private record Entry(GeoLocation location, long expiresAt) {
        GeoLocation result() {
            if (location == null) throw new GeocodingException(true);
            return location;
        }
    }
}
