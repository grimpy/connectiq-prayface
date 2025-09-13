//--------------------- Copyright Block ----------------------
//
//
//PrayTime.java: Prayer Times Calculator (ver 1.0)
//Copyright (C) 2007-2010 PrayTimes.org
//
//Monkey-C Code By: Spencer Bruce
//Original JS Code By: Hamid Zarrabi-Zadehh

//License: GNU LGPL v3.0
//
//TERMS OF USE:
//	Permission is granted to use this code, with or
//	without modification, in any website or application
//	provided that credit is given to the original work
//	with a link back to PrayTimes.org.
//
//This program is distributed in the hope that it will
//be useful, but WITHOUT ANY WARRANTY.
//
//PLEASE DO NOT REMOVE THIS COPYRIGHT BLOCK.
//
//

using IslamicCalendarModule.ExtendedMaths as Maths;
using Toybox.Time as Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

module IslamicCalendarModule {
    const M_JAFARI = 0; // Ithna Ashari
    const M_KARACHI = 1; // University of Islamic Sciences, Karachi
    const M_ISNA = 2; // Islamic Society of North America
    const M_MWL = 3; // Muslim World League
    const M_MAKKAH = 4; // Umm al-Qura, Makkah
    const M_EGYPT = 5; // Egyptian General Authority of Survey
    const M_TEHRAN = 6; // Institute of Geophysics, Univ. of Tehran
    const M_CUSTOM = 7; // Custom
    
    const ASR_SHAFII = 0; // factor = 1
    const ASR_HANAFI = 1; // factor = 2
    
    const HL_NONE = 0; // no high-latitude adjustment
    const HL_MIDNIGHT = 1; // middle of night
    const HL_ONE7TH = 2; // 1/7 of night
    const HL_ANGLE60TH = 3; // angle/60 of night

	class SalahCalculator {

    // ---------------------- Global Variables --------------------
    hidden var calcMethod; // caculation method
    hidden var asrJuristic; // Juristic method for Asr
    hidden var dhuhrMinutes; // minutes after mid-day for Dhuhr
    hidden var adjustHighLats; // adjusting method for higher latitudes
    hidden var lat; // latitude
    hidden var lng; // longitude
    hidden var timeZone; // time-zone
    hidden var JDate; // Julian date
    // --------------------- Technical Settings --------------------
    const numIterations = 1; // number of iterations needed to compute times
    // ------------------- Calc Method Parameters --------------------
    hidden var methodParams;

    //
    //* this.methodParams[methodNum] = new Array(fa, ms, mv, is, iv);
    // *
    // * fa : fajr angle ms : maghrib selector (0 = angle; 1 = minutes after
    // * sunset) mv : maghrib parameter value (in angle or minutes) is : isha
    // * selector (0 = angle; 1 = minutes after maghrib) iv : isha parameter value
    // * (in angle or minutes)
    // */
    hidden var prayerTimesCurrent;
    hidden var offsets;

    function initialize() {
        // Initialize vars

        setCalcMethod(0);
        setAsrJuristic(0);
        self.dhuhrMinutes = 0;
        setAdjustHighLats(1);


        // ------------------- Calc Method Parameters --------------------

        // Tuning offsets {fajr, sunrise, dhuhr, asr, sunset, maghrib, isha}
        offsets = new [7];
        offsets[0] = 0;
        offsets[1] = 0;
        offsets[2] = 0;
        offsets[3] = 0;
        offsets[4] = 0;
        offsets[5] = 0;
        offsets[6] = 0;

        /*
        * fajr angle 
        * maghrib selector (0 = angle; 1 = minutes after sunset) 
        * maghrib parameter value (in angle or minutes) 
        * isha selector (0 = angle; 1 = minutes after maghrib 
        * isha parameter value (in angle or minutes)
        */
        methodParams = {
          M_JAFARI =>  [16d,   0d,   4d, 0d,   14d],
          M_KARACHI => [18d,   1d,   0d, 0d,   18d],
          M_ISNA =>    [15d,   1d,   0d, 0d,   15d],
          M_MWL =>     [18d,   1d,   0d, 0d,   17d],
          M_MAKKAH =>  [18.5d, 1d,   0d, 1d,   90d],
          M_EGYPT =>   [19.5d, 1d,   0d, 0d, 17.5d],
          M_TEHRAN =>  [17.7d, 0d, 4.5d, 0d,   14d],
          M_CUSTOM =>  [18d,   1d,   0d, 0d,   17d],
        };

    }

