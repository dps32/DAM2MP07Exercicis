package com.project;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.*;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Base64;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;

public class OllamaService {
    private static final String OLLAMA_API_URL = "http://localhost:11434/api/generate";
    private static final String TEXT_MODEL = "gemma3:1b";
    private static final String IMAGE_MODEL = "llava-phi3";
    
    private final HttpClient httpClient;
    private final ExecutorService executorService;
    private final AtomicBoolean isCancelled;
    private CompletableFuture<HttpResponse<InputStream>> streamRequest;
    private CompletableFuture<HttpResponse<String>> completeRequest;
    private Future<?> streamReadingTask;
    private InputStream currentInputStream;

    public OllamaService() {
        this.httpClient = HttpClient.newHttpClient();
        this.executorService = Executors.newCachedThreadPool();
        this.isCancelled = new AtomicBoolean(false);
    }

    // envia mensaje de texto a ollama con streaming
    public void sendTextMessage(String message, Consumer<String> onChunk, Runnable onComplete, Consumer<String> onError) {
        isCancelled.set(false);
        
        JSONObject requestBody = new JSONObject();
        requestBody.put("model", TEXT_MODEL);
        requestBody.put("prompt", message);
        requestBody.put("stream", true);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(OLLAMA_API_URL))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestBody.toString()))
                .build();

        streamRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofInputStream())
                .thenApply(response -> {
                    currentInputStream = response.body();
                    streamReadingTask = executorService.submit(() -> {
                        try (BufferedReader reader = new BufferedReader(new InputStreamReader(currentInputStream))) {
                            String line;
                            while ((line = reader.readLine()) != null) {
                                if (isCancelled.get()) {
                                    break;
                                }
                                JSONObject jsonResponse = new JSONObject(line);
                                if (jsonResponse.has("response")) {
                                    String chunk = jsonResponse.getString("response");
                                    onChunk.accept(chunk);
                                }
                                if (jsonResponse.optBoolean("done", false)) {
                                    break;
                                }
                            }
                        } catch (Exception e) {
                            if (!isCancelled.get()) {
                                onError.accept("Error: " + e.getMessage());
                            }
                        } finally {
                            try {
                                if (currentInputStream != null) {
                                    currentInputStream.close();
                                }
                            } catch (Exception e) {
                                // ignorar
                            }
                            if (!isCancelled.get()) {
                                onComplete.run();
                            }
                        }
                    });
                    return response;
                })
                .exceptionally(e -> {
                    if (!isCancelled.get()) {
                        onError.accept("Error: " + e.getMessage());
                    }
                    return null;
                });
    }



    // Envia imagen con prompt (sin imagen)
    public void sendImageMessage(File imageFile, String prompt, Consumer<String> onComplete, Consumer<String> onError) {
        isCancelled.set(false);
        
        try {
            // leer imagen y convertir a base64
            byte[] imageBytes = readFileToBytes(imageFile);
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            JSONObject requestBody = new JSONObject();
            requestBody.put("model", IMAGE_MODEL);
            requestBody.put("prompt", prompt);
            
            JSONArray images = new JSONArray();
            images.put(base64Image);
            requestBody.put("images", images);
            requestBody.put("stream", false);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(OLLAMA_API_URL))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestBody.toString()))
                    .build();

            completeRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenApply(response -> {
                        JSONObject jsonResponse = new JSONObject(response.body());
                        String responseText = jsonResponse.getString("response");
                        if (!isCancelled.get()) {
                            onComplete.accept(responseText);
                        }
                        return response;
                    })
                    .exceptionally(e -> {
                        if (!isCancelled.get()) {
                            onError.accept("Error: " + e.getMessage());
                        }
                        return null;
                    });
        } catch (Exception e) {
            onError.accept("Error: " + e.getMessage());
        }
    }


    // leer archivo y convertir a bytes
    private byte[] readFileToBytes(File file) throws IOException {
        try (FileInputStream fis = new FileInputStream(file);
             ByteArrayOutputStream bos = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                bos.write(buffer, 0, bytesRead);
            }
            return bos.toByteArray();
        }
    }

    // parar la generacion actual
    public void stopGeneration() {
        isCancelled.set(true);
        
        if (streamRequest != null && !streamRequest.isDone()) {
            streamRequest.cancel(true);
        }
        
        if (completeRequest != null && !completeRequest.isDone()) {
            completeRequest.cancel(true);
        }
        
        if (streamReadingTask != null && !streamReadingTask.isDone()) {
            streamReadingTask.cancel(true);
        }
        
        try {
            if (currentInputStream != null) {
                currentInputStream.close();
            }
        } catch (Exception e) {
            // ni caso
        }
    }

    // Comprobar si ollama esta disponible
    public static boolean isOllamaAvailable() {
        try {
            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("http://localhost:11434/api/tags"))
                    .GET()
                    .build();
            
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            return response.statusCode() == 200;
        } catch (Exception e) {
            return false;
        }
    }

    // intentar iniciar ollama si no esta ejecutandose
    public static boolean startOllamaIfNeeded() {
        if (isOllamaAvailable()) {
            return true; // ya se esta ejecutando
        }

        try {
            String os = System.getProperty("os.name").toLowerCase();
            ProcessBuilder pb;

            if (os.contains("win")) {
                // windows
                pb = new ProcessBuilder("cmd", "/c", "start", "/B", "ollama", "serve");
            } else if (os.contains("mac")) {
                // macos
                pb = new ProcessBuilder("bash", "-c", "ollama serve > /dev/null 2>&1 &");
            } else {
                // linux
                pb = new ProcessBuilder("bash", "-c", "nohup ollama serve > /dev/null 2>&1 &");
            }

            pb.start();

            // esperar un poco a que arranque
            for (int i = 0; i < 10; i++) {
                Thread.sleep(1000);
                if (isOllamaAvailable()) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            System.err.println("Error starting Ollama: " + e.getMessage());
            return false;
        }
    }
}
