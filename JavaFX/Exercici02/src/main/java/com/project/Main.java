package com.project;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

public class Main extends Application {

    final int WINDOW_WIDTH = 700;
    final int WINDOW_HEIGHT = 500;

    @Override
    public void start(Stage stage) throws Exception {

        // cargamos las vistas del móvil y la del ordenador
        UtilsViews.addView(getClass(), "MobileMenu", "/assets/mobile_menu.fxml");
        UtilsViews.addView(getClass(), "MobileList", "/assets/mobile_list.fxml");
        UtilsViews.addView(getClass(), "MobileDetail", "/assets/mobile_detail.fxml");
        UtilsViews.addView(getClass(), "Desktop", "/assets/desktop.fxml");

        Scene scene = new Scene(UtilsViews.parentContainer);

        stage.setScene(scene);
        stage.setTitle("Nintendo DB");
        stage.setWidth(WINDOW_WIDTH);
        stage.setHeight(WINDOW_HEIGHT);
        
        // Afegeix una icona només si no és un Mac
        if (!System.getProperty("os.name").contains("Mac")) {
            Image icon = new Image("file:icons/icon.png");
            stage.getIcons().add(icon);
        }
        
        // Establecer la vista inicial según el ancho de la ventana
        if (stage.getWidth() < 600) {
            UtilsViews.setView("MobileMenu");
        } else {
            UtilsViews.setView("Desktop");
        }

        // Listener para cambios de tamaño
        scene.widthProperty().addListener((obs, oldWidth, newWidth) -> {
            if (newWidth.intValue() < 600) {
                UtilsViews.setView("MobileMenu");
            } else {
                UtilsViews.setView("Desktop");
            }
        });

        stage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
