import Toybox.WatchUi;

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

  	function onSelect(item) {
  		var id = item.getId();
        switch (id) {
            case :item_setting_method:
                WatchUi.pushView(new Rez.Menus.MethodMenu(), self, WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_method_jafari:
                Application.Properties.setValue("calculationMethod", 0);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_method_karachi:
                Application.Properties.setValue("calculationMethod", 1);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_method_isna:
                Application.Properties.setValue("calculationMethod", 2);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_method_mwl:
                Application.Properties.setValue("calculationMethod", 3);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_method_makkah:
                Application.Properties.setValue("calculationMethod", 4);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_method_egypt:
                Application.Properties.setValue("calculationMethod", 5);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_method_tehran:
                Application.Properties.setValue("calculationMethod", 6);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;


            case :item_setting_juristic:
                WatchUi.pushView(new Rez.Menus.JuristicMenu(), self, WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_juristic_shafii:
                Application.Properties.setValue("juristicMethod", 0);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_juristic_hanafi:
                Application.Properties.setValue("juristicMethod", 1);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;


            case :item_setting_latitude:
                WatchUi.pushView(new Rez.Menus.LatitudeMenu(), self, WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_latitude_none:
                Application.Properties.setValue("latitudeMethod", 0);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_latitude_midnight:
                Application.Properties.setValue("latitudeMethod", 1);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_latitude_oneseventh:
                Application.Properties.setValue("latitudeMethod", 2);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
            case :item_latitude_anglebased:
                Application.Properties.setValue("latitudeMethod", 3);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                break;
        }
  	}

  	function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
