//! View during workout

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System as System;
using Toybox.Timer;
using Toybox.Time;
using Toybox.UserProfile;
using Toybox.SensorHistory as Sensor;
using Toybox.Math;

class IHWorkoutView extends Ui.View {

    hidden var mModel;
    hidden var mController;
    hidden var mTimer;

    //! UI Variables
    hidden var uiBlinkToggle = true; //Toggle between true/false on timer to make blinking effect
    hidden var uiHRZoneValue;
 
    //hidden var uiHRZoneColor;
    //hidden var uiColorsArray;

    hidden var prevZone;
    hidden var vibeTime;
    //hidden var selectedActivityStr;
    hidden var maxHR;
    hidden var currTemperature;
    hidden var currCharge;
    //hidden var isDarkModeOn;
	hidden var showBattTempFields;	
	hidden var showGPS;
	hidden var timerFont;
	hidden var graphRefreshRate;
    
    //Graph Constants
    hidden var heartMin = 1000;
	hidden var heartMax = 0;
	//hidden var maxSecs; // = graphLength * 60;
	hidden var tickInterval = 15; //In Minutes
	hidden var totHeight = 45; //Graph Height
	hidden var totWidth = 210; //Graph Width
	hidden var binPixels = 1; //Bin (Column) Width
	hidden var totBins = Math.ceil(totWidth / binPixels).toNumber(); //Count of Bins or Columns
	hidden var xValConst;
	hidden var yVal;
	
	//Coordinates Constants
	hidden var baseDimension = 240; //All drawings coordinates baseline (VivoActive3 240x240)
	hidden var baseFactor = 1.0;   //Device Height	
	hidden var devWidth; //Device Width
	hidden var devHeight; //Device Height
	hidden var devXCenter; //Device X Center
	hidden var devYCenter; //Device Y Center
	
	//var simulateHRArray;
	
	//var hrZoneModeChanged = false;
	
	hidden var graphLayer; 

    function initialize() {
        View.initialize();
        
        // Start timer used to push UI updates
        mTimer = new Timer.Timer();
        
        // Get the model and controller from the Application
        mModel = Application.getApp().model;
        mController = Application.getApp().controller;
        
        //Convert tickIntervals to seconds
        tickInterval = tickInterval * 60; 

		//Get Default HR Zones from user profiles
		uiHRZoneValue = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC); 
		