    // ---------------------- Trigonometric Functions -----------------------
    // range reduce angle in degrees.


    // ---------------------- Time-Zone Functions -----------------------
    // compute base time-zone of the system
    hidden function getBaseTimeZone() {
        var hoursDiff = (System.getClockTime().timeZoneOffset / 1000.0d) / 3600d;
        return hoursDiff;

    }

    // ---------------------- Julian Date Functions -----------------------
    // calculate julian date from a calendar date
    hidden function julianDate(year, month, day) {
        if (month <= 2) {
            year -= 1;
            month += 12;
        }
        var A = Maths.floor(year / 100.0d);
        var B = 2d - A + Maths.floor(A / 4.0d);
        var JD = Maths.floor(365.25d * (year + 4716d))
                + Maths.floor(30.6001d * (month + 1)) + day + B - 1524.5d;
        return JD;
    }

    // convert a calendar date to julian date (second method)
    hidden function calcJD(year, month, day) {
        var J1970 = 2440588.0d;
        var date = Gregorian.moment({:year => year, :month => month - 1, :day => day});

        var ms = date.value(); // # of milliseconds since midnight Jan 1,
        // 1970
        var days = Maths.floor(ms / (60.0d * 60.0d * 24.0d));
        return J1970 + days - 0.5;

    }

    // ---------------------- Calculation Functions -----------------------
    // References:
    // http://www.ummah.net/astronomy/saltime
    // http://aa.usno.navy.mil/faq/docs/SunApprox.html
    // compute declination angle of sun and equation of time
    hidden function sunPosition(jd) {

        var D = jd - 2451545d;
        var g = Maths.fixangle(357.529d + 0.98560028d * D);
        var q = Maths.fixangle(280.459d + 0.98564736d * D);
        var L = Maths.fixangle(q + (1.915d * Maths.dsin(g)) + (0.020d * Maths.dsin(2d * g)));

        // double R = 1.00014 - 0.01671 * [self dcos:g] - 0.00014 * [self dcos:
        // (2*g)];
        var e = 23.439d - (0.00000036d * D);
        var d = Maths.darcsin(Maths.dsin(e) * Maths.dsin(L));
        var RA = (Maths.darctan2((Maths.dcos(e) * Maths.dsin(L)), (Maths.dcos(L))))/ 15.0d;
        RA = Maths.fixhour(RA);
        var EqT = q/15.0d - RA;
        var sPosition = new [2];
        sPosition[0] = d;
        sPosition[1] = EqT;

        return sPosition;
    }

    // compute equation of time
    hidden function equationOfTime(jd) {
        var eq = sunPosition(jd)[1];
        return eq;
    }

    // compute declination angle of sun
    hidden function sunDeclination(jd) {
        var d = sunPosition(jd)[0];
        return d;
    }

    // compute mid-day (Dhuhr, Zawal) time
    hidden function computeMidDay(t) {
        var T = equationOfTime(JDate + t);
        var Z = Maths.fixhour(12 - T);
        return Z;
    }

    // compute time for a given angle G
    hidden function computeTime(G, t) {
        var D = sunDeclination(JDate + t);
        var Z = computeMidDay(t);
        var Beg = -Maths.dsin(G) - Maths.dsin(D) * Maths.dsin(lat);
        var Mid = Maths.dcos(D) * Maths.dcos(lat);
        var V = Maths.darccos(Beg/Mid)/15.0;
        return Z + (G > 90 ? -V : V);
    }

