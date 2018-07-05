using Toybox.Application as App;
using Toybox.WatchUi as Ui;

//! Application menu delegate
class IHMenuDelegate extends Ui.MenuInputDelegate {

	var mController;

    function initialize() {
        MenuInputDelegate.initialize();
         mController = Application.getApp().controller;
         //unconfirm execution after Settings Menu is shown, 
         //this way make the Workout does not start on OnShown in IHWorkoutView automatically
         //but shows the 'Press Start' popup to the user
        mController.WorkoutUIState = mController.UISTATE_WAITINGFORHR;
    }
    
    function getIHMenu(){
    
		var menu = new Ui.Menu();
        //menu.setTitle("Settings:");
        menu.addItem("Activity Type", :ActivityType);
        menu.addItem("Vibration", :AllowVibration);
		//menu.addItem("HR Stabilizer",:HRStability);
		menu.addItem("Dark Mode",:DarkMode);
		menu.addItem("Batt/Temp",:BattTemp);
		
		return menu;
    
    }

    function onMenuItem(item) {
    
        //Create Activities Menu
        if (item == :ActivityType) {
        
        	var actMenu = new Ui.Menu();
        	//actMenu.setTitle("Activities:");
        	for(var i =0; i< mController.mActivities.size(); ++i){
        		var actMenuIDArray = mController.mActivities[i];
				actMenu.addItem(mController.mActivitiesStr[i], actMenuIDArray[2]);
			}
			
            Ui.pushView(actMenu, new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }
        
        //Create Vibration Menu
        if (item == :AllowVibration) {
        
	       	var menu = new Ui.Menu();
	        menu.addItem("Vibration On", :VibrationOn);
	        menu.addItem("Vibration Off", :VibrationOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }
        
        //Create Dark Mode Menu
        if (item == :DarkMode) {
        
	       	var menu = new Ui.Menu();
	        menu.addItem("Dark Mode On", 	:DarkModeOn);
	        menu.addItem("Dark Mode Off", 	:DarkModeOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }
        
        //Create Batt/Temp Menu
        if (item == :BattTemp) {
        
	       	var menu = new Ui.Menu();
	        menu.addItem("Batt/Temp On", 	:BattTempOn);
	        menu.addItem("Batt/Temp Off", 	:BattTempOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }
        
        //Create Stability Menu
        /*
        if (item == :HRStability) {
        	var menu = new Ui.Menu();
	        menu.addItem("HR Stabilizer On", :HRStabilityOn);
	        menu.addItem("HR Stabilizer Off", :HRStabilityOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }*/
        
        // Allow Vibration Sub Menu Options
        if (item == :VibrationOn) {
            App.getApp().setProperty(mController.ALLOW_VIBRATION, true); 
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        if (item == :VibrationOff) {
            App.getApp().setProperty(mController.ALLOW_VIBRATION, false);
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        
        // Allow DarkMode Sub Menu Options
        if (item == :DarkModeOn) {
            App.getApp().setProperty(mController.ALLOW_DARKMODE, true); 
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        if (item == :DarkModeOff) {
            App.getApp().setProperty(mController.ALLOW_DARKMODE, false);
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        
        // Allow Batt/Temp Sub Menu Options
        if (item == :BattTempOn) {
            App.getApp().setProperty(mController.ALLOW_BATTTEMP, true); 
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        if (item == :BattTempOff) {
            App.getApp().setProperty(mController.ALLOW_BATTTEMP, false);
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }

        // HR Stabilizer Sub Menu Options
        /*
        if (item == :HRStabilityOn) {
            App.getApp().setProperty(mController.ALLOW_HRSTABILITY, true);
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        if (item == :HRStabilityOff) {
            App.getApp().setProperty(mController.ALLOW_HRSTABILITY, false);
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }*/
        

		//Activities Sub Menu Options
		for(var i =0; i< mController.mActivities.size(); ++i){
			var actMenuIDArray = mController.mActivities[i];
			if (item == actMenuIDArray[2]) {
	            //Prefs.setActivityType(actMenuIDArray[0]);
	            App.getApp().setProperty(mController.ACTIVITY_TYPE, actMenuIDArray[0]);
	            //Prefs.setActivitySubType(actMenuIDArray[1]);
	            App.getApp().setProperty(mController.ACTIVITY_SUB_TYPE, actMenuIDArray[1]);
	            
	            if(actMenuIDArray[3] ==  mController.GPSCapable){ //If GPS Capable Activity, confirm torning ON GPS
	            	Ui.popView(Ui.SLIDE_DOWN);
	            	Ui.pushView(new Ui.Confirmation("Enable\nGPS tracking?"), new GPSConfirmationDelegate(), Ui.SLIDE_UP );
	            	return true;
	            } else {  //GPS is not an option
	            	App.getApp().setProperty(mController.ALLOW_GPSTRACKING, false);
	            	Ui.popView(Ui.SLIDE_DOWN);
	            	return true;
	            }
	            
        	}
		}
		

        return false;
    }

}

class GPSConfirmationDelegate extends Ui.ConfirmationDelegate {

    hidden var mController;

    function initialize() {
        ConfirmationDelegate.initialize();
        // Get the controller from the application class
        mController = Application.getApp().controller;
    }

    function onResponse(value) {
        if (value == Ui.CONFIRM_YES) {
             App.getApp().setProperty(mController.ALLOW_GPSTRACKING, true);
        } else {
        	 App.getApp().setProperty(mController.ALLOW_GPSTRACKING, false);
        }
        
        Ui.popView(Ui.SLIDE_DOWN);
    }

}