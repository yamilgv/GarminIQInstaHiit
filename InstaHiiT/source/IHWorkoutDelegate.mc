//! Delegates inputs to the controller

using Toybox.WatchUi as Ui;

class IHWorkoutDelegate extends Ui.BehaviorDelegate {

    hidden var mController;

    //! Constructor
    function initialize() {
        // Initialize the superclass
        BehaviorDelegate.initialize();
        // Get the controller from the application class
        mController = Application.getApp().controller;
    }

    //! Back button pressed
    function onBack() {
        
        // Exit App on back press if Workout not running
        if(mController.WorkoutUIState != mController.UISTATE_RUNNING){
        	mController.onExit();}
        	
        return true;
    }

    //! Menu button pressed / VivoActive3 LongPress
    function onMenu() {
    
     	System.println("Menu Pressed.");
    
        // Treat the Menu button like the Secondary Timer Toggle button during workout 
        if(mController.WorkoutUIState == mController.UISTATE_RUNNING) {
        	mController.vibrate(0);
        	//mController.restartSecondaryTimer();
        	mController.toggleSecondaryTimer();
        	return true;
        }
        
        //Show Settings by Menu button on Confirmed State
        if(mController.WorkoutUIState == mController.UISTATE_READYTOSTART || mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR) { 
        
        	Ui.pushView(IHMenuDelegate.getIHMenu(), new IHMenuDelegate(), Ui.SLIDE_UP);
        	return true;
        }
        return true;
    }

    //! Main Button Pressed
    function onKey(key) {
    	 // Treat the Main button like the Stop button during workout else start the workout for the first time
    	 
    	//System.println("On Key "+key.getKey());
    	 
        if (key.getKey() == Ui.KEY_ENTER) {
        
        	if(mController.WorkoutUIState == mController.UISTATE_WORKOUTEND){
	        	mController.onExit();
	        	return true;
        	}
        
         	if(mController.WorkoutUIState == mController.UISTATE_RUNNING){
         		mController.stopWorkout();
         		Ui.pushView(IHMenuDelegate.getRunningWorkoutMenu(), new IHMenuDelegate(), WatchUi.SLIDE_UP);
           		//mController.onStartStop();
           	}
            else {
             	//mController.confirmStart(); 
             	Ui.pushView(IHMenuDelegate.getStartWorkoutMenu(), new IHMenuDelegate(), Ui.SLIDE_UP);   	
             	} 
            return true;
        }
        
       //if (key.getKey() == Ui.KEY_MENU) {
		//	System.println("Menu Pressed.");
       // }
        
        //Toggle HR Color Zones Mode Text
		if(key.getKey() == Ui.KEY_UP || key.getKey() == Ui.KEY_DOWN){
			if(mController.WorkoutUIState == mController.UISTATE_RUNNING){
				//Toggle Mode
				mController.hrZoneMode = mController.hrZoneMode==1?2:1; 
				//mController.vibrate(0);
			}
		}
    	
        return true;
    }

    //! Screen Tap
    function onTap(type) {
        if (type.getType() == Ui.CLICK_TYPE_TAP) {
            //mController.turnOnBacklight();
        }
    }
    
        //! Screen Tap
    function onHold(type) {
        if (type.getType() == Ui.CLICK_TYPE_RELEASE) {
            //mController.turnOnBacklight();
        }
    }
    
    function onSwipe(swipeEvent) {
    	
    	//Toggle HR Color Zones Mode Text
		if(swipeEvent.getDirection() == Ui.SWIPE_DOWN || swipeEvent.getDirection() == Ui.SWIPE_UP) {
			if(mController.WorkoutUIState == mController.UISTATE_RUNNING){
				//Toggle Mode
				mController.hrZoneMode = mController.hrZoneMode==1?2:1; 
				mController.forceOnUpdate = true;
				//mController.vibrate(0);
			}
		}
		
        //System.println(swipeEvent.getDirection()); // e.g. SWIPE_RIGHT = 1
    }

}