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
        //mController.WorkoutUIState = mController.UISTATE_WAITINGFORHR;
    }
    
    function getMoreMenu(){
    
    	var isDarkModeOn =  mController.getDarkModeSetting();
		var showBattTempFields =  mController.getBattTempSetting();
        var allowVib = mController.getAllowVibration(); 
        var graphRefreshRate = mController.getGraphRefreshRate();
    
		var menu = new Ui.Menu();
        menu.setTitle("Options:");
        menu.addItem("Graph Refresh " + graphRefreshRate + "s",:RefRate);
        menu.addItem("Vibration "+(allowVib?"[On] Off":"On [Off]"), :AllowVibration);
		//menu.addItem("Dark Mode "+(isDarkModeOn?"[On] Off":"On [Off]"),:DarkMode);
		var hasTemp = (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory);
		menu.addItem((hasTemp ? "Batt/Temp " : "Battery ") + (showBattTempFields?"[On] Off":"On [Off]"),:BattTemp);
		
		return menu;
    
    }
    
    function getActMenu(){
    	var actMenu = new Ui.Menu();
		actMenu.setTitle("Activities");
		for(var i =0; i< mController.mActivities.size(); ++i){
			var actMenuIDArray = mController.mActivities[i];
			actMenu.addItem(mController.mActivitiesStr[i], actMenuIDArray[2]);
		}
		return actMenu;
    }
    
    function getGraphRefreshRateMenu(){
    	var rateMenu = new Ui.Menu();
		rateMenu.setTitle("Refresh Rate");
		for(var i =0; i< mController.mRefRate.size(); ++i){
			var itemArray = mController.mRefRate[i];
			rateMenu.addItem(itemArray[0], itemArray[1]); //refresh rate name, symbol
		}
		return rateMenu;
    }
    
    /*
	function getWaitingForHRMenu() {
    	
    	var selectedActivityStr = mController.getActivityString(); 
    	
    	var menu = new Ui.Menu();
        menu.setTitle(selectedActivityStr);
        menu.addItem("Start",:Start);
        menu.addItem("Change Activity", :ActivityType);
		menu.addItem("More...",:More);
		
		
		return menu;
    }*/
    
    function getStartWorkoutMenu() {
    	
    	var selectedActivityStr = mController.getActivityString(); 
    	
    	var menu = new Ui.Menu();
        menu.setTitle(selectedActivityStr);
        menu.addItem("Start",:Start);
        menu.addItem("Change Activity", :ActivityType);
		menu.addItem("Options",:More);
		menu.addItem("Exit",:Exit);
		
		return menu;
    }
    
   function getRunningWorkoutMenu() {
    	
    	var selectedActivityStr = mController.getActivityString(); 
    	
    	var menu = new Ui.Menu();
        menu.setTitle(selectedActivityStr);
	    menu.addItem("Resume", 	:resume);
	    menu.addItem("Save", 	:save);
		menu.addItem("Options...", :More);
		menu.addItem("Discard & Exit", :discard);   
		
		return menu;
    }
    
    function refreshMoreMenu(){
    	//Ui.popView(Ui.SLIDE_DOWN);
    	Ui.popView(Ui.SLIDE_DOWN);
    	Ui.pushView(getMoreMenu(), new IHMenuDelegate(), Ui.SLIDE_UP);
    }

    function onMenuItem(item) {
    
    	//Start Workout
        if (item == :Start) {
            mController.confirmStart();
            return true;
        }
        
        //Resume Workout
        if (item == :resume) {
            mController.resumeWorkout();
        	return true;
        }

        //Save Workout            
        if (item == :save) {
            Ui.pushView(new Ui.Confirmation("Save & End?"), new SaveConfirmationDelegate(), Ui.SLIDE_UP );
        	return true;
        }
            
        //Discard Workout            
        if (item == :discard) {
            Ui.pushView(new Ui.Confirmation("Discard & Exit?"), new DiscardConfirmationDelegate(), Ui.SLIDE_UP );
        	return true;
        }
    
    	//Create Options menu
        if (item == :More) {
            Ui.pushView(getMoreMenu(), new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }
        
        //Exit Action
        if(item == :Exit){
        	mController.onExit();
        }
    
        //Create Activities Menu
        if (item == :ActivityType) {
        	//Ui.popView(Ui.SLIDE_DOWN);
            Ui.pushView(getActMenu(), new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }
        
        //Create Vibration Menu
        if (item == :AllowVibration) {

        	var allowVib = mController.getAllowVibration();
            App.getApp().setProperty(mController.ALLOW_VIBRATION, !allowVib); 
            refreshMoreMenu();
            /*
	       	var menu = new Ui.Menu();
	        menu.addItem("Vibration On", :VibrationOn);
	        menu.addItem("Vibration Off", :VibrationOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);*/
            return true;
        }
        
        //Create Dark Mode Menu
        if (item == :DarkMode) {
        
        	        
            var isDarkModeOn =  mController.getDarkModeSetting();
            App.getApp().setProperty(mController.ALLOW_DARKMODE, !isDarkModeOn); 
        	refreshMoreMenu();
        	
	       	/*var menu = new Ui.Menu();
	        menu.addItem("Dark Mode On", 	:DarkModeOn);
	        menu.addItem("Dark Mode Off", 	:DarkModeOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);*/
            return true;
        }
        
        //Create Batt/Temp Menu
        if (item == :BattTemp) {
        
        	var showBattTempFields =  mController.getBattTempSetting();
        	App.getApp().setProperty(mController.ALLOW_BATTTEMP, !showBattTempFields); 
        	refreshMoreMenu();
	       	/*var menu = new Ui.Menu();
	        menu.addItem("Batt/Temp On", 	:BattTempOn);
	        menu.addItem("Batt/Temp Off", 	:BattTempOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);*/
            return true;
        }
        
        //Create Graph Refresh Rate menu
        if (item == :RefRate) {
            Ui.pushView(getGraphRefreshRateMenu(), new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }
        
        //Graph Refresh Rate
        for(var i =0; i< mController.mRefRate.size(); ++i){
			var itemArray = mController.mRefRate[i];
			if(item == itemArray[1]){
			    App.getApp().setProperty(mController.GRPH_REFRSH_RATE, itemArray[2]); 
        		Ui.popView(Ui.SLIDE_DOWN);
        		refreshMoreMenu();
            	return true;
			}
		}
        
        //Create AskActivity Menu
        /*
        if (item == :AskActivity) {
	       	var menu = new Ui.Menu();
	        menu.addItem("Always Ask", 	:AskActivityOn);
	        menu.addItem("Use Last One", :AskActivityOff);
            Ui.pushView(menu, new IHMenuDelegate(), Ui.SLIDE_UP);
            return true;
        }*/
        
        // Allow Vibration Sub Menu Options
        /*
        if (item == :VibrationOn) {
            App.getApp().setProperty(mController.ALLOW_VIBRATION, true); 
            refreshMoreMenu();
            return true;
        }
        if (item == :VibrationOff) {
            App.getApp().setProperty(mController.ALLOW_VIBRATION, false);
            refreshMoreMenu();
            return true;
        }*/
        
        // Allow DarkMode Sub Menu Options
        /*
        if (item == :DarkModeOn) {
            App.getApp().setProperty(mController.ALLOW_DARKMODE, true); 
            refreshMoreMenu();
            return true;
        }
        if (item == :DarkModeOff) {
            App.getApp().setProperty(mController.ALLOW_DARKMODE, false);
            refreshMoreMenu();
            return true;
        }*/
        
        // Allow Batt/Temp Sub Menu Options
        /*
        if (item == :BattTempOn) {
            App.getApp().setProperty(mController.ALLOW_BATTTEMP, true); 
            refreshMoreMenu();
            return true;
        }
        if (item == :BattTempOff) {
            App.getApp().setProperty(mController.ALLOW_BATTTEMP, false);
            refreshMoreMenu();
            return true;
        }*/

		//Ask for Activity at Launck Options
		/*
        if (item == :AskActivityOn) {
            App.getApp().setProperty(mController.ASK_ACTIVITY, true); 
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        if (item == :AskActivityOff) {
            App.getApp().setProperty(mController.ASK_ACTIVITY, false);
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }*/
        
		//Activities Sub Menu Options
		for(var i =0; i< mController.mActivities.size(); ++i){
			var actMenuIDArray = mController.mActivities[i];
			if (item == actMenuIDArray[2]) {
			
	            App.getApp().setProperty(mController.ACTIVITY_TYPE, actMenuIDArray[0]);
	            App.getApp().setProperty(mController.ACTIVITY_SUB_TYPE, actMenuIDArray[1]);
	            //Make sure we can refresh Start Main Menu, after the Activity is changed
	            mController.WorkoutUIState = mController.UISTATE_WAITINGTOSTART; 
	            Ui.popView(Ui.SLIDE_DOWN);
	            
	            if(actMenuIDArray[3] ==  mController.GPSCapable){ //If GPS Capable Activity, confirm torning ON GPS
	            	Ui.pushView(new Ui.Confirmation("GPS tracking?"), new GPSConfirmationDelegate(), Ui.SLIDE_UP );
	            	return true;
	            } else {  //GPS is not an option
	            	App.getApp().setProperty(mController.ALLOW_GPSTRACKING, false);
	            	return true;
	            }
	            
	            return true;
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

class DiscardConfirmationDelegate extends Ui.ConfirmationDelegate {

    hidden var mController;

    function initialize() {
        ConfirmationDelegate.initialize();
        // Get the controller from the application class
        mController = Application.getApp().controller;
    }

    function onResponse(value) {
        if (value == Ui.CONFIRM_YES) {
            mController.discard();
        } 
    }

}

class SaveConfirmationDelegate extends Ui.ConfirmationDelegate {

    hidden var mController;

    function initialize() {
        ConfirmationDelegate.initialize();
        // Get the controller from the application class
        mController = Application.getApp().controller;
    }

    function onResponse(value) {
        if (value == Ui.CONFIRM_YES) {
             mController.save();
        } 
    }

}