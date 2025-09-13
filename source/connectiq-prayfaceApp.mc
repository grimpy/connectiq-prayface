import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class connectiqprayfaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [new connectiqprayfaceView()];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    // set method sublabel
    function _setSubLabel(mainmenu, submenu, setting_name, index) {
        var setting = Application.Properties.getValue(setting_name);
        var menuitem = mainmenu.getItem(index);
        var subitem = submenu.getItem(setting);
        menuitem.setSubLabel(subitem.getLabel());
    }
    
    function getSettingsView() {
        var mainmenu = new Rez.Menus.MainMenu();
        _setSubLabel(mainmenu, new Rez.Menus.MethodMenu(), "calculationMethod", 0);
        _setSubLabel(mainmenu, new Rez.Menus.JuristicMenu(), "juristicMethod", 1);
        _setSubLabel(mainmenu, new Rez.Menus.LatitudeMenu(), "latitudeMethod", 2);

        return [mainmenu, new SettingsMenuDelegate()];
    }   

}

function getApp() as connectiqprayfaceApp {
    return Application.getApp() as connectiqprayfaceApp;
}