import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Position;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Activity;
import IslamicCalendarModule;

class connectiqprayfaceView extends WatchUi.WatchFace {
    var calculator;
    var times;
    var names = ["Midnight", "Fajr", "Sunrise", "Duhr", "Asr", "Maghrib", "Isha", "Midnight"];
    var lasthourupdate = 0;
    var lastminupdate = 0;
    var location;
    var dayView;
    var secondsView;
    var stepsView;
    var notificationsView;
    var batteryView;
    var praystartView;
    var prayendView;
    var praynameView;
    var width;
    var is_awake;
    var height;

    function initialize() {
        WatchFace.initialize();
        calculator = new SalahCalculator();
        is_awake = true;
        times = [0, 0, 0, 0, 0, 0, 0];
        // we default location close to developers home
        location = [30.008518, 30.982032];
        updateTimes();
    }

    function updateTimes() {
        // set settings
        var method = Application.Properties.getValue("calculationMethod");
        calculator.setCalcMethod(method);
        var juristic = Application.Properties.getValue("juristicMethod");
        calculator.setAsrJuristic(juristic);
        var latitude_method = Application.Properties.getValue("latitudeMethod");
        calculator.setAdjustHighLats(latitude_method);
        System.println("Method: " + method + " Jursitic: " + juristic + " Adjust: " + latitude_method);

        // set posititions
        var position = Position.getInfo().position;
        var coordinates = position.toDegrees();
        System.println("Long: " + coordinates[0] + " Lan: " + coordinates[1]);
        if (!is_null_location(coordinates)) {
            location = coordinates;
        }
        var clock = System.getClockTime();
        var hoursDiff = (clock.timeZoneOffset) / 3600d;
        System.println("Timezone: " + hoursDiff);
        var calcTimes = calculator.getPrayerTimes(Time.now(), location[0], location[1], hoursDiff);
        times = [0];
        times = times.addAll(calcTimes.slice(0, 4));
        times.addAll(calcTimes.slice(5, 7));
        times.add(24);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        width = dc.getWidth();
        height = dc.getHeight();
    }

    function is_null_location(location) {
        if (location[0] == 0 and location[1] == 0){
            return true;
        } else if (location[0] == 180 and location[1] == 180){
            return true;
        } else if (location[0] == -180 and location[1] == -180){
            return true;
        }
        return false;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var floatTime = clockTime.min.toFloat() / 60;
        floatTime += clockTime.hour;
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        var stats = System.getSystemStats();
        var devsettings = System.getDeviceSettings();
        var info =  ActivityMonitor.getInfo();
        // Should we update calctimes?
        if (lasthourupdate != clockTime.hour or (is_null_location(location) and lastminupdate != clockTime.min)) {
            updateTimes();
            lasthourupdate = clockTime.hour;
            lastminupdate = clockTime.min;
        }

        // load views
        var clockView = View.findDrawableById("TimeLabel") as Text;
        var statusView = View.findDrawableById("status") as Text;
        var dateView = View.findDrawableById("Date") as Text;
        var dayView = View.findDrawableById("Day") as Text;
        var secondsView = View.findDrawableById("TimeSeconds") as Text;
        var stepsView = View.findDrawableById("Steps") as Text;
        var notificationsView = View.findDrawableById("Notifications") as Text;
        var batteryView = View.findDrawableById("Battery") as Text;
        var praystartView = View.findDrawableById("PrayStart") as Text;
        var praynameView = View.findDrawableById("PrayName") as Text;
        var prayendView = View.findDrawableById("PrayEnd") as Text;

        // Update the time
        clockView.setText(timeString);
        if (is_awake) {
            secondsView.setText(clockTime.sec.format("%02d"));
        } else {
            secondsView.setText("");
        }
        // Update stepsView
        var steps_str = info.steps.toString();
        stepsView.setText(steps_str);
        // Update datViewe
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        dateView.setText(today.day.toString());
        dayView.setText(today.day_of_week);
        if (devsettings.phoneConnected) {
            notificationsView.setText(devsettings.notificationCount.toString()); 
        }
        // Set DND
        if (devsettings.doNotDisturb) {
            statusView.setText("Zzz"); 
        }
        // Update batery text
        batteryView.setText(stats.battery.format("%02d") + "%");
        // Pray times
        var prayername = "Unknown";
        var prayerstart = 0;
        var prayerend = 1;
        for (var i = 1; i < times.size(); i++){
            if (times[i-1] < floatTime and times[i] > floatTime) {
                prayername = names[i - 1];
                prayerstart = times[i - 1];
                prayerend = times[i];
                break;
            }
        }
        praystartView.setText(calculator.floatToTime24(prayerstart));
        prayendView.setText(calculator.floatToTime24(prayerend));
        praynameView.setText(prayername);
        var prayerpercent = (floatTime - prayerstart) / (prayerend - prayerstart);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        // draw seperator lines
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        // seperator clockView / bottom
        var linelenght = prayerpercent * width;
        dc.drawLine(0, 120, linelenght, 120);
        dc.drawLine(0, 118, width, 118);
        dc.drawLine(0, 122, width, 122);
        // line between batteryView; and notification
        dc.drawLine(65, 40, 65, 55);
        // draw precentage circle
        dc.setPenWidth(12);
        var consumedbat = 100 - stats.battery;;
        // consumedbat = 0.0;
        var arcangle = 360 * ( 1 - (consumedbat/ 100));
        var destarc = (90 + arcangle.toNumber()) % 360;
        dc.drawArc(144, 31, 30, Graphics.ARC_COUNTER_CLOCKWISE, 90, destarc);
        var font = WatchUi.loadResource( Rez.Fonts.icons );
        // step icon
        dc.drawText(40, 5, font, "B", Graphics.TEXT_JUSTIFY_CENTER);
        // battery icon
        dc.drawText(15, 35, font, "T", Graphics.TEXT_JUSTIFY_CENTER);
        // notification icon
        if (devsettings.phoneConnected) {
            dc.drawText(70, 35, font, "V", Graphics.TEXT_JUSTIFY_CENTER);
        }
        // seperator clockView top
        dc.setPenWidth(2);
        dc.drawLine(0, 60, 115, 60);
        var steppercent = ((info.steps / info.stepGoal.toFloat()) * 114).toNumber();
        dc.drawLine(0, 62, steppercent, 62);
        dc.drawLine(0, 64, 115, 64);

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        is_awake = true;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        is_awake = false;
        WatchUi.requestUpdate();
    }

}
