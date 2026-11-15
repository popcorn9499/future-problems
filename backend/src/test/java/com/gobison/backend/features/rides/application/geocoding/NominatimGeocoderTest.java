package com.gobison.backend.features.rides.application.geocoding;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Clock;


import java.util.ArrayList;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class NominatimGeocoderTest {
    private final HttpClient client = mock(HttpClient.class);
    @SuppressWarnings("unchecked")
    private final HttpResponse<String> response = mock(HttpResponse.class);
    private final Clock clock = mock(Clock.class);
    private NominatimGeocoder geocoder;
    private static final String MATCH = """
            [{"place_rank":30,"lat":"49.895","lon":"-97.138",
            "address":{"country_code":"ca","house_number":"123","road":"Main Street"}}]
            """;

    @BeforeEach
    void setup() throws Exception {
        when(clock.millis()).thenReturn(0L);
        when(response.statusCode()).thenReturn(200);
        when(response.body()).thenReturn(MATCH);
        when(client.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(response);
        geocoder = new NominatimGeocoder("https://example.test/search", "GoBison-Test/1.0", client, clock);
    }

    @Test
    void filtersCanadaAndPreservesCoordinateOrderAndCachesNormalizedAddresses() throws Exception {
        var point = geocoder.locate("123 Main Street", "Winnipeg");
        assertEquals(-97.138, point.longitude());
        assertEquals(49.895, point.latitude());
        assertEquals(point, geocoder.locate(" 123  MAIN STREET ", " WINNIPEG "));
        var request = org.mockito.ArgumentCaptor.forClass(HttpRequest.class);
        verify(client).send(request.capture(), any());
        assertTrue(request.getValue().uri().getQuery().contains("countrycodes=ca"));
        assertTrue(request.getValue().uri().getQuery().contains("limit=2"));
        assertEquals("GoBison-Test/1.0", request.getValue().headers().firstValue("User-Agent").orElseThrow());
        assertEquals(5, request.getValue().timeout().orElseThrow().toSeconds());
    }

    @Test
    void rejectsUncertainOrNonCanadianMatches() {
        for (String body : new String[] {"[]", "[{},{}]", MATCH.replace("30", "26"),
                MATCH.replace("\"ca\"", "\"us\""), MATCH.replace("\"123\"", "\"124\""),
                MATCH.replace("Main Street", "")}) {
            assertTrue(assertThrows(GeocodingException.class, () -> geocoder.parse(body, "123")).isInvalidAddress());
        }
    }

    @Test
    void malformedProviderDataIsTemporaryFailure() {
        for (String body : new String[] {"invalid", "{}", MATCH.replace("49.895", "NaN"),
                MATCH.replace("-97.138", "181")}) {
            assertFalse(assertThrows(GeocodingException.class, () -> geocoder.parse(body, "123")).isInvalidAddress());
        }
    }

    @Test
    void cachesRejectionsAndExpiresEntries() throws Exception {
        when(response.body()).thenReturn("[]");
        assertThrows(GeocodingException.class, () -> geocoder.locate("123 Main", "Winnipeg"));
        assertThrows(GeocodingException.class, () -> geocoder.locate("123 Main", "Winnipeg"));
        verify(client, times(1)).send(any(), any());
        when(clock.millis()).thenReturn(TimeUnit.HOURS.toMillis(24));
        when(response.body()).thenReturn(MATCH);
        assertNotNull(geocoder.locate("123 Main", "Winnipeg"));
        verify(client, times(2)).send(any(), any());
    }

    @Test
    void providerFailuresAreNotCachedAndOutboundCallsAreSpaced() throws Exception {
        var starts = new ArrayList<Long>();
        when(client.<String>send(any(), any())).thenAnswer(call -> {
            starts.add(System.nanoTime());
            return response;
        });
        when(response.statusCode()).thenReturn(429, 200);
        assertFalse(assertThrows(GeocodingException.class,
                () -> geocoder.locate("123 Main", "Winnipeg")).isInvalidAddress());
        assertNotNull(geocoder.locate("123 Main", "Winnipeg"));
        assertTrue(starts.get(1) - starts.get(0) >= TimeUnit.MILLISECONDS.toNanos(990));
    }

    @Test
    void combinesConcurrentIdenticalLookups() throws Exception {
        var started = new CountDownLatch(1);
        var release = new CountDownLatch(1);
        when(client.<String>send(any(), any())).thenAnswer(call -> {
            started.countDown();
            assertTrue(release.await(3, TimeUnit.SECONDS));
            return response;
        });
        var first = CompletableFuture.supplyAsync(() -> geocoder.locate("123 Main", "Winnipeg"));
        assertTrue(started.await(2, TimeUnit.SECONDS));
        var second = CompletableFuture.supplyAsync(() -> geocoder.locate("123 Main", "Winnipeg"));
        release.countDown();
        assertEquals(first.get(3, TimeUnit.SECONDS), second.get(3, TimeUnit.SECONDS));
        verify(client, times(1)).send(any(), any());
    }

    @Test
    void timeoutIsTemporaryAndDoesNotPoisonCache() throws Exception {
        when(client.<String>send(any(), any())).thenThrow(new java.net.http.HttpTimeoutException("timeout"))
                .thenReturn(response);
        assertFalse(assertThrows(GeocodingException.class,
                () -> geocoder.locate("123 Main", "Winnipeg")).isInvalidAddress());
        assertNotNull(geocoder.locate("123 Main", "Winnipeg"));
    }
}