    // compute the time of Asr
    // Shafii: step=1, Hanafi: step=2
    hidden function computeAsr(step, t) {
        var D = sunDeclination(JDate + t);
        var G = -Maths.darccot(step + Maths.dtan((lat - D).abs()));
        return computeTime(G, t);
    }

    // ---------------------- Misc Functions -----------------------
    // compute the difference between two times
    hidden function timeDiff(time1, time2) {
        return Maths.fixhour(time2 - time1);
    }

    // -------------------- Interface Functions --------------------
    // return prayer times for a given date
    hidden function getDatePrayerTimes(year, month, day,
            latitude, longitude, tZone) {
        self.lat = latitude;
        self.lng = longitude;
        self.timeZone = tZone;
        self.JDate = julianDate(year, month, day);
        var lonDiff = longitude / (15.0d * 24.0d);
        self.JDate -= lonDiff;
        return computeDayTimes();
    }

	function getPrayerTimesFromGeoLocation(date, latitude, longitude) {
		return getPrayerTimes(date, latitude, longitude, 0);
	}

    // return prayer times for a given date
    function getPrayerTimes(date, latitude, longitude, tZone) {
    	var info = Time.Gregorian.info(date, Time.FORMAT_SHORT);
        var year = info.year;
        var month = info.month;
        var day = info.day;
//
        return getDatePrayerTimes(year, month, day, latitude, longitude, tZone);
    }

    // set custom values for calculation parameters
    function setCustomParams(params) {
        for (var i = 0; i < 5; i++) {
            if (params[i] == -1) {
                params[i] = methodParams[calcMethod][i];
            }
            methodParams[M_CUSTOM][i] = params[i];
        }
        setCalcMethod(M_CUSTOM);
    }

	function getDatesFromTimes(calendar, times) {
		for (var i = 0; i < times.size(); i++) {
			times[i] = getDateFromTime(calendar, times[i]);
		}
		
		return times;
	}

	function getDateFromTime(calendar, time) {
		if (null == time) {
			return null;
		}
		var calculatedTime = Maths.fixhour(time);

		var timeInfo = Time.Gregorian.info(calendar, Toybox.Time.FORMAT_SHORT);
					 
		var hours = calculatedTime.toNumber();
		calculatedTime -= hours;
		calculatedTime *= 60;
		var minutes = calculatedTime.toNumber(); // retain only the minutes
		calculatedTime -= minutes;
		calculatedTime *= 60;
		var seconds = calculatedTime.toNumber(); // retain only the seconds
		calculatedTime -= seconds; // remaining milliseconds
					
		var cal = Time.Gregorian.moment({:year=>timeInfo.year, :month=>timeInfo.month, :day=>timeInfo.day,
											:hour=>hours, :minute=>minutes, :second=>seconds});

		var gmtOffset = getBaseTimeZone();
        System.println("GMT OFFSET: " + gmtOffset);
		if (time + gmtOffset > 24) {
			var duration = Time.Gregorian.duration({:days=>-1});
			cal = cal.add(duration);
		} else if (time + gmtOffset < 0) {
			var duration = Time.Gregorian.duration({:days=>1});
			cal = cal.add(duration);
		}

		return cal;
	}

    // convert double hours to 24h format
    function floatToTime24(time) {
        var hour = time.toNumber();
        var minutes = ((time - hour) * 60).toNumber();
        return Lang.format("$1$:$2$", [hour.format("%d"), minutes.format("%02d")]);
    }

    // ---------------------- Compute Prayer Times -----------------------
    // compute prayer times at given julian date
    hidden function computeTimes(times) {
        var t = dayPortion(times);
        var Fajr = computeTime(
                180 - methodParams[calcMethod][0], t[0]);

        var Sunrise = computeTime(180 - 0.833d, t[1]);

        var Dhuhr = computeMidDay(t[2]);
        var Asr = computeAsr(1 + asrJuristic, t[3]);
        var Sunset = computeTime(0.833d, t[4]);

        var Maghrib = computeTime(
                methodParams[calcMethod][2], t[5]);
        var Isha = computeTime(
                methodParams[calcMethod][4], t[6]);

        var CTimes = [Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha];
        return CTimes;

    }

    // compute prayer times at given julian date
    hidden function computeDayTimes() {
        var times = [5d, 6d, 12d, 13d, 18d, 18d, 18d]; // default times

        for (var i = 1; i <= numIterations; i++) {
            times = computeTimes(times);
        }

        times = adjustTimes(times);
        times = tuneTimes(times);
       return times;
    }

    // adjust times in a prayer time array
    hidden function adjustTimes(times) {
        for (var i = 0; i < times.size(); i++) {
            times[i] += timeZone - lng / 15d;
        }
        times[2] += dhuhrMinutes / 60d; // Dhuhr
        if (methodParams[calcMethod][1] == 1) // Maghrib
        {
            times[5] = times[4] + methodParams[calcMethod][2]/ 60d;
        }
        if (methodParams[calcMethod][3] == 1) // Isha
        {
            times[6] = times[5] + methodParams[calcMethod][4]/ 60d;
        }

        if (adjustHighLats != HL_NONE) {
            times = adjustHighLatTimes(times);
        }

        return times;
    }

    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    hidden function adjustHighLatTimes(times) {
        var nightTime = timeDiff(times[4], times[1]); // sunset to sunrise
        // Adjust Fajr
        var FajrDiff = nightPortion(methodParams[calcMethod][0]) * nightTime;

        if (checkForNaN(times[0]) || timeDiff(times[0], times[1]) > FajrDiff) {
            times[0] = times[1] - FajrDiff;
        }

        // Adjust Isha
        var IshaAngle = (methodParams[calcMethod][3] == 0) ? methodParams[calcMethod][4] : 18d;
        var IshaDiff = nightPortion(IshaAngle) * nightTime;
        if (checkForNaN(times[6]) || timeDiff(times[4], times[6]) > IshaDiff) {
            times[6] = times[4] + IshaDiff;
        }

        // Adjust Maghrib
        var MaghribAngle = (methodParams[calcMethod][1] == 0) ? methodParams[calcMethod][2] : 4d;
        var MaghribDiff = nightPortion(MaghribAngle) * nightTime;
        if (checkForNaN(times[5]) || timeDiff(times[4], times[5]) > MaghribDiff) {
            times[5] = times[4] + MaghribDiff;
        }

        return times;
    }

	hidden function checkForNaN(number) {
		return number.toString().equals("-1.#IND00");
	}

    // the night portion used for adjusting times in higher latitudes
    hidden function nightPortion(angle) {
	    var calc = 0d;
	
		if (adjustHighLats == HL_ANGLE60TH) {
			calc = (angle)/60.0d;
		} else if (adjustHighLats == HL_MIDNIGHT) {
			calc = 0.5d;
		} else if (adjustHighLats == HL_MIDNIGHT) {
			calc = 0.14286d;
		}
	
		return calc;
    }

    // convert hours to day portions
    hidden function dayPortion(times) {
        for (var i = 0; i < 7; i++) {
            times[i] /= 24d;
        }
        return times;
    }

    // Tune timings for adjustments
    // Set time offsets
    function tune(offsetTimes) {

        for (var i = 0; i < offsetTimes.size(); i++) { // offsetTimes length
            // should be 7 in order
            // of Fajr, Sunrise,
            // Dhuhr, Asr, Sunset,
            // Maghrib, Isha
            offsets[i] = offsetTimes[i];
        }
    }

    function tuneTimes(times) {
        for (var i = 0; i < times.size(); i++) {
            times[i] = times[i] + offsets[i] / 60.0d;
        }

        return times;
    }

    function setCalcMethod(localcalcMethod) {
        calcMethod = localcalcMethod;
    }

    function setAsrJuristic(localasrJuristic) {
        asrJuristic = localasrJuristic;
    }

    function setAdjustHighLats(localadjustHighLats) {
        adjustHighLats = localadjustHighLats;
    }
}
}