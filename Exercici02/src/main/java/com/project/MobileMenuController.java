package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;

public class MobileMenuController {

    @FXML private Button btnGames, btnCharacters, btnConsoles;

    // ir a la lista al hacer click en la categoria
    @FXML
    private void toList() {
        String category = "";
        if (btnGames.isArmed()) category = "Games";
        if (btnCharacters.isArmed()) category = "Characters";
        if (btnConsoles.isArmed()) category = "Consoles";

        MobileListController.setCategory(category);
        UtilsViews.setViewAnimating("MobileList");
    }
}