        prevZone = 0;
        vibeTime = 0;
        currTemperature = 0;
        currCharge = 0;
        
       
    }

    //! Load your resources here
    function onLayout(dc) {
    
    	System.println("onLayout");
    	
    	baseFactor = dc.getWidth().toDouble()/baseDimension.toDouble();  
    	
    	timerFont = dc.getWidth() <= 220 ? mController.FONTTINY : mController.FONTSMALL; 
    	
        // Load the layout from the resource file
        //setLayout(Rez.Layouts.PrimaryWorkoutScreen(dc));
        totHeight = 45*baseFactor; //Graph Height
		totWidth = 210*baseFactor; //Graph Width
		totBins = Math.ceil(totWidth / binPixels).toNumber(); //Count of Bins or Columns
		
        //Initialize Screen Dimension Variabbles with dc (Display Context)
        devWidth = dc.getWidth();
		devHeight = dc.getHeight();
		devXCenter = devWidth/2; 
		devYCenter = devHeight/2; 
		//System.println("Screen Dimensions: " + devWidth + "x" + devHeight + " baseDimension "+ baseDimension + " factor " + baseFactor);
		
		//Initialize Graph Position Constants
		xValConst = (devWidth-totWidth)/2 + totWidth;
		yVal = 4;//devHeight/2 + 8*baseFactor;
		
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    
    System.println("onShow");
    
        //System.println("onShow Received State: "+mController.WorkoutUIState);
        
       	//If Start has not been pressed
		if(mController.WorkoutUIState == mController.UISTATE_WAITINGTOSTART) {
		    //System.println("UISTATE_WAITINGTOSTART");
		    //mController.WorkoutUIState = mController.UISTATE_EXITONBACK;
			Ui.pushView(IHMenuDelegate.getStartWorkoutMenu(), new IHMenuDelegate(), Ui.SLIDE_UP);
			return;
		}
		
		//If Back was pressed on the Main Start Menu, Exit the app
		/*if(mController.WorkoutUIState == mController.UISTATE_EXITONBACK) {
			//Ui.popView(Ui.SLIDE_DOWN);
			System.println("System Exit:");
			System.exit();
			System.exit();
			return;
		}*/
		
		mTimer.start(method(:onTimer), 1000, true);
        
        // If we come back to this view via back button from Resume option
        //if (!mController.isRunning()  && mController.resume == true) {
        if(mController.WorkoutUIState == mController.UISTATE_STOPPED){
            mController.resumeWorkout();
        }
        
        //Get Settings only when OnShow is called
		//isDarkModeOn =  mController.getDarkModeSetting();
		showBattTempFields =  mController.getBattTempSetting();
		showGPS = mModel.isGPSOn();
		graphRefreshRate = mController.getGraphRefreshRate();
        //selectedActivityStr = mController.getActivityString(); //Get Activity String 
        
        maxHR = mModel.getMaxHRbpm();
        
        //Initialize UI Colors
        //MainBkgrdColor, TopDowmBrgrdColor, ValueColor, LabelColor, TopDownValueColor, BattTempValues
        
        /*if(isDarkModeOn  == false){
        	//White Mode no longer supported
        	uiColorsArray = [Gfx.COLOR_WHITE, Gfx.COLOR_BLACK, Gfx.COLOR_BLACK, Gfx.COLOR_DK_GRAY, Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY];
        	uiHRZoneColor = [Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_BLUE, Gfx.COLOR_DK_GREEN, Gfx.COLOR_ORANGE, Gfx.COLOR_RED];
        }
        else {*/
        //Dark Mode Default
     	//uiColorsArray = [Gfx.COLOR_BLACK, Gfx.COLOR_BLACK, Gfx.COLOR_WHITE, Gfx.COLOR_LT_GRAY, Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY];
     	//uiHRZoneColor = [Gfx.COLOR_DK_GRAY, Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN, Gfx.COLOR_YELLOW, Gfx.COLOR_RED];
        //}
        
        
        mController.forceOnUpdate = true;
    
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
        mTimer.stop();
    }

    //! Update the view
    function onUpdate(dc) {
    
    	//testFonts(dc); return;
    
		var timer = mModel.getTimeElapsed(); //Seconds
		
		
		//If Start has not been pressed, do nothing
		if(mController.WorkoutUIState == mController.UISTATE_WAITINGTOSTART) {
			return;
		}
		

		/*
		//Draw a color in the bckground
		//Draw a bigmap that has a transparent circle
		dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_DK_GRAY);
		dc.fillRectangle(0, 123*baseFactor, devWidth, totHeight); 
		var gl = new Gfx.BufferedBitmap({:width=>devWidth, :height=>totHeight});		
		var gldc = gl.getDc();
		gldc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_DK_GRAY);
		//gldc.fillRectangle(0, 0, devWidth, totHeight); 
		gldc.setColor(Gfx.COLOR_RED, Gfx.COLOR_DK_GRAY);
		gldc.fillCircle(devWidth/2, totHeight/2, 50);
		dc.drawBitmap(0, 123*baseFactor, gl);
		*/
		
		//Do not update anything else but timers to smooth UI update and reduce drawing glitches
		//if(mController.WorkoutUIState == mController.UISTATE_RUNNING && ((timer-10) % 60) == 0 || timer == 1) {
		//	graphLayer = plotHRgraph(dc,timer);
			//drawTimers(dc, timer);
			//if(showBattTempFields == true) {drawSlowUpdatingFields(dc, timer);}//Draw Batt and Temperature 	
			//return;
		//}
		
		//graphLayer = plotHRgraph(dc,timer); 
		
		//Clean All Screen
		//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
		//dc.clear();
		
		//Testing HardCode Values for IQ Store Screenshoots
		//COMMENT TO DISABLE
		//drawTestValues(dc, timer);
		//dc.drawBitmap(0, 123*baseFactor, plotTestHRgraph(dc,0));//force timer=0 to keep forcing re-drawing graph
		drawMyLayers(dc);
		return;
		 
		
		//Workout Running and End Screen Common Drawing
		if(mController.WorkoutUIState == mController.UISTATE_RUNNING || mController.WorkoutUIState == mController.UISTATE_WORKOUTEND) {
		
			//Get heart rate graph 1st second or when forced to update UI or
			//Get heart rate graph every 60 seconds, at the 10 seconds of the minute
			if(mController.forceOnUpdate || timer == 1 || ((timer) % graphRefreshRate) == 0) {
				//System.println("graphRefreshRate: "+ graphRefreshRate);
				graphLayer = plotHRgraph(timer); 
			}
		
			dc.drawBitmap(0, 123*baseFactor, graphLayer);
			//dc.drawBitmap(0, 0, plotHRgraph(dc,timer));
		
			//Clean Top Header Area
			//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			//dc.fillRectangle(0, 0, devWidth, 32*baseFactor); 
	
			//Clear HR Fields Area
			//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			//dc.fillRectangle(0, 32*baseFactor, devWidth, 92*baseFactor); 

			drawTimers(dc, timer);

			//Draw Labels
			dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);	
	    	dc.drawText(53*baseFactor, 30*baseFactor,  mController.FONTXTINY, "Max", Graphics.TEXT_JUSTIFY_CENTER);
	    	dc.drawText(190*baseFactor, 30*baseFactor, mController.FONTXTINY, (mController.hrZoneMode == 1 ? "Avg" : "IMin"), Graphics.TEXT_JUSTIFY_CENTER);
	    	dc.drawText(38*baseFactor, 73*baseFactor,  mController.FONTXTINY, "Kcal",  Graphics.TEXT_JUSTIFY_CENTER); 
	    	dc.drawText(devXCenter, 29*baseFactor, mController.FONTXTINY, "Peak", Graphics.TEXT_JUSTIFY_CENTER); 
       		if(showGPS) {dc.drawText(70*baseFactor, 12*baseFactor, mController.FONTXXXTINY, "GPS", Graphics.TEXT_JUSTIFY_CENTER);} //Draw GPS string if enabled
    
			//Draw IMin, Kcal and MakHR
			dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
	        dc.drawText(190*baseFactor, 47*baseFactor, mController.FONTTINY, (mController.hrZoneMode == 1 ? mModel.getAvgHRbpm() : mModel.getIntesityMinutes()), Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(54*baseFactor, 47*baseFactor, mController.FONTTINY, maxHR, Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(36*baseFactor, 90*baseFactor, mController.FONTSMALL, mModel.getCalories(), Graphics.TEXT_JUSTIFY_CENTER);
		
			//Peak HR and Percent
			var peakHR = mModel.getPeakHR();	
			var peakHRCombo = peakHR+" "+mModel.getPeakHRpct(); //Peak HR and Peak HR Pecent concatenated 
			var percSymOffset = dc.getTextWidthInPixels(peakHRCombo, mController.FONTSMALL)/2;
        	dc.setColor(mModel.getHRZoneColor(peakHR), Graphics.COLOR_TRANSPARENT);
        	dc.drawText(devXCenter, 44*baseFactor, mController.FONTSMALL, peakHRCombo, Graphics.TEXT_JUSTIFY_CENTER); //Peak HR and Peak HR Pecent concatenated 
		    dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		    dc.drawText(devXCenter+percSymOffset+5, 44*baseFactor, mController.FONTXXXTINY, "%", Graphics.TEXT_JUSTIFY_CENTER); //Percentage Symbol 
		    
		    //Plot heart rate graph 1st second or when forced to update UI
			//if(mController.forceOnUpdate || timer == 1) { plotHRgraph(dc, timer);}
		    
		}
		
		//Workout Running Only Drawings Screen
		if(mController.WorkoutUIState == mController.UISTATE_RUNNING) {
		
			//Draw Batt and Temperature
			if(showBattTempFields == true) {drawSlowUpdatingFields(dc, timer);}	
			
	    	//Draw Time
	    	dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(devXCenter, 1*baseFactor, mController.FONTSMALL, getTimeString(), Graphics.TEXT_JUSTIFY_CENTER); 

            //Get current HeartRate and Percent
       		var heartRate = mModel.getHRbpm();
            var curZone = mModel.getHRZoneColorIndex(heartRate);
	        dc.setColor(mModel.getHRZoneColor(heartRate), Graphics.COLOR_TRANSPARENT);
	        dc.drawText(devXCenter, 60*baseFactor, mController.FONTXXLARGE, heartRate, Graphics.TEXT_JUSTIFY_CENTER); //Current HR
	        var currHRRpct = Math.round(( heartRate.toDouble() / maxHR.toDouble() ) * 100).toNumber() + "";
	        dc.drawText(200*baseFactor, 80*baseFactor, mController.FONTLARGE, currHRRpct, Graphics.TEXT_JUSTIFY_CENTER); //Current HR Percent
	        dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
	        dc.drawText(200*baseFactor + (dc.getTextWidthInPixels(currHRRpct, mController.FONTLARGE)/2) + 5, 80*baseFactor, mController.FONTXTINY, "%", Graphics.TEXT_JUSTIFY_CENTER); //Percentage Symbol
	        
	        //Update Max/Min HR till the moment
	        if(heartRate > 0){
	        	if (heartRate > heartMax) { heartMax = heartRate; }
				if (heartRate < heartMin) { heartMin = heartRate; }
			}
			//System.println("Max: " + heartMax + " Min: " + heartMin);
	        
	        //Draw only when coming from OnShow or Every 10 Seconds if showing Minutes in HRZones 
        	//if(mController.forceOnUpdate || hrZoneModeChanged || (((timer) % 10) == 0 && mController.hrZoneMode == 2)) { 
        	drawZonesLegend(dc); 
        	//}

        	mController.forceOnUpdate = false;
	        
	        //Check Zone Change after every 5 seconds to prevent back to back vibration events
	    	if((timer - vibeTime) > 5) {zoneChangeEvents(curZone, timer);}
	    	
	    	return;
        }

       //Workout Done Only Drawings, user can Exit Screen 
       if(mController.WorkoutUIState == mController.UISTATE_WORKOUTEND) {
       
			//Draw Avg Label and Value
			dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);	
	    	dc.drawText(195*baseFactor, 73*baseFactor, mController.FONTXTINY, "Avg", Graphics.TEXT_JUSTIFY_CENTER); //Draw Avg String
	    	dc.setColor(mModel.getHRZoneColor(mModel.getAvgHRbpm()), Graphics.COLOR_TRANSPARENT);	
	        dc.drawText(195*baseFactor, 90*baseFactor, mController.FONTSMALL, mModel.getAvgHRbpm(), Graphics.TEXT_JUSTIFY_CENTER);
	    	
	    	//Draw End of Workout Fields
			dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);	
			dc.drawText(devXCenter, 4*baseFactor, mController.FONTXTINY, "Done", Graphics.TEXT_JUSTIFY_CENTER);
			
			dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);	
			dc.drawText(devXCenter, 70*baseFactor, mController.FONTSMALL, "Workout", Graphics.TEXT_JUSTIFY_CENTER);
			dc.drawText(devXCenter, 95*baseFactor, mController.FONTSMALL, "Saved", Graphics.TEXT_JUSTIFY_CENTER);
			
			mController.hrZoneMode = 2; drawZonesLegend(dc);//Show Minutes in each zone at WorkoutEnd
			
			mTimer.stop(); //Stop Updating UI
			
			return;
		}

		//Waiting for Heart Rate Screen
		if(mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR) {
			
			var heartRate = mModel.getHRbpm();
		
			if (heartRate != 0 && mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR) {
				mController.startWorkout();
				//Vibrate briefly to alert the user we got HR and we are ready to start workout
				if( (Attention has :vibrate) && (System.getDeviceSettings().vibrateOn) && (mController.getAllowVibration() == true)){ 
					mController.vibrate(0);
					//Attention.vibrate([new Attention.VibeProfile(100, 250)]);
				}
				return;
			} 
			
			//Clean Top Header Area
			//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			//dc.fillRectangle(0, 0, devWidth, 32*baseFactor); 
			
			//Draw Time and GPS if needed
	    	dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(devXCenter, 1*baseFactor, mController.FONTSMALL, getTimeString(), Graphics.TEXT_JUSTIFY_CENTER); 
			if(showGPS) {dc.drawText(70*baseFactor, 12*baseFactor, mController.FONTXXXTINY, "GPS", Graphics.TEXT_JUSTIFY_CENTER);} //Draw GPS string if enabled
			
			//Clear HR Fields Area
			//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			//dc.fillRectangle(0, 32*baseFactor, devWidth, 92*baseFactor); 
			
			//Clear and Draw Legends Zone
			drawZonesLegend(dc);

			//Clean and Draw Timers Area
			drawTimers(dc, timer);
			
			//Draw Batt and Temperature
			if(showBattTempFields == true) {drawSlowUpdatingFields(dc, timer);}	
			
			//Clean Graph Background
			//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			//dc.fillRectangle(0, 124*baseFactor-1, devWidth, 50*baseFactor); 
		    
		    //Draw Instructions
		    dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(devXCenter,  35*baseFactor, mController.FONTSMALL, mController.getActivityString(), Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(devXCenter, 130*baseFactor, mController.FONTSMALL, (mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR?(uiBlinkToggle?"Waiting for":"Heart Rate."):(uiBlinkToggle?"Ready for Workout!":"Press Start button.")), Graphics.TEXT_JUSTIFY_CENTER);
	       	//dc.drawText(devXCenter, (devHeight / 3) + 70, mController.FONTXTINY, "Settings:\nLongpress on screen\nor press Menu.", Graphics.TEXT_JUSTIFY_CENTER);
	       	
	       	//Draw Blinking Heart
	       	if(uiBlinkToggle) {dc.drawBitmap(35*baseFactor, 90*baseFactor, Ui.loadResource(Rez.Drawables.hr_red_24));}
	       	
	       	//Draw Current HR
	       	dc.setColor(mModel.getHRZoneColor(heartRate), Graphics.COLOR_TRANSPARENT);
	        dc.drawText(devXCenter, 60*baseFactor, mController.FONTXXLARGE, (mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR?"0" : heartRate), Graphics.TEXT_JUSTIFY_CENTER); //Current HR
	        return; 
        }
				
		//View.onUpdate(dc); //Used if a layout is defined
		
    }
    
    function drawSlowUpdatingFields(dc, timer){
    
    	//Update these fields every minute
    	if((timer % 60) == 0 || currTemperature == 0) {
	        currTemperature = mModel.getTemperature();
	        currCharge = Sys.getSystemStats().battery;
        }
        
        //Set System Fields Color
        dc.setColor(Gfx.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
       
        // Temperature
        dc.drawText(devWidth*0.84, devHeight*0.80, mController.FONTXXTINY, currTemperature, Graphics.TEXT_JUSTIFY_RIGHT); //Draw Temperature String

		//Vertival Battery
        var battX = 42*baseFactor;
        var battY = devHeight*0.81;
        
        //Draw Battery Frame
        dc.drawRectangle(battX, battY, 8, 16);
        dc.fillRectangle(battX + 2, battY - 1, 4, 1);
        
        //Draw Battery Level and Text Color
        dc.setColor(currCharge < 20 ? Gfx.COLOR_DK_RED : Gfx.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var chargeHeight = clamp(1, 12, 12.0 * currCharge / 100.0).toNumber();            
        dc.fillRectangle(battX + 2, clamp(6, 18, 18 - chargeHeight) + battY - 4, 4, chargeHeight); 
        dc.drawText(devWidth*0.22, devHeight*0.80, mController.FONTXXTINY, currCharge.toNumber()>99?99:currCharge.toNumber().format("%02d"), Graphics.TEXT_JUSTIFY_LEFT); //Draw Batt String 
        
    } 
    
    function drawTimers(dc, timer){
    
        //Clean Timer Area for data updated every second
		//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		//dc.fillRectangle(0, 190*baseFactor, devWidth, (devHeight-190)*baseFactor); //Footer Timer Area
    
        //Get Timers Strings    
        var timerString =          Lang.format("$1$:$2$:$3$", [((timer / 60) / 60).format("%2d"), ((timer / 60) % 60).format("%02d"), (timer % 60).format("%02d")]);
        var secondaryTimer = mModel.getSecondaryTimeElapsed();
        var secondaryTimerString = Lang.format("$1$:$2$:$3$", [((secondaryTimer  / 60) / 60).format("%2d"), ((secondaryTimer / 60) % 60).format("%02d"), (secondaryTimer % 60).format("%02d")]);

		//Draw Timers
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(devXCenter, 186*baseFactor, timerFont, timerString, Graphics.TEXT_JUSTIFY_CENTER); //Draw timer 
        dc.drawText(devXCenter, 208*baseFactor, timerFont, secondaryTimerString, Graphics.TEXT_JUSTIFY_CENTER); //Draw secondary timer
		//dc.drawBitmap(63, 200, Ui.loadResource(Rez.Drawables.stopwatch_24)); //Timer Icon
    }
    
    function drawZonesLegend(dc){
    
        //Clean legend Area Bkgd
    	//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT); 
    	//dc.fillRectangle(0, 173*baseFactor, devWidth, 17*baseFactor); 
		
		//Zones Rectangle Colors
		dc.setColor(Gfx.COLOR_RED, Graphics.COLOR_TRANSPARENT); 
		dc.fillRectangle(11*baseFactor, 174*baseFactor, 49*baseFactor, 15*baseFactor); 
		dc.setColor(Gfx.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT); 
		dc.fillRectangle(61*baseFactor, 174*baseFactor, 39*baseFactor, 15*baseFactor);
		dc.setColor(Gfx.COLOR_GREEN, Graphics.COLOR_TRANSPARENT); 
		dc.fillRectangle(101*baseFactor, 174*baseFactor, 39*baseFactor, 15*baseFactor);
		dc.setColor(Gfx.COLOR_BLUE, Graphics.COLOR_TRANSPARENT); 
		dc.fillRectangle(141*baseFactor, 174*baseFactor, 39*baseFactor, 15*baseFactor);
		dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT); 
		dc.fillRectangle(181*baseFactor, 174*baseFactor, 49*baseFactor, 15*baseFactor);
		
		//System.println("Update Zones: " + timer + " "+ mController.hrZoneMode);
		//var hrZoneArray = mController.hrZoneMode == 1? uiHRZoneValue : mModel.getZoneTimes();
		dc.setColor(Gfx.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);  //Legend Text Color
		if(mController.hrZoneMode == 1){
			dc.drawText(41*baseFactor,  170*baseFactor, mController.FONTXXTINY, uiHRZoneValue[4], Graphics.TEXT_JUSTIFY_CENTER); //Zone5 Text
			dc.drawText(81*baseFactor,  170*baseFactor, mController.FONTXXTINY, uiHRZoneValue[3], Graphics.TEXT_JUSTIFY_CENTER); //Zone4 Text
			dc.drawText(devXCenter,     170*baseFactor, mController.FONTXXTINY, uiHRZoneValue[2], Graphics.TEXT_JUSTIFY_CENTER); //Zone3 Text
			dc.drawText(161*baseFactor, 170*baseFactor, mController.FONTXXTINY, uiHRZoneValue[1], Graphics.TEXT_JUSTIFY_CENTER); //Zone2 Text
			dc.drawText(201*baseFactor, 170*baseFactor, mController.FONTXXTINY, uiHRZoneValue[0], Graphics.TEXT_JUSTIFY_CENTER); //Zone1 Text
		} else {
			dc.drawText(41*baseFactor,  170*baseFactor, mController.FONTXXTINY, mModel.mZoneTimes[4]/60, Graphics.TEXT_JUSTIFY_CENTER); //Zone5 Text
			dc.drawText(81*baseFactor,  170*baseFactor, mController.FONTXXTINY, mModel.mZoneTimes[3]/60, Graphics.TEXT_JUSTIFY_CENTER); //Zone4 Text
			dc.drawText(devXCenter,     170*baseFactor, mController.FONTXXTINY, mModel.mZoneTimes[2]/60, Graphics.TEXT_JUSTIFY_CENTER); //Zone3 Text
			dc.drawText(161*baseFactor, 170*baseFactor, mController.FONTXXTINY, mModel.mZoneTimes[1]/60, Graphics.TEXT_JUSTIFY_CENTER); //Zone2 Text
			dc.drawText(201*baseFactor, 170*baseFactor, mController.FONTXXTINY, mModel.mZoneTimes[0]/60, Graphics.TEXT_JUSTIFY_CENTER); //Zone1 Text
		}
		
		//hrZoneModeChanged = false;
    }
    
    //! Handler for the timer callback
    function onTimer() {
    	uiBlinkToggle = uiBlinkToggle? false : true; 
        Ui.requestUpdate();
    }

    function zoneChangeEvents(zone, timer) {

        if (prevZone != zone && prevZone > 0){ 
        
        	if(prevZone < 5 && zone == 5 ){
        		 mController.vibrate(1);} //Red Zone - Long Vibration
        	else if(prevZone < zone){ 
        		mController.vibrate(2);} //Zone Up - Two Vibrations
        	else {
        		mController.vibrate(0);} //Zone Down - One Vibration
        }
        
        vibeTime = timer;
        prevZone = zone;
    }
    
    function getTimeString(){
            
        var time = System.getClockTime();
        var hh   = time.hour;
        var hour = (System.getDeviceSettings().is24Hour) ? hh : (hh == 12 || hh == 0) ? 12 : (hh % 12);
        var timeString = Lang.format("$1$:$2$", [hour.format("%2.2d"),time.min.format("%2.2d")]);
        return timeString;
    }
    
	function plotHRgraph(timer) {
			
		//var gl = new Graphics.BufferedBitmap({:width=>devWidth, :height=>devHeight, :palette=> _palette, :colorDepth=>4} );		
		var gl = new Gfx.BufferedBitmap(
		//var gl = bufferedBitmapFactory(
		{:width=>devWidth, :height=>totHeight+4, :colorDepth=>4, :palette=>
		 [Gfx.COLOR_BLACK, //0 Gr Background
         Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN, Gfx.COLOR_YELLOW, Gfx.COLOR_RED,
         Gfx.COLOR_WHITE] //6 Gr Ticks 
		} );		
		
		//Clean Graph Background
		//gl.getDc().setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(150)],Gfx.COLOR_BLACK);
		var gldc = gl.getDc();
		//var gldc = Gfx has :createBufferedBitmap ? gl.get().getDc() : gl.getDc();
		gldc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
		//gldc.setColor(0, 4);
		
		//gldc.setColor(0, 2);
		gldc.clear();
		//gldc.fillCircle(100, 100, 50);
		//gldc.fillRectangle(0, 124, devWidth, 50); 
		//gldc.fillRectangle(0, 124*baseFactor, devWidth, 50*baseFactor); 
		gldc.fillRectangle(0, 0, devWidth, devHeight); 
				
		if(!(Toybox has :SensorHistory)){ return gl;} //Leave Graph empty if no sensor found
			
		//var curHeartMin = 1000; //0;
		//var curHeartMax = 0;    //0;
	
		//Make sure Graph limits are aceptable
		var maxSecs = timer;
		if (maxSecs < 900) { maxSecs = 900;} // 900sec = 15min
		else if (maxSecs > 14355) { maxSecs = 14355; }  // 14400sec = 4hrs
		var binWidthSecs = Math.floor(binPixels * maxSecs / totWidth).toNumber(); //Amount of time that average a bin	
		var maxSecsDuration = new Time.Duration(maxSecs); 
		var sample = Sensor.getHeartRateHistory( {:duration=>maxSecsDuration,:order=>Sensor.ORDER_NEWEST_FIRST});  //Seems to always return all history
		//System.println("Iterator:" +  sample.getMax() + " " + sample.getMin()); //Always return de whole history Max/min not of the Duration
		//dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		//dc.drawText(devXCenter, 120, mController.FONTXTINY, "iMax: " + sample.getMax() + " iMin: " + sample.getMin(), Graphics.TEXT_JUSTIFY_CENTER); 
								
		//If no HR Iterator was found leave Graph Space empty	
		if (sample == null) {return gl;}
		
		//In the first run, get the maximun and minimun HRs available for the first 15 min
		if(timer == 0) {
			var timeLimit = Time.now().value() - maxSecs; //Previous 15 min
			var stopWhile = false; 
			var fheart = sample.next();
			while (fheart!=null && !stopWhile) {
				if(fheart.data != null) {
					if(fheart.when.value() >= timeLimit){
						if (fheart.data > heartMax) { heartMax = fheart.data; }
						if (fheart.data < heartMin) { heartMin = fheart.data; }
						} 
					else { 
						stopWhile = true;
					}
				}
			fheart = sample.next();
			}
			
		//System.println("Timer Zero Values: heartMax" +  heartMax  + " heartMin " + heartMin); 
		//Reset Iterator to be used in graph drawing
		sample = Sensor.getHeartRateHistory( {:duration=>maxSecsDuration,:order=>Sensor.ORDER_NEWEST_FIRST});

		}
	  	
		
		var curHeartMin = heartMin - 3; //Avoid actual values touch the bottom of the graph making the min artificially three pixels less
		var curHeartMax = heartMax;
		var yDenominator = ((curHeartMax-curHeartMin)) < totHeight?totHeight.toDouble():(curHeartMax-curHeartMin).toDouble(); //If Denominator is less than the total pixels on the graph, use the totHeight to avoid missing pixels while drawing
		
		
		var heartSecs;
		var heartValue = 0;
		var secsBin = 0;
		var lastHeartSecs = sample.getNewestSampleTime().value();
		var heartBinMax;
		var heartBinMin;

		var prevHeartBinMin = 0;
		var prevHeartBinMax = 1000;
		var tempHeartBin = 0;
		var tHeartBinMax = 0;
		var finished = false;
		var prevHeight = 0;
		var height = 0;
		var xVal = 0;
		var dasherCnt = 0;  //used to dash the line of the first minutes not within the workout
		
		//Draw an static arrow at top of graph representing current and end workout time	
		var xIndicator = xValConst; // + (totBins * ((mModel.getTimeElapsed()*1.00)/maxSecs))*binPixels);
		gldc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		//gldc.setColor(6, 8);
		gldc.fillPolygon([[xIndicator-5, (yVal-4)],[xIndicator, (yVal+1)], [xIndicator+5, (yVal-4)]]);
				
		//Calculate dynamic x used to draw dashed lines of out of workout time at the beginning 	
		xIndicator = xValConst - (totBins * ((timer*1.00)/maxSecs)*binPixels);
		if(xIndicator<xValConst-totWidth){xIndicator = xValConst-totWidth;}
		
		//Interval
		if(timer>60){
			var intervalTime  = 60; 
			var xInterval = xValConst - (totWidth*((intervalTime*1.00)/maxSecs));
			gldc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
			gldc.drawRectangle(xInterval, yVal, 1, totHeight);
		}
		
		//Draw arrow at top of graph representing when the workout started
		//dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
		//dc.fillPolygon([[xIndicator-5, (yVal-4)],[xIndicator, (yVal+1)], [xIndicator+5, (yVal-4)]]);
	
		var heart = sample.next();
		for (var i = 0; i < totBins; ++i) {
		
			heartBinMax = 0;
			heartBinMin = 0;
			
			if (!finished)
			{
				//deal with carryover values
				if (secsBin > 0 && heartValue != null)
				{
					heartBinMax = heartValue;
					heartBinMin = heartValue;
				}

				//deal with new values in this bin
				while (!finished && secsBin < binWidthSecs)
				{
					heart = sample.next();
					if (heart == null) { finished = true;}
					else
					{
						heartValue = heart.data;
						if (heartValue != null)
						{
							if (heartBinMax == 0)
							{
								heartBinMax = heartValue;
								heartBinMin = heartValue;
							}
							else
							{
								if (heartValue > heartBinMax)
									{ heartBinMax = heartValue; }
								if (heartValue < heartBinMin)
									{ heartBinMin = heartValue; }
							}
						}

						// keep track of time in this bin
						heartSecs = lastHeartSecs - heart.when.value();
						lastHeartSecs = heart.when.value();
						secsBin += heartSecs;
						//System.println(i + ":   " + heartValue + " " + heartSecs + " " + secsBin + " " + heartBinMin + " " + heartBinMax);
					}

				} // while secsBin < binWidthSecs

				if (secsBin >= binWidthSecs) { secsBin -= binWidthSecs; }
			    xVal = xValConst - i*binPixels;

				//Draw Line in zone color if HR was found
				//System.println(i + " prevHeartBinMin:   " +prevHeartBinMin + " prevHeartBinMax: " + prevHeartBinMax + " " + heartBinMin + " " + heartBinMax);
				//System.println(i + " getMax:   " + sample.getMax() + " getMin: " + sample.getMin());
				if ((heartBinMax > 0 && heartBinMax >= heartBinMin)){
				
					if ((curHeartMax > 0 && curHeartMax > curHeartMin)) {

						prevHeight = 0;
						tHeartBinMax = prevHeartBinMin > heartBinMax? prevHeartBinMin:heartBinMax; 
						tempHeartBin = prevHeartBinMax < heartBinMin? prevHeartBinMax:heartBinMin;
						
						//System.println(i + " timer "+ timer + " heartBinMax: " + heartBinMax + " heartBinMin: " + heartBinMin + " tHeartBinMax: "+tHeartBinMax + " tempHeartBin "+ tempHeartBin + " curHeartMin "+ curHeartMin + " Denominador " + yDenominator );
						
						while(tempHeartBin <= tHeartBinMax) { 
							height = ((tempHeartBin-curHeartMin) / (yDenominator) * totHeight).toNumber();
							if(prevHeight != height){ //Avoid drawing the same dot again
								//System.println(i + " xVal:   " + xVal + " xIndicator: " + xIndicator + " dasherCnt: "+dasherCnt);
								
								//Draw Dash Line for the first minutes of the graph not within the workout time
								if(xVal < xIndicator){
									if(dasherCnt < 3) {
										//gldc.setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(tempHeartBin)], Gfx.COLOR_TRANSPARENT);
										gldc.setColor(mModel.getHRZoneColor(tempHeartBin), Gfx.COLOR_BLACK);
										gldc.drawRectangle(xVal, yVal + totHeight - height, 3, 3);
										//System.println(i + " DotDrwan dasherCnt: "+dasherCnt);
									}
									dasherCnt= dasherCnt>5?0:dasherCnt+1;
								
								//Draw solid line during workout	
								} else {
									//gldc.setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(tempHeartBin)], Gfx.COLOR_TRANSPARENT);
									gldc.setColor(mModel.getHRZoneColor(tempHeartBin),Gfx.COLOR_BLACK);
									//dc.setColor(uiHRZoneColor[getHRTestColour(tempHeartBin)], Gfx.COLOR_TRANSPARENT); 
									gldc.drawRectangle(xVal, yVal + totHeight - height, 3, 3);
									//dc.fillCircle(xVal, yVal + totHeight - height, 1);
								}
							}
							
							tempHeartBin++;
							prevHeight = height;
							
						}//while
						
						prevHeartBinMin = heartBinMin;
						prevHeartBinMax = heartBinMax;
					} 
				}		

			} //if !finished

		} // loop over all bins
		
		//Draw a shadow representing HR measurements out of the workout timeframe	
		//xIndicator = xValConst - (totBins * ((timer*1.00)/maxSecs)*binPixels);
		//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		//for (var i = xValConst-totBins; i < xIndicator; i=i+4) { dc.drawLine(i, yVal, i, yVal+totHeight);} //Vertical Lines
		/*for (var i = yVal; i < yVal+totHeight; i=i+2) {dc.drawLine(xIndicator, i, (xValConst+totBins), i);}*/ //Horizontal Lines
		
		//Draw a short tick on the line representing the desired time interval
		var xTickIndicator; 
		var iOffSet = 0; //timer/tickInterval;
		//System.println("Interval1 Limit "+maxSecs/(tickInterval)+" "+maxSecs+" "+tickInterval);
		for(var i = 0 - iOffSet; i <= (maxSecs/(tickInterval))+iOffSet; i++){
			xTickIndicator =  xValConst - (totBins * ((tickInterval*i*1.00)/maxSecs))*binPixels; //(xIndicator + (totBins * ((tickInterval*i)/maxSecs))*binPixels);
			//System.println(i+" xTickIndicator1 "+xTickIndicator);
			////if(xTickIndicator<xValConst-totWidth){xIndicator = xValConst-totWidth;} //I think is never used because is reseting the wrong variable
			//gldc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
			gldc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			var tickLengh = ((tickInterval*i)%(tickInterval*4)) == 0? 7: ((tickInterval*i)%(tickInterval*2)) == 0? 5 : 3; 
			gldc.fillRectangle(xTickIndicator-1, yVal+totHeight-tickLengh, binPixels*3, tickLengh);
		}
		
		return gl;
			
	}
	
	function bufferedBitmapFactory(options as {
            :width as Number,
            :height as Number,
            :palette as Array<ColorType>,
            :colorDepth as Number}) 
            as BufferedBitmapReference or BufferedBitmap {
	    if (Graphics has :createBufferedBitmap) {
	        return Gfx.createBufferedBitmap(options);
	    } else {
	        return new Gfx.BufferedBitmap(options);
	    }
	}

	function drawTestValues(dc, timer){
	
			timer = 2752;
	
			//Clean Top Header Area
			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			dc.fillRectangle(0, 0, devWidth, 32*baseFactor); 
	
			//Clear HR Fields Area
			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			dc.fillRectangle(0, 32*baseFactor, devWidth, 92*baseFactor); 

			drawTimers(dc, timer);

			//Draw Labels
			dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);	
	    	dc.drawText(53*baseFactor, 30*baseFactor,  mController.FONTXTINY, "Max", Graphics.TEXT_JUSTIFY_CENTER);
	    	dc.drawText(190*baseFactor, 30*baseFactor, mController.FONTXTINY, "IMin", Graphics.TEXT_JUSTIFY_CENTER);
	    	dc.drawText(38*baseFactor, 73*baseFactor,  mController.FONTXTINY, "Kcal",  Graphics.TEXT_JUSTIFY_CENTER); 
	    	dc.drawText(devXCenter, 29*baseFactor, mController.FONTXTINY, "Peak", Graphics.TEXT_JUSTIFY_CENTER); 
       		if(showGPS) {dc.drawText(70*baseFactor, 12*baseFactor, mController.FONTXXXTINY, "GPS", Graphics.TEXT_JUSTIFY_CENTER);} //Draw GPS string if enabled
    
			//Draw IMin, Kcal and MakHR
			dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
	        dc.drawText(190*baseFactor, 47*baseFactor, mController.FONTTINY, 23, Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(54*baseFactor, 47*baseFactor, mController.FONTTINY, maxHR, Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(36*baseFactor, 90*baseFactor, mController.FONTSMALL, 742, Graphics.TEXT_JUSTIFY_CENTER);
		
			//Peak HR and Percent
			var heartRate = 125;
			var peakHR = 172;	
			var peakPct = Math.round(( peakHR.toDouble() / maxHR.toDouble() ) * 100).toNumber();
			var peakHRCombo = 172+" "+ peakPct; //Peak HR and Peak HR Pecent concatenated 
			var percSymOffset = dc.getTextWidthInPixels(peakHRCombo, mController.FONTSMALL)/2;
        	dc.setColor(mModel.getHRZoneColor(peakHR), Graphics.COLOR_TRANSPARENT);
        	dc.drawText(devXCenter, 44*baseFactor, mController.FONTSMALL, peakHRCombo, Graphics.TEXT_JUSTIFY_CENTER); //Peak HR and Peak HR Pecent concatenated 
		    dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		    dc.drawText(devXCenter+percSymOffset+5, 44*baseFactor, mController.FONTXXXTINY, "%", Graphics.TEXT_JUSTIFY_CENTER); //Percentage Symbol 
		    
		    //Draw Batt and Temperature
			if(showBattTempFields == true) {drawSlowUpdatingFields(dc, timer);}	
			
	    	//Draw Time
	    	dc.setColor(Gfx.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(devXCenter, 1*baseFactor, mController.FONTSMALL, getTimeString(), Graphics.TEXT_JUSTIFY_CENTER); 

            //Get current HeartRate and Percent
            var curZone = mModel.getHRZoneColorIndex(heartRate);
	        dc.setColor(mModel.getHRZoneColor(heartRate), Graphics.COLOR_TRANSPARENT);
	        dc.drawText(devXCenter, 60*baseFactor, mController.FONTXXLARGE, heartRate, Graphics.TEXT_JUSTIFY_CENTER); //Current HR
	        var currHRRpct = Math.round(( heartRate.toDouble() / maxHR.toDouble() ) * 100).toNumber() + "";
	        dc.drawText(200*baseFactor, 80*baseFactor, mController.FONTLARGE, currHRRpct, Graphics.TEXT_JUSTIFY_CENTER); //Current HR Percent
	        dc.setColor(Gfx.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
	        dc.drawText(200*baseFactor + (dc.getTextWidthInPixels(currHRRpct, mController.FONTLARGE)/2) + 5, 80*baseFactor, mController.FONTXTINY, "%", Graphics.TEXT_JUSTIFY_CENTER); //Percentage Symbol
	        
	        //Update Max/Min HR till the moment
	        if(heartRate > 0){
	        	if (heartRate > heartMax) { heartMax = heartRate; }
				if (heartRate < heartMin) { heartMin = heartRate; }
			}
			//System.println("Max: " + heartMax + " Min: " + heartMin);
	        
	        //Draw only when coming from OnShow or Every 10 Seconds if showing Minutes in HRZones 
        	if(mController.forceOnUpdate || (((timer) % 10) == 0 && mController.hrZoneMode == 2)) { drawZonesLegend(dc); }

        	//mController.forceOnUpdate = false;
	        
	        //Check Zone Change after every 5 seconds to prevent back to back vibration events
	    	//if((timer - vibeTime) > 5) {zoneChangeEvents(curZone, timer);}
		    
	
	}
	
	function drawMyLayers(dc){

        // draw something on the foreground layer
        dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, 100, 50); 
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);
        //dc.drawText(20, 40, mController.FONTXTINY, "HELLO", Graphics.TEXT_JUSTIFY_CENTER);
        dc.fillRectangle(50, 50, 100, 50);
        

		var gl = new Gfx.BufferedBitmap({:width=>40, :height=>40, 
		//:palette=>[Gfx.COLOR_BLACK,Gfx.COLOR_RED,Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT], 
		:palette=>[Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT], 
		//:colorDepth=>4, 
		:alphaBlending=> 1	
		} );		
		
		//Clean Graph Background
		//gl.getDc().setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(150)],Gfx.COLOR_BLACK);
		var gldc = gl.getDc();
		
		gldc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
		gldc.fillRectangle(0, 0, 40, 40); 
		
		//gldc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
		//gldc.fillRectangle(0, 0, 20, 20); 
		
		gldc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_RED);
		gldc.fillRectangle(10, 10, 20, 20); 
		
		dc.drawBitmap(40,30,gl);
	}

	function plotTestHRgraph(dc, timer) {
	
		//timer = 100;
		var simulateHRArray = getSimulateHRArray(); 
		var simulatedIdx = 0;
		
		var lapArray = [35, 67, 90];

		
		var _palette = [Gfx.COLOR_BLACK, //0 Gr Background
 			Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN, Gfx.COLOR_YELLOW, Gfx.COLOR_RED,
 			Gfx.COLOR_WHITE]; //6 Gr Ticks
			
		//var gl = new Graphics.BufferedBitmap({:width=>devWidth, :height=>devHeight, :palette=> _palette, :colorDepth=>4} );		
		var gl = new Gfx.BufferedBitmap({:width=>devWidth, :height=>totHeight+4, :palette=>_palette, :colorDepth=>4} );		
		
		//Clean Graph Background
		//gl.getDc().setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(150)],Gfx.COLOR_BLACK);
		var gldc = gl.getDc();
		
		gldc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
		gldc.fillRectangle(0, 0, devWidth, devHeight); 
		
		//Clean Graph Background
		//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		//dc.fillRectangle(0, 124*baseFactor, devWidth, 50*baseFactor); 
		
		if(!(Toybox has :SensorHistory)){ return gl;} //Leave Graph empty if no sensor found
			
		//var curHeartMin = 1000; //0;
		//var curHeartMax = 0;    //0;
	
		//Make sure Graph limits are aceptable
		var maxSecs = timer;
		if (maxSecs < 900) { maxSecs = 2700;}//900; }         	// 900sec = 15min
		else if (maxSecs > 14355) { maxSecs = 14355; }  // 14400sec = 4hrs
		var binWidthSecs = Math.floor(binPixels * maxSecs / totWidth).toNumber(); //Amount of time that average a bin	
		var maxSecsDuration = new Time.Duration(maxSecs); 
		var sample = Sensor.getHeartRateHistory( {:duration=>maxSecsDuration,:order=>Sensor.ORDER_NEWEST_FIRST});  //Seems to always return all history
		//System.println("Iterator:" +  sample.getMax() + " " + sample.getMin()); //Always return de whole history Max/min not of the Duration
		//dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		//dc.drawText(devXCenter, 120, mController.FONTXTINY, "iMax: " + sample.getMax() + " iMin: " + sample.getMin(), Graphics.TEXT_JUSTIFY_CENTER); 
								
		//If no HR Iterator was found leave Graph space empty	
		if (sample == null) {return gl;}
		
		//In the first run, get the maximun and minimun HRs available for the first 15 min
		if(timer == 0) {
			var timeLimit = Time.now().value() - maxSecs; //Previous 15 min
			var stopWhile = false; 
			var fheart = sample.next();
			while (fheart!=null && !stopWhile) {
				if(fheart.data != null) {
					if(fheart.when.value() >= timeLimit){
						if (fheart.data > heartMax) { heartMax = fheart.data; }
						if (fheart.data < heartMin) { heartMin = fheart.data; }
					} else {
						stopWhile = true;
					}
				}
			fheart = sample.next();
			}
			//dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
			//dc.drawText(devXCenter, 140, mController.FONTXTINY, "Max: " + heartMax + " Min: " + heartMin, Graphics.TEXT_JUSTIFY_CENTER);
			//System.println("Max: " + heartMax + " Min: " + heartMin);
			//Reset Iterator to be used in graph drawing
			sample = Sensor.getHeartRateHistory( {:duration=>maxSecsDuration,:order=>Sensor.ORDER_NEWEST_FIRST});
			//return;
		}
		
		heartMin = 75;
	    heartMax = 175;
	  	
		
		//var curHeartMin = sample.getMin();
		//var curHeartMax = sample.getMax();
		var curHeartMin = heartMin - 3; //Avoid actual values touch the bottom of the graph making the min artificially three pixels less
		var curHeartMax = heartMax;
		var yDenominator = ((curHeartMax-curHeartMin)) < totHeight?totHeight.toDouble():(curHeartMax-curHeartMin).toDouble(); //If Denominator is less than the total pixels on the graph, use the totHeight to avoid missing pixels while drawing
		
		var heartSecs;
		var heartValue = 0;
		var secsBin = 0;
		var lastHeartSecs = sample.getNewestSampleTime().value();
		var heartBinMax;
		var heartBinMin;

		var prevHeartBinMin = 0;
		var prevHeartBinMax = 1000;
		var tempHeartBin = 0;
		var tHeartBinMax = 0;
		var finished = false;
		var prevHeight = 0;
		var height = 0;
		var xVal = 0;
		var dasherCnt = 0;  //used to dash the line of the first minutes not within the workout
		
		//Draw an static arrow at top of graph representing current and end workout time	
		var xIndicator = xValConst; // + (totBins * ((mModel.getTimeElapsed()*1.00)/maxSecs))*binPixels);
		gldc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		gldc.fillPolygon([[(xIndicator-5), (yVal-4)],[xIndicator, (yVal+1)], [(xIndicator+5), (yVal-4)]]);
		
		//Calculate dynamic x used to draw dashed lines of out of workout time at the beginning 	
		xIndicator = xValConst - (totBins * ((timer*1.00)/maxSecs)*binPixels);
		if(xIndicator<xValConst-totWidth){xIndicator = xValConst-totWidth;}
		
		xIndicator = xValConst-totWidth;
		var intervalTime  = 120; 
		var xInterval = xIndicator + (xValConst-xIndicator)*(1-((intervalTime*1.00)/maxSecs));
		gldc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		gldc.fillRectangle(xInterval, yVal, 1, totHeight);
		//gldc.drawRectangle(xInterval, yVal, 5, totHeight);
		//System.println("xValConst "+ xValConst +  " xIndicator " + xIndicator + " xInterval " + xInterval + "proportion "+ (1-((intervalTime*1.00)/maxSecs)));
		
		var lapIdx = -1;
		var lapX = -1;
		if(lapArray.size()>0) { 
			lapIdx = 0;
			//lapX =(lapArray[lapIdx]/(timer*1.00))*(xValConst - xIndicator);//This formula has to be the same as below
			//lapX =(lapArray[lapIdx]/(900*1.00))*(xValConst - xIndicator);//This formula has to be the same as below
			//System.println(" lapX:   " + lapArray[lapIdx]/(900*1.00) + " lapArray[lapIdx]: " + lapArray[lapIdx] + " xValConst: "+xValConst + " xIndicator: "+ xIndicator );
		}
		
		//Draw arrow at top of graph representing when the workout started
		//dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
		//dc.fillPolygon([[xIndicator-5, (yVal-4)],[xIndicator, (yVal+1)], [xIndicator+5, (yVal-4)]]);
	 	var heart = sample.next();
		for (var i = 0; i < totBins; ++i) {
		
			heartBinMax = 0;
			heartBinMin = 0;
			
			if (!finished)
			{
				//deal with carryover values
				if (secsBin > 0 && heartValue != null)
				{
					heartBinMax = heartValue;
					heartBinMin = heartValue;
				}

				//deal with new values in this bin
				/*
				while (!finished && secsBin < binWidthSecs)
				{
					heart = sample.next();
					if (heart == null) { finished = true;}
					else
					{
						heartValue = heart.data;
						if (heartValue != null)
						{
							if (heartBinMax == 0)
							{
								heartBinMax = heartValue;
								heartBinMin = heartValue;
							}
							else
							{
								if (heartValue > heartBinMax)
									{ heartBinMax = heartValue; }
								if (heartValue < heartBinMin)
									{ heartBinMin = heartValue; }
							}
						}

						// keep track of time in this bin
						heartSecs = lastHeartSecs - heart.when.value();
						lastHeartSecs = heart.when.value();
						secsBin += heartSecs;
						//System.println(i + ":   " + heartValue + " " + heartSecs + " " + secsBin + " " + heartBinMin + " " + heartBinMax);
					}

				} */ // while secsBin < binWidthSecs

				if (secsBin >= binWidthSecs) { secsBin -= binWidthSecs; }
			    xVal = xValConst - i*binPixels;
			    
				//**I need to avoid getting here unless there's something to draw
				//if(lapIdx!=-1){
					//XSize-(ProportionOfTheTime)*(WorkoutPeriodPixels)
					/*
					System.println(" lapX:   " + lapArray[lapIdx]/(900*1.00)*(xIndicator - xVal) + " lapArray[lapIdx]: " + lapArray[lapIdx] + " xVal: "+xVal + " xIndicator: "+ xIndicator );
					if(lapX>=xIndicator - xVal && lapIdx>=0){
						gldc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
						gldc.drawRectangle(xVal, totHeight, 1, 1);
						//Get Next Lap Position
						//lapX =(lapArray[lapIdx]/(timer*1.00))*(xValConst - xIndicator);
						lapX =(lapArray[lapIdx]/(900*1.00))*(xIndicator - xVal);
						lapIdx++;
					}
					*/
				//}
				//var lapArray = [35, 67, 90];
				//var lapIdx = 0;
				//(xVal - xIndicator)/timer//how many pixels I have to draw
				//I need to divide by how much time it have been
				//Intervals are greater than timer
				//Interval/timer is my proportion
				//**

				//Draw Line in zone color if HR was found
				//System.println(i + " prevHeartBinMin:   " +prevHeartBinMin + " prevHeartBinMax: " + prevHeartBinMax + " " + heartBinMin + " " + heartBinMax);
				//System.println(i + " getMax:   " + sample.getMax() + " getMin: " + sample.getMin());
				//if ((heartBinMax > 0 && heartBinMax >= heartBinMin)){
				
					//if ((curHeartMax > 0 && curHeartMax > curHeartMin)) {

						//heartBinMid = (heartBinMax+heartBinMin)/2;
						
						if(simulatedIdx<simulateHRArray.size()){ //simulateHRArray.size()
						heartBinMin = simulateHRArray[simulatedIdx];
						simulatedIdx = simulatedIdx + 1;
						heartBinMax = simulateHRArray[simulatedIdx];
						simulatedIdx = simulatedIdx + 1;} else {
						heartBinMin = 100;
						heartBinMax = 102;
						i = totBins;}
				
						prevHeight = 0;
						tHeartBinMax = prevHeartBinMin > heartBinMax? prevHeartBinMin:heartBinMax; 
						tempHeartBin = prevHeartBinMax < heartBinMin? prevHeartBinMax:heartBinMin;
						
						//System.println(i + " timer "+ timer + " heartBinMax: " + heartBinMax + " heartBinMin: " + heartBinMin + " tHeartBinMax: "+tHeartBinMax + " tempHeartBin "+ tempHeartBin + "yDenominador " + yDenominador );
						
						while(tempHeartBin <= tHeartBinMax) { 
							//height = ((tempHeartBin-curHeartMin*0.9) / (curHeartMax-curHeartMin*0.9) * totHeight).toNumber();
							height = ((tempHeartBin-curHeartMin) / (yDenominator) * totHeight).toNumber();
							/*if(prevHeight != height){ //Avoid drawing the same dot again
								//System.println(i + " xVal:   " + xVal + " xIndicator: " + xIndicator + " dasherCnt: "+dasherCnt);
								//Draw Dash Line for the first minutes of the graph not within the workout time
								//if(xVal < xIndicator){
									if(dasherCnt < 3) {
										dc.setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(tempHeartBin)], Gfx.COLOR_TRANSPARENT);
										dc.drawRectangle(xVal, yVal + totHeight - height, 2, 2);
										//System.println(i + " DotDrwan dasherCnt: "+dasherCnt);
									}
									dasherCnt= dasherCnt>5?0:dasherCnt+1;
									
								} else {*/									
									gldc.setColor(mModel.getHRZoneColor(tempHeartBin), Gfx.COLOR_BLACK);
									//dc.setColor(uiHRZoneColor[getHRTestColour(tempHeartBin)], Gfx.COLOR_TRANSPARENT); 
									gldc.drawRectangle(xVal, (yVal + totHeight - height), 3, 3);
									//fillRoundedRectangle(x as Numeric, y as Numeric, width as Numeric, height as Numeric, radius as Numeric) as Void
									//dc.fillCircle(xVal, yVal + totHeight - height, 1);
								/*}
							}*/
							tempHeartBin++;
							prevHeight = height;
						//}
						
						prevHeartBinMin = heartBinMin;
						prevHeartBinMax = heartBinMax;
					//}

					//if (heartBinMin < heartMin) 
					//	{ heartMin = heartBinMin; } 
					//if (heartBinMax > heartMax)
					//	{ heartMax = heartBinMax; }
					//System.println(i + "curHeartMax: " +curHeartMax + " sample.getMax: " + sample.getMax() + " curHeartMin: " + heartBinMin + " sample.getMin: " + sample.getMin());
				}		

			} // if !finished

		} // loop over all bins
		
		//Draw a shadow representing HR measurements out of the workout timeframe	
		//xIndicator = xValConst - (totBins * ((timer*1.00)/maxSecs)*binPixels);
		//dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		//for (var i = xValConst-totBins; i < xIndicator; i=i+4) { dc.drawLine(i, yVal, i, yVal+totHeight);} //Vertical Lines
		/*for (var i = yVal; i < yVal+totHeight; i=i+2) {dc.drawLine(xIndicator, i, (xValConst+totBins), i);}*/ //Horizontal Lines
		
		//Draw a short tick on the line representing the desired time interval
		var xTickIndicator; 
		//System.println("Interval1 Limit "+maxSecs/(tickInterval)+" "+maxSecs+" "+tickInterval);
		for(var i = 0; i <= (maxSecs/(tickInterval)); i++){
			xTickIndicator =  xValConst - (totBins * ((tickInterval*i*1.00)/maxSecs))*binPixels; //(xIndicator + (totBins * ((tickInterval*i)/maxSecs))*binPixels);
			//System.println(i+" xTickIndicator1 "+xTickIndicator);
			if(xTickIndicator<xValConst-totWidth){xIndicator = xValConst-totWidth;}
			gldc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			var tickLengh = ((tickInterval*i)%(tickInterval*4)) == 0? 7: ((tickInterval*i)%(tickInterval*2)) == 0? 5 : 3; 
			gldc.fillRectangle(xTickIndicator-1, yVal+totHeight-tickLengh, binPixels*3, tickLengh);
		}
		
		return gl;
			
	}


	//Used for force drawing colors whhen testing in the Emulator
	function getHRTestColour(mHeartRate)
	{
	
		
	 	var mZones = [79, 82, 86, 88, 90, 92];//fake zones 
			
		// Gray Zone
        if ( mHeartRate < mZones[0] ) {
            return 1;
        // Blue Zone
        } else if ( mHeartRate < mZones[1] ) {
            return 2;
        // Green Zone
        } else if ( mHeartRate < mZones[2] ) {
            return 3;
        // Orange Zone
        } else if ( mHeartRate < mZones[3] ) {
            return 4;
        //Red Zone
        } else if ( mHeartRate >= mZones[3] ) {
            return 5;
        }
        
        // Gray Zone - Default
        return 1;
	}
	
	/*
	//Used for force drawing colors when testing in the Emulator
	function getTestHR(i, mHeartRate)
	{
	
		getSimulateHRArray();
	
		if (mHeartRate == null) {return 0;}
	 	var mZones = [79, 82, 86, 88, 90, 92];//fake zones 
	 	
	 	//Math.srand(i);
	 	Math.srand(i);
	 	//i = Math.rand();
	 	var r = Math.rand() % 900 + 100; //Random number between 100 and 1000 (900+100)
	 	//r = r/1000.00;
	 	System.println("Irand:" + r  );
	 	
	 	
	 	var RAND_MAX = 1000.00;
		
		// return a random value on the range [n, m]
		mHeartRate = 75 + r /  (165.00 - 75.00 + 1.0);
    	//mHeartRate = 165 + Math.rand() / (RAND_MAX / (165 - 75 + 1) + 1);
		System.println("HR " + mHeartRate );
		return mHeartRate;
			
		// Gray Zone
        if ( mHeartRate < mZones[0] ) {
            return mHeartRate * (r + 1) ;
        // Blue Zone
        } else if ( mHeartRate < mZones[1] ) {
            return mHeartRate * 1.07;
        // Green Zone
        } else if ( mHeartRate < mZones[2] ) {
            return mHeartRate * 1.10;
        // Orange Zone
        } else if ( mHeartRate < mZones[3] ) {
            return mHeartRate * 1.06;
        //Red Zone
        } else if ( mHeartRate >= mZones[3] ) {
            return mHeartRate;
        }
        
        // Gray Zone - Default
        return mHeartRate;
	}*/
	
	function clamp(min, max, value) {
            if (value < min) { return min; }
            if (value > max) { return max; }
            return value;
    }
    
    function testFonts(dc){
    	
		dc.setColor(Gfx.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
		dc.fillRectangle(0, 0, devWidth, devHeight);
	    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		//dc.drawText(devXCenter, devYCenter-10, mController.FONTMEDIUM, getTimeString()+" "+Gfx.getFontHeight( Ui.loadResource( Rez.Fonts.RobotoCondensedBold34 )), Graphics.TEXT_JUSTIFY_CENTER);
		dc.drawText(devXCenter, devYCenter-10, Ui.loadResource( Rez.Fonts.RobotoCondensedBold30 ), "1234567890", Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+20, Ui.loadResource( Rez.Fonts.RobotoCondensedBold30NoCT ), "1234567890", Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+10, Ui.loadResource( Rez.Fonts.RobotoCondensedBold30SS4 ), "1234567890", Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, 30, Ui.loadResource( Rez.Fonts.RobotoCondensedBold30 ), getTimeString()+" "+Gfx.getFontHeight( Ui.loadResource( Rez.Fonts.RobotoCondensedBold30 )), Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, 60, Ui.loadResource( Rez.Fonts.RobotoCondensedBold34 ), getTimeString()+" "+Gfx.getFontHeight( Ui.loadResource( Rez.Fonts.RobotoCondensedBold34 )), Graphics.TEXT_JUSTIFY_CENTER);
		
		//dc.drawText(devXCenter, devYCenter+20, Gfx.FONT_SYSTEM_MEDIUM, getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_SYSTEM_MEDIUM) , Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+60, Gfx.FONT_SYSTEM_SMALL, "S "+getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_SYSTEM_SMALL), Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+60, Gfx.FONT_SYSTEM_TINY, "S "+getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_SYSTEM_TINY), Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+10, Gfx.FONT_SYSTEM_XTINY, getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_SYSTEM_XTINY), Graphics.TEXT_JUSTIFY_CENTER);
		
		//dc.drawText(devXCenter-70, devYCenter-60, Gfx.FONT_NUMBER_THAI_HOT,   "S "+getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_NUMBER_THAI_HOT) , Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter-70, devYCenter, Gfx.FONT_NUMBER_HOT,   "S "+getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_NUMBER_HOT) , Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+30, Gfx.FONT_NUMBER_MEDIUM, "S "+getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_NUMBER_MEDIUM), Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+60, Gfx.FONT_NUMBER_MILD,  "S "+getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_NUMBER_MILD), Graphics.TEXT_JUSTIFY_CENTER);
		//dc.drawText(devXCenter, devYCenter+90, Gfx.FONT_SYSTEM_XTINY, "S "+getTimeString()+" "+Gfx.getFontHeight(Gfx.FONT_SYSTEM_XTINY), Graphics.TEXT_JUSTIFY_CENTER);
		return;
		
    }
    
    function getSimulateHRArray() {
    
    var simulateHRArray = [
    
    95,96,
    96,96,
    95,96,
    97,98,
	98,101,
	101,110,
	101,101,
	101,112,
	102,113,
	108,112,
	107,113,
	109,110,
	111,115,
	112,112,
	100,112,
	109,111,
	105,111,
	105,100,
	99,100,
	100,105,
	102,104,
	
	104,106,
    106,107,
    110,105,
    111,115,
	116,119,
	120,124,
	125,130,
	131,143,
	144,145,
	142,146,
	143,146,
	140,143,
	142,142,
	139,140,
	140,142,
	137,142,
	137,141,
	135,142,
	134,139,
	140,144,
	144,145,
	
	146,155,
    155,156,
    155,156,
    154,158,
	155,155,
	151,160,
    155,159,
    155,156,
    154,158,
	155,155,
	149,155,
    155,156,
    155,156,
    154,158,
	155,155,
	155,155,
    155,156,
    155,156,
    154,158,
	155,159,
	
	155,155,
    154,156,
    155,156,
    156,158,
	155,155,
	157,160,
    150,159,
    155,155,
    154,156,
	155,155,
	158,158,
    155,160,
    155,162,
    150,155,
	155,155,
	154,155,
    155,156,
    155,156,
    154,156,
	155,155,
	
	155,155,
    154,156,
    155,156,
    158,158,
	159,162,
	160,160,
    161,165,
    165,170,
    165,171,
	161,170,
	159,159,
    159,160,
    160,162,
    160,163,
	158,162,
	160,161,
    160,162,
    161,163,
    159,162,
	158,161,
	
	155,155,
    154,156,
    155,156,
    158,158,
	159,165,
	160,165,
    164,165,
    166,170,
    170,173,
	171,173,
	168,170,
    165,168,
    162,167,
    162,163,
	158,162,
	160,161,
    159,162,
    158,163,
    159,162,
	158,161,
	
	155,155,
    154,154,
    148,150,
    146,148,
	145,145,
	144,144,
    144,144,
    145,146,
    144,145,
	144,145,
	142,144,
    141,143,
    139,142,
    133,142,
	130,133,
	129,135,
    135,135,
    133,133,
    132,133,
	132,133,
	
	135,136,
    136,140,
    140,145,
    146,150,
	150,155,
	156,160,
    155,159,
    155,155,
    149,155,
	149,153,
	153,158,
    157,160,
    155,160,
    150,155,
	155,155,
	154,155,
    155,156,
    155,156,
    154,156,
	155,155,
	
	145,155,
    146,150,
    140,149,
    138,140,
	136,139,
	136,137,
    134,135,
    130,134,
    129,131,
	131,132,
	131,133,
    125,130,
    125,129,
    125,128,
	125,126,
	126,126,
    125,126,
    125,126,
    124,126,
	115,123,
	
	115,123,
    114,120,
    115,119,
    116,118,
	116,117,
	116,117,
    116,116,
    117,120,
    120,123,
	119,122,
	118,119,
    118,118,
    114,117,
    110,114,
	112,114,
	110,113,
    110,112,
    105,112,
    107,110,
	108,111,

	105,108,
    100,104,
    99,101,
    97,99,
	98,99,
	97,99,
    95,98,
    95,97,
    95,97,
	96,97,
	97,97,
    98,99,
    91,97,
    90,91,
	90,91,
	90,91,
    89,90,
    87,89,
    
    105,108,
    100,104,
    99,101,
    97,99,
	98,99,
	97,99,
    95,98,
    95,97,
    95,97,
	96,97,
	97,97,
    98,99,
    91,97,
    90,91,
	90,91,
	90,91,
    89,90,
    87,89

    ];
    
    //System.println("simulateHRArray Size " + simulateHRArray.size());
    return simulateHRArray;
    
    }
    
}