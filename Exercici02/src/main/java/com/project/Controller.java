package com.project;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;
import java.net.URL;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;

public class Controller implements Initializable {

    @FXML private ChoiceBox<String> choiceBox;
    @FXML private VBox yPane;

    @FXML private ImageView detailImage;
    @FXML private Label detailTitle;
    @FXML private Label detailDescription;

    private JSONArray jsonInfo;

    @Override
    public void initialize(java.net.URL url, ResourceBundle rb) {
        try {
            // opciones para elegir en el choicebox
            choiceBox.getItems().addAll("Games", "Characters", "Consoles");
            choiceBox.setValue("Games"); // valor inciial

            // Acción al cambiar de categoría
            choiceBox.setOnAction(e -> loadChoice(choiceBox.getValue()));

            // carga inicial
            loadChoice("Games");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // cargamos la lista según la categoria seleccionada
    private void loadChoice(String type) {
        try {
            String jsonFile = "";
            switch (type) {
                case "Games": jsonFile = "/assets/games.json"; break;
                case "Characters": jsonFile = "/assets/characters.json"; break;
                case "Consoles": jsonFile = "/assets/consoles.json"; break;
            }

            // pillams el contenido del json
            InputStream is = getClass().getResourceAsStream(jsonFile);
            if (is == null) { // si no hay archivo damos error
                System.out.println("ERROR no se encuentra el archivo JSON " + jsonFile);
                return;
            }

            String content = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            jsonInfo = new JSONArray(content);

            // Limpiar lista anterior
            yPane.getChildren().clear();

            // cargamos la plantilla de los items
            URL resource = getClass().getResource("/assets/listItem.fxml");

            // por cada item del json creamos una subvista
            for (int i = 0; i < jsonInfo.length(); i++) {
                JSONObject item = jsonInfo.getJSONObject(i);

                FXMLLoader loader = new FXMLLoader(resource);
                Parent itemTemplate = loader.load();
                ListItem itemController = loader.getController();

                itemController.setTitle(item.getString("name"));
                itemController.setImage("/assets/images/" + item.getString("image"));

                // llamar a la función showDetail al hacer click al item
                itemTemplate.setOnMouseClicked(e -> showDetail(type, item));

                // añadirlo a la lista
                yPane.getChildren().add(itemTemplate);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void showDetail(String type, JSONObject item) {
        detailTitle.setText(item.getString("name"));

        switch(type) {
            case "Games":
                detailDescription.setText(item.getString("plot"));
                break;
            case "Characters":
                detailDescription.setText(item.getString("game"));
                break;
            case "Consoles":
                detailDescription.setText("Procesador: " + item.getString("procesador") +
                                          "\nUnidades vendidas: " + item.getInt("units_sold"));
                break;
        }

        try {
            detailImage.setImage(new Image(getClass().getResourceAsStream("/assets/images/" + item.getString("image"))));
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
}
