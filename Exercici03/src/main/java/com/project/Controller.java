package com.project;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.*;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.*;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.Text;
import javafx.scene.text.TextFlow;
import javafx.stage.FileChooser;

import java.io.File;
import java.io.FileInputStream;
import java.net.URL;
import java.util.ResourceBundle;

public class Controller implements Initializable {

    @FXML private ScrollPane scrollPane;
    @FXML private VBox chatContainer;
    @FXML private TextArea inputArea;
    @FXML private Button btnSend;
    @FXML private Button btnSelectImage;
    @FXML private Button btnStop;
    @FXML private Button btnClear;

    private OllamaService ollamaService;
    private File selectedImage;
    private TextFlow currentResponseFlow;
    private boolean isGenerating = false;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        ollamaService = new OllamaService();
        
        // intentar iniciar ollama si no esta corriendo
        addSystemMessage("Comprobando Ollama...");
        
        // comprobar ollama en background
        new Thread(() -> {
            boolean isAvailable = OllamaService.isOllamaAvailable();
            
            if (!isAvailable) {
                Platform.runLater(() -> addSystemMessage("Ollama no se está ejecutando. Intentando iniciar..."));
                
                boolean started = OllamaService.startOllamaIfNeeded();
                
                if (started) {
                    Platform.runLater(() -> addSystemMessage("Ollama iniciado"));
                } else {
                    Platform.runLater(() -> addSystemMessage("No ha podido iniciar ollama automáticamente"));
                }
            } else {
                Platform.runLater(() -> addSystemMessage("Conectado a Ollama. Listo!"));
            }
        }).start();

        // hacer que el scroll baje automaticamente
        chatContainer.heightProperty().addListener((obs, oldVal, newVal) -> {
            scrollPane.setVvalue(1.0);
        });

        // Enter se envía el mensaje, Shift+Enter para nueva línea
        inputArea.setOnKeyPressed(event -> {
            if (event.getCode().toString().equals("ENTER") && !event.isShiftDown()) {
                event.consume();
                sendMessage();
            }
        });
    }

    @FXML
    private void sendMessage() {
        String message = inputArea.getText().trim();
        
        if (message.isEmpty() && selectedImage == null)
            return;

        if (isGenerating) {
            addSystemMessage("Espera a que termine la respuesta actual");
            return;
        }

        // limpiar input
        inputArea.clear();

        if (selectedImage != null) {
            // mensaje con imagen
            String prompt = message.isEmpty() ? "Describe this image" : message;
            sendImageMessage(selectedImage, prompt);
            selectedImage = null;
            btnSelectImage.setText("Image");
        } else {
            // mensaje de texto
            sendTextMessage(message);
        }
    }

    private void sendTextMessage(String message) {
        // añadimos mensaje del usuario
        addUserMessage(message);

        // mantenemos el cliente a la espera y bloqueamos botones
        prepareAssistantMessage();
        setGenerating(true);

        // enviar mensaje al ollama
        ollamaService.sendTextMessage(
            message,
            this::appendToResponse,
            () -> Platform.runLater(() -> setGenerating(false)),
            error -> Platform.runLater(() -> {
                addSystemMessage("Error: " + error);
                setGenerating(false);
            })
        );
    }

    private void sendImageMessage(File imageFile, String prompt) {
        // añadir mensaje con imagen
        addUserMessageWithImage(prompt, imageFile);

        // mostrar "pensando..."
        addAssistantMessage("Pensando...");
        setGenerating(true);

        ollamaService.sendImageMessage(
            imageFile,
            prompt,
            response -> Platform.runLater(() -> {
                // quitamos el último elemento del chat
                if (!chatContainer.getChildren().isEmpty()) {
                    chatContainer.getChildren().remove(chatContainer.getChildren().size() - 1);
                }

                addAssistantMessage(response);
                setGenerating(false);
            }),
            error -> Platform.runLater(() -> {
                addSystemMessage("Error: " + error);
                setGenerating(false);
            })
        );
    }

    // mensaje del usuario en el chat
    private void addUserMessage(String message) {
        Platform.runLater(() -> {
            HBox messageBox = new HBox();
            messageBox.setAlignment(Pos.CENTER_RIGHT);
            messageBox.setPadding(new Insets(5, 10, 5, 50));

            VBox bubble = createMessageBubble(message, "#0d7377", "#ffffff");
            messageBox.getChildren().add(bubble);

            chatContainer.getChildren().add(messageBox);
        });
    }

    // mensaje del usuario con imagen en el chat
    private void addUserMessageWithImage(String message, File imageFile) {
        Platform.runLater(() -> {
            HBox messageBox = new HBox();
            messageBox.setAlignment(Pos.CENTER_RIGHT);
            messageBox.setPadding(new Insets(5, 10, 5, 50));

            VBox bubble = new VBox(5);
            bubble.setStyle("-fx-background-color: #0d7377; -fx-background-radius: 10; -fx-padding: 10;");
            bubble.setMaxWidth(500);

            // añadir imagen
            try {
                ImageView imageView = new ImageView(new Image(new FileInputStream(imageFile)));
                imageView.setFitWidth(200);
                imageView.setPreserveRatio(true);
                bubble.getChildren().add(imageView);
            } catch (Exception e) {
                // ignorar error
            }

            // añadir texto
            if (!message.isEmpty()) {
                Text text = new Text(message);
                text.setFill(Color.web("#ffffff"));
                text.setFont(Font.font(14));
                text.setWrappingWidth(480);
                bubble.getChildren().add(text);
            }

            messageBox.getChildren().add(bubble);
            chatContainer.getChildren().add(messageBox);
        });
    }

    // mensaje del ollama e nel chat
    private void addAssistantMessage(String message) {
        Platform.runLater(() -> {
            HBox messageBox = new HBox();
            messageBox.setAlignment(Pos.CENTER_LEFT);
            messageBox.setPadding(new Insets(5, 50, 5, 10));

            VBox bubble = createMessageBubble(message, "#3a3a3a", "#ffffff");
            messageBox.getChildren().add(bubble);

            chatContainer.getChildren().add(messageBox);
        });
    }

    // preparar el contenedor del ollama para el mensaje
    private void prepareAssistantMessage() {
        Platform.runLater(() -> {
            HBox messageBox = new HBox();
            messageBox.setAlignment(Pos.CENTER_LEFT);
            messageBox.setPadding(new Insets(5, 50, 5, 10));

            VBox bubble = new VBox();
            bubble.setStyle("-fx-background-color: #3a3a3a; -fx-background-radius: 10; -fx-padding: 10;");
            bubble.setMaxWidth(500);

            currentResponseFlow = new TextFlow();
            currentResponseFlow.setMaxWidth(480);
            bubble.getChildren().add(currentResponseFlow);

            messageBox.getChildren().add(bubble);
            chatContainer.getChildren().add(messageBox);
        });
    }

    // añadir chunk de texto a la respuesta
    private void appendToResponse(String chunk) {
        Platform.runLater(() -> {
            if (currentResponseFlow != null) {
                Text text = new Text(chunk);
                text.setFill(Color.web("#ffffff"));
                text.setFont(Font.font(14));
                currentResponseFlow.getChildren().add(text);
            }
        });
    }

    // mostrar mensaje del sistema en el chat
    private void addSystemMessage(String message) {
        Platform.runLater(() -> {
            HBox messageBox = new HBox();
            messageBox.setAlignment(Pos.CENTER);
            messageBox.setPadding(new Insets(5, 10, 5, 10));

            Text text = new Text(message);
            text.setFill(Color.web("#888888"));
            text.setFont(Font.font(12));
            text.setStyle("-fx-font-style: italic;");

            messageBox.getChildren().add(text);
            chatContainer.getChildren().add(messageBox);
        });
    }

    private VBox createMessageBubble(String message, String bgColor, String textColor) {
        VBox bubble = new VBox();
        bubble.setStyle("-fx-background-color: " + bgColor + "; -fx-background-radius: 10; -fx-padding: 10;");
        bubble.setMaxWidth(500);

        Text text = new Text(message);
        text.setFill(Color.web(textColor));
        text.setFont(Font.font(14));
        text.setWrappingWidth(480);

        bubble.getChildren().add(text);
        return bubble;
    }

    @FXML
    private void selectImage() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Select Image");
        fileChooser.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Image Files", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp")
        );

        File file = fileChooser.showOpenDialog(btnSelectImage.getScene().getWindow());
        if (file != null) {
            selectedImage = file;
            btnSelectImage.setText("📷 " + file.getName());
        }
    }

    @FXML
    private void stopGeneration() {
        ollamaService.stopGeneration();
        setGenerating(false);
        addSystemMessage("Generacion parada");
    }

    @FXML
    private void clearChat() {
        chatContainer.getChildren().clear();
        addSystemMessage("Chat limpiado");
    }

    private void setGenerating(boolean generating) {
        isGenerating = generating;
        Platform.runLater(() -> {
            btnSend.setDisable(generating);
            btnStop.setDisable(!generating);
            btnSelectImage.setDisable(generating);
        });
    }
}
