//! Controller class for IHApp
//! Controls overall flow of app, settings and processing

using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as System;
using Toybox.Timer as Timer;
using Toybox.Activity as Activity;
using Toybox.Attention as Attention;
using Toybox.Time as Time;
using Toybox.Lang as Lang;
using Toybox.ActivityRecording as Recording;

class IHController
{
    hidden var mModel;
    hidden var mTimer;
    hidden var isSecondaryTimerStarted;
    hidden var allowVibration;
    
    //Font constants
    var FONTXXXTINY = Ui.loadResource( Rez.Fonts.RobotoCondensedReg16 ); //GPS, %
    var FONTXXTINY = Ui.loadResource( Rez.Fonts.RobotoCondensedBold22  ); //Temperature, Batt
    var FONTXTINY = Ui.loadResource( Rez.Fonts.RobotoMedium22 );		//Field Labels
    var FONTTINY = Ui.loadResource( Rez.Fonts.RobotoCondensedBold28 ); 	//Calories and Intensity Minutes Values
    var FONTSMALL = Ui.loadResource( Rez.Fonts.RobotoCondensedBold30 ); //Time, Timer, Peak and Max, Workout Done
    var FONTLARGE = Ui.loadResource( Rez.Fonts.RobotoBlack39 ); //HR Percent and HR Initial View
    var FONTXXLARGE = Ui.loadResource( Rez.Fonts.RobotoBlack76 ); //Main HR
    
    //Workout View States
    enum {UISTATE_EXITONBACK, UISTATE_WAITINGTOSTART, UISTATE_WAITINGFORHR, UISTATE_RUNNING, UISTATE_STOPPED, UISTATE_WORKOUTEND}
    var WorkoutUIState = UISTATE_WAITINGTOSTART;
    
    var hrZoneMode = 1; //Controls if showing HR Zone Values or HR Zone Workout Minutes by SwipeUp/SwipeDown or KeyUp/KeyDown
    var forceOnUpdate = false; //If an event like PopUpMenus, Swipe or Key press was detected, refresh screen
    
    // Settings IDs
    const ACTIVITY_TYPE = "activityType";
    const ACTIVITY_SUB_TYPE = "activitySubType";
    const ALLOW_VIBRATION = "allowVibration";
    //const ALLOW_HRSTABILITY = "allowHRStability";   
    const ALLOW_GPSTRACKING = "allowGPSTracking";
    const ALLOW_DARKMODE = "allowDarkMode"; 
    const ALLOW_BATTTEMP = "allowBATTTEMP"; 
    const GRPH_REFRSH_RATE  = "graphRefreshRate";
    const IS_VIVOACTIVE3 = Ui.loadResource(Rez.Strings.isVivoActive).toNumber();
    
    //const ASK_ACTIVITY = "askActivity";
    
    const GPSCapable = 1;
    const GPSDisabled = 0;
     
    //Activities Menu Items
	var mActivities  = [		
		[Recording.SPORT_TRAINING, Recording.SUB_SPORT_STRENGTH_TRAINING, 		:strength_training, GPSDisabled],	//1	
		[Recording.SPORT_TRAINING, Recording.SUB_SPORT_CARDIO_TRAINING, 	    :cardio_training,   GPSDisabled],	//2
		[Recording.SPORT_HIKING, Recording.SUB_SPORT_GENERIC,				    :hiking, 			GPSCapable],	//3
		[Recording.SPORT_RUNNING, Recording.SUB_SPORT_GENERIC,					:running, 			GPSCapable],	//4
		[Recording.SPORT_GENERIC, Recording.SUB_SPORT_GENERIC, 			    	:sports, 			GPSDisabled]	//5
	];
		
	var mActivitiesStr = [
		"Strength",	//1
		"Cardio",	//2
		"Hiking",	//3
		"Running",	//4
		"Sports"	//5
	];
	
	var mRefRate = [
		["Normal-30 Secs", :grrNormal, 30],
		["High-15 Secs",   :grrHigh, 15],
		["Live-5 Secs",    :grrLive, 5]
	];

