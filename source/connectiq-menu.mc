import Toybox.WatchUi;

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
  	function onSelect(item) {
  		var id = item.getId();
        var menu = null;
        var setting = null;
        switch (id) {
            case :item_setting_method:
                menu = new Rez.Menus.MethodMenu();
                setting = "calculationMethod";
                break;

            case :item_setting_juristic:
                menu = new Rez.Menus.JuristicMenu();
                setting = "juristicMethod";
                break;

            case :item_setting_latitude:
                menu = new Rez.Menus.LatitudeMenu();
                setting = "latitudeMethod";
                break;
        }
        if (setting != null) {
            WatchUi.pushView(menu, 
                    new SubSettingsMenuDelegate(item, setting, menu), 
                    WatchUi.SLIDE_IMMEDIATE);
        }
  	}

  	function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class SubSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var parent;
    var setting;
    var menu;
    function initialize(item, setting, menu) {
        self.parent = item;
        self.setting = setting;
        self.menu = menu;
        Menu2InputDelegate.initialize();
    }
  	function onSelect(item) {
        parent.setSubLabel(item.getLabel());
  		var id = item.getId();
        var value = menu.findItemById(id);
        if (value != null ) {
            Application.Properties.setValue(setting, value);
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
  	}

  	function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