    //! Initialize the controller
    function initialize() {
        //var AppName = Ui.loadResource(Rez.Strings.AppName);
        //var AppVersion = Ui.loadResource(Rez.Strings.AppVersion);

        //Log.debug("App: " + AppName);
        //Log.debug("Version: " + AppVersion);

        // Connect to Heart Rate Sensor
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));

        // Allocate a timer
        mTimer = null;
        isSecondaryTimerStarted = false;
        
        // Get the model from the application
        mModel = App.getApp().model;
        
    }

    //! Start the recording process
    //! If it was not previously started confirm the presense of a HR
    function startWorkout() {
        //mRunning = true;
       WorkoutUIState = UISTATE_RUNNING;
        
        //var delegate = new IHWorkoutDelegate();
        //var view = new IHWorkoutView();
        //Ui.switchToView(view, delegate, Ui.SLIDE_LEFT);
        loadPreferences();
        mModel.start();
        notifyShort();
    }

    //! Start the Model
    function resumeWorkout() {
        WorkoutUIState = UISTATE_RUNNING;
        mModel.start();
        notifyShort();
    }

    //! Stop/Pause the Model
    function stopWorkout() {
    
        WorkoutUIState = UISTATE_STOPPED;
        
        mModel.stop();
        notifyShort();
        
    }

    //! Handle the start/stop button
    /*
    function onStartStop() {
        if(WorkoutUIState == UISTATE_RUNNING) {
            stopWorkout();
        } else {
            resumeWorkout();
        }
    }*/

    //! Confirmation of no HR
    function confirmStart() {
        // grab current heart rate
        
        //Start was pressed
       
        var heartrate = mModel.getHRbpm();
        // If there is no heart rate detected and the prompt has not previously been confirmed
        // confirm if the user still wishes to start the workout
        if ((heartrate == 0 || heartrate == null)) {
			//Ui.popView(Ui.SLIDE_DOWN);
            // Open the HR confirmation dialog
            //Ui.pushView(new Ui.Confirmation("Do you want to wait for HR?"), new StartConfirmationDelegate(), Ui.SLIDE_UP );
             WorkoutUIState = UISTATE_WAITINGFORHR;
        } else {
            //confirmed = true;
            //WorkoutUIState = UISTATE_READYTOSTART;
            startWorkout();
        }
    }

    //! Save the recording
    function save() {


        // Give the system some time to finish the recording. Push up a progress bar
        // and start a timer to allow all processing to finish
        Ui.pushView(new Ui.ProgressBar("Saving...", null), new ProgressDelegate(), Ui.SLIDE_DOWN);
        //mTimer = new Timer.Timer();

        // Set final statistic variables for review
        mModel.setStats();

        // Save the recording
        mModel.save();
        
        onFinish();

        // After data is saved, proceed to screens to review the stats of the workout
        //mTimer.start(method(:onFinish), 3000, false);
        
    }

    //! Discard the recording
    function discard() {
        mModel.discard();

        // Give the system some time to discard the recording. Push up a progress bar
        // and start a timer to allow all processing to finish
        Ui.pushView(new Ui.ProgressBar("Discarding...", null), new ProgressDelegate(), Ui.SLIDE_DOWN);
        mTimer = new Timer.Timer();

        // After data is discarded, exit the app
        mTimer.start(method(:onExit), 1000, false);
    }

     //! Review the stats of the activity when finished
    function onFinish() {
    
    	WorkoutUIState = UISTATE_WORKOUTEND;
    	Ui.popView(Ui.SLIDE_IMMEDIATE);
    	Ui.popView(Ui.SLIDE_IMMEDIATE);
    	
        //var delegate = new IHReviewDelegate();
        //var view = new IHReviewView();

        //Ui.switchToView(view, delegate, Ui.SLIDE_UP);
    }

    //! Are we running currently?
    //function isRunning() {
    //    return mRunning;
    //}

    //! Get the recording time elapsed
    function getTime() {
        return mModel.getTimeElapsed();
    }

    //! Handle Sensor Events
    function onSensor(sensor_info) {
        mModel.setSensor(sensor_info);
    }

    //! Handle timing out after exit
    function onExit() {
        System.exit();
    }

    //! Load preferences for the view from the object store.
    //! This can be called from the app when the settings have changed.
    function loadPreferences() {
    
    	mModel.setGPSTracking(getGPSTracking());
        //Log.debug("Preferences Loading");
        // Set Activity Recording Type
        mModel.setActivity(getActivityType(), getActivitySubType());
        // Set HR Stability
        //mModel.setStability(getHRStability());
        //Log.debug("HR Stability: " + Prefs.getHRStability());
        // Set Vibration Policy
        allowVibration = (Attention has :vibrate) && (System.getDeviceSettings().vibrateOn) && (getAllowVibration() == true);
        //Log.debug("Allow Vibration: " + allowVibration);
    }
    
    // Return activity type string
    function getActivityString() {
    
	    var type = getActivityType();
	    var subType = getActivitySubType();
    
		//Activities Sub Menu Options
		for(var i =0; i< mActivities.size(); ++i){
			var actMenuIDArray = mActivities[i];
			if (type == actMenuIDArray[0] && subType == actMenuIDArray[1]) {
	            return mActivitiesStr[i];
        	}
		}
		
        return "Unknown Activity";
    }

    //! Turn on backlight.
    //! Trigger a timer to turn off backlight after 3 seconds.
    function turnOnBacklight() {
        //if (backlightTimer == null) {
            //backlight(true);
            //backlightTimer = new Timer.Timer();
            //backlightTimer.start(method(:onBacklightTimer), 5000, false);
        //}
    }

    //! Action on backlight timer, turn off backlight and invalidate timer.
    function onBacklightTimer() {
        //backlight(false);
        //backlightTimer = null;
    }

    //! Turn on/off backlight based on given flag.
    function backlight(on) {
        if (Attention has :backlight) {
            Attention.backlight(on);
        }
    }

    hidden function notifyShort() {
        turnOnBacklight();
        vibrate(0);
    }
    
    function restartSecondaryTimer(){
        	mModel.startSecondaryTimer((isSecondaryTimerStarted?false:true));
        	isSecondaryTimerStarted = true;
    }
    
    //Toggles Start/Reset Secondary Timer
    function toggleSecondaryTimer(){
    
    	mModel.createInterval();
	    mModel.resetSecondaryTimer();
	    mModel.startSecondaryTimer(true);
    
    	/*START/STOP/START/STOP
    	if(isSecondaryTimerStarted == false) {
        	mModel.startSecondaryTimer(true);
        	isSecondaryTimerStarted = true;
        }
        else {
        	mModel.resetSecondaryTimer();
        	isSecondaryTimerStarted = false;
        }*/
    }

    function vibrate(style) {
        if (allowVibration) {
            var VibeData = null;
            if ( style == 0 ) {
                // Single Short
                VibeData =
                [
                    new Attention.VibeProfile(100, 250)
                ];
            } else if ( style == 1 ) {
                // Single Long
                VibeData =
                [
                    new Attention.VibeProfile(100, 750) //Originally 2000
                ];
            } else if ( style == 2 ) {
                // Two Short
                VibeData =
                [
                    new Attention.VibeProfile(100, 250),
                    new Attention.VibeProfile(0, 250),
                    new Attention.VibeProfile(100, 250)
                ];
            } else if ( style == 3 ) {
                // Three Short
                VibeData =
                [
                    new Attention.VibeProfile(100, 250),
                    new Attention.VibeProfile(0, 250),
                    new Attention.VibeProfile(100, 250),
                    new Attention.VibeProfile(0, 250),
                    new Attention.VibeProfile(100, 250)
                ];
            }
            Attention.vibrate(VibeData);
        }
    }
    
    //! Return the number value for a preference, or the given default value if pref
    //! does not exist, is invalid, is less than the min or is greater than the max.
    //! @param name the name of the preference
    //! @param def the default value if preference value cannot be found
    //! @param min the minimum authorized value for the preference
    //! @param max the maximum authorized value for the preference
    function getNumbericPref(name, def, min, max) {
        var app = App.getApp();
        var pref = def;

        if (app != null) {
            pref = app.getProperty(name);

            if (pref != null) {
                // GCM used to return value as string
                if (pref instanceof Toybox.Lang.String) {
                    try {
                        pref = pref.toNumber();
                    } catch(ex) {
                        pref = null;
                    }
                }
            }
        }

        // Run checks
        if (pref == null || pref < min || pref > max) {
            pref = def;
            app.setProperty(name, pref);
        }

        return pref;
    }

    //! Return the boolean value for the preference
    //! @param name the name of the preference
    //! @param def the default value if preference value cannot be found
    function getBooleanPref(name, def) {
        var app = App.getApp();
        var pref = def;
        
        //System.println("Preference "+name+"");

        if (app != null) {
            pref = app.getProperty(name);

            if (pref != null) {
            	//System.println("Preference "+name+" exist.");
                if (pref instanceof Toybox.Lang.Boolean) {
                	//System.println("Preference value "+pref);
                    return pref;
                }

                if (pref == 1) {
                    return true;
                }
            }
        }

        // Default
        return def;
    }
    
    //! Get activity type preference
    function getActivityType() {
        var type = getNumbericPref(ACTIVITY_TYPE, Recording.SPORT_TRAINING, 0, 100);
        return type;
    }

    //! Get activity sub-type preference
    function getActivitySubType() {
        var subType = getNumbericPref(ACTIVITY_SUB_TYPE, Recording.SUB_SPORT_STRENGTH_TRAINING, 0, 100);
        return subType;
    }
    
    //! Get graph refresh rate preference
    function getGraphRefreshRate() {
        var graphRefreshRate = getNumbericPref(GRPH_REFRSH_RATE, 30, 0, 30);
        return graphRefreshRate;
    }

    //! Return boolean of vibration setting preference
    function getAllowVibration() {
        var value = getBooleanPref(ALLOW_VIBRATION, true);
        return value;
    }
    
    /*
    function getAskActivity(){
        var value = getBooleanPref(ASK_ACTIVITY, true);
        return value;
    }*/

	/*
    //! Return boolean of HR Stability setting preference
    function getHRStability() {
        var value = getBooleanPref(ALLOW_HRSTABILITY, true);
        return value;
    }*/
    
    //! Return boolean of GPS setting preference
    function getGPSTracking() {
        var value = getBooleanPref(ALLOW_GPSTRACKING, false);
        return value;
    }
    
    //! Return boolean of DarkMode setting preference
    function getDarkModeSetting() {
        var value = getBooleanPref(ALLOW_DARKMODE, false);
        return value;
    }
    
    //! Return boolean of BattTemp setting preference
    function getBattTempSetting() {
        var value = getBooleanPref(ALLOW_BATTTEMP, false);
        return value;
    }
}

//! This handles input while the progress bar is up
class ProgressDelegate extends Ui.BehaviorDelegate {

    //! Constructor
    function initialize() {
        BehaviorDelegate.initialize();
    }

    //! Block the back button handling while the progress bar is up.
    function onBack() {
        return true;
    }

}

class StartConfirmationDelegate extends Ui.ConfirmationDelegate {

    hidden var mController;

    function initialize() {
        ConfirmationDelegate.initialize();
        mController = Application.getApp().controller;
    } 
    
    function onResponse(value) {
        if (value == Ui.CONFIRM_YES) {
        	mController.WorkoutUIState = mController.UISTATE_WAITINGFORHR; 
        	Ui.popView(Ui.SLIDE_DOWN);
        } else {
        	//Ui.popView(Ui.SLIDE_DOWN);
        	//Ui.popView(Ui.SLIDE_DOWN);
        	//System.exit();
        	//mController.WorkoutUIState = mController.UISTATE_EXITONBACK;
        	//System.println("ConfirmationDelegate Cancel: "+mController.WorkoutUIState);
        	
        }
    }

}
