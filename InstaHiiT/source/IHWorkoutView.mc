//! View during workout

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
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

    hidden var uiHRZoneColor;
    hidden var uiHRZoneValue;
    hidden var uiColorsArray;

    hidden var prevZone;
    hidden var vibeTime;
    hidden var selectedActivityStr;
    hidden var maxHR;
    hidden var currTemperature;
    hidden var currCharge;
    hidden var isDarkModeOn;
	hidden var showBattTempFields;
    
    //Graph Constants
    hidden var heartMin = 1000;
	hidden var heartMax = 0;
	//hidden var graphLength = 15; //minutes
	hidden var maxSecs; // = graphLength * 60;
	hidden var tickInterval = 15; //In Minutes
	//hidden var tickInterval2 = 30; //In Minutes
	hidden var totHeight = 45; //Graph Height
	hidden var totWidth = 210; //Graph Width
	hidden var binPixels = 1; //Bin (Column) Width
	hidden var totBins = Math.ceil(totWidth / binPixels).toNumber(); //Count of Bins or Columns
	//hidden var binWidthSecs = Math.floor(binPixels * maxSecs / totWidth).toNumber(); //Amount of time that average a bin	
	hidden var xValConst;
	hidden var yVal;
	
	//Location Constants
	hidden var devWidth; //Device Width
	hidden var devHeight; //Device Height
	hidden var devXCenter; //Device X Center
	hidden var devYCenter; //Device Y Center

    function initialize() {
        View.initialize();
        // Start timer used to push UI updates
        mTimer = new Timer.Timer();
        // Get the model and controller from the Application
        mModel = Application.getApp().model;
        mController = Application.getApp().controller;
        
        //Convert tickIntervals to seconds
        tickInterval = tickInterval * 60; 
		//tickInterval2 = tickInterval2 * 60; 

		uiHRZoneValue = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC); //Get Default HR Zones from user profiles
        prevZone = 0;
        vibeTime = 0;
        currTemperature = 0;
        currCharge = 0;
    }

    //! Load your resources here
    function onLayout(dc) {
    
    	System.println("onLayout");
    	
        // Load the layout from the resource file
        //setLayout(Rez.Layouts.PrimaryWorkoutScreen(dc));
        
        //Initialize Screen Dimension Variabbles with dc (Display Context)
        devWidth = dc.getWidth();
		devHeight = dc.getHeight();
		devXCenter = devWidth/2; 
		devYCenter = devHeight/2; 
		//System.println("Screen Dimensions: " + devWidth + "x" + devHeight);
		
		//Initialize Graph Position Constants
		xValConst = (devWidth-totWidth)/2 + totWidth;
		yVal = devHeight/2 + 8;
        
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    
    System.println("onShow");
    
        mTimer.start(method(:onTimer), 1000, true);
        
        // If we come back to this view via back button from Resume option
        //if (!mController.isRunning()  && mController.resume == true) {
        if(mController.WorkoutUIState == mController.UISTATE_STOPPED){
        	//mController.resume = false; 
            mController.onStartStop();
            
        }
        
        
        //Get Seetings
		isDarkModeOn =  mController.getDarkModeSetting();
		showBattTempFields =  mController.getBattTempSetting();
        selectedActivityStr = mController.getActivityString(); //Get Activity String only when OnShow is called
        maxHR = mModel.getMaxHRbpm();
        
        //Initialize UI Colors
        //MainBkgrdColor, TopDowmBrgrdColor, ValueColor, LabelColor, TopDownValueColor, BattTempValues
        if(isDarkModeOn  == false){
        	uiColorsArray = [Gfx.COLOR_WHITE, Gfx.COLOR_BLACK, Gfx.COLOR_BLACK, Gfx.COLOR_DK_GRAY, Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY];
        	uiHRZoneColor = [Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_GRAY, Gfx.COLOR_DK_BLUE, Gfx.COLOR_DK_GREEN, Gfx.COLOR_ORANGE, Gfx.COLOR_RED];
        }
        else {
         	uiColorsArray = [Gfx.COLOR_BLACK, Gfx.COLOR_BLACK, Gfx.COLOR_WHITE, Gfx.COLOR_LT_GRAY, Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY];
         	uiHRZoneColor = [Gfx.COLOR_BLUE, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN, Gfx.COLOR_YELLOW, Gfx.COLOR_ORANGE, Gfx.COLOR_RED];
        }
        
        
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
		
		// Plot heart rate graph every 60 seconds, at the 10 seconds of the minute
		//Do not update anything else but timers to smooth UI update and reduce glitches
		if(mController.WorkoutUIState == mController.UISTATE_RUNNING && ((timer-10) % 60) == 0) {
			drawTimers(dc, timer);
			if(showBattTempFields == true) {drawSlowUpdatingFields(dc, timer);}//Draw Batt and Temperature 	
			plotHRgraph(dc,timer); 
			return;
		}

		//Workout Running and End Screen Common Drawing
		if(mController.WorkoutUIState == mController.UISTATE_RUNNING || mController.WorkoutUIState == mController.UISTATE_WORKOUTEND) {
		
			//Clean Top Header Area
			dc.setColor(uiColorsArray[1], Gfx.COLOR_TRANSPARENT);
			dc.fillRectangle(0, 0, devWidth, 32); 
	
			//Clear HR Fields Area
			dc.setColor(uiColorsArray[0], Gfx.COLOR_TRANSPARENT);
			dc.fillRectangle(0, 32, devWidth, 92); 

			//drawCenterFields(dc);
			drawTimers(dc, timer);

			//Draw Labels
			dc.setColor(uiColorsArray[3], Graphics.COLOR_TRANSPARENT);	
	    	dc.drawText(53, 30,  mController.FONTXTINY, "Kcal", Graphics.TEXT_JUSTIFY_CENTER);
	    	dc.drawText(190, 30, mController.FONTXTINY, "IMin", Graphics.TEXT_JUSTIFY_CENTER);
	    	dc.drawText(38, 73,  mController.FONTXTINY, "Max",  Graphics.TEXT_JUSTIFY_CENTER); 
	    	dc.drawText(devXCenter, 29, mController.FONTXTINY, "Peak", Graphics.TEXT_JUSTIFY_CENTER); 
       		if(mModel.isGPSOn() == true) {dc.drawText(70, 12, mController.FONTXXXTINY, "GPS", Graphics.TEXT_JUSTIFY_CENTER);} //Draw GPS string if enabled
    
			//Draw IMin, Kcal and MakHR
			dc.setColor(uiColorsArray[2], Graphics.COLOR_TRANSPARENT);
	        dc.drawText(190, 47, mController.FONTTINY, mModel.getIntesityMinutes(), Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(54, 47, mController.FONTTINY, mModel.getCalories(), Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(36, 90, mController.FONTSMALL, maxHR, Graphics.TEXT_JUSTIFY_CENTER);
		
			//Peak HR and Percent
			var peakHR = mModel.getPeakHR();	
			var peakHRCombo = peakHR+" "+mModel.getPeakHRpct(); //Peak HR and Peak HR Pecent concatenated 
			var percSymOffset = dc.getTextWidthInPixels(peakHRCombo, mController.FONTSMALL)/2;
        	dc.setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(peakHR)], Graphics.COLOR_TRANSPARENT);
        	dc.drawText(devXCenter, 44, mController.FONTSMALL, peakHRCombo, Graphics.TEXT_JUSTIFY_CENTER); //Peak HR and Peak HR Pecent concatenated 
		    dc.setColor(uiColorsArray[3], Graphics.COLOR_TRANSPARENT);
		    dc.drawText(devXCenter+percSymOffset+5, 44, mController.FONTXXXTINY, "%", Graphics.TEXT_JUSTIFY_CENTER); //Percentage Symbol 
		    
		    //Plot heart rate graph 1st second or when forced to update UI
			if(mController.forceOnUpdate || timer == 1) { plotHRgraph(dc, timer);}
		    
		}
		
		//Workout Running Only Drawings Screen
		if(mController.WorkoutUIState == mController.UISTATE_RUNNING) {
		
			//Draw Batt and Temperature
			if(showBattTempFields == true) {drawSlowUpdatingFields(dc, timer);}	
			
	    	//Draw Time
	    	dc.setColor(uiColorsArray[4], Graphics.COLOR_TRANSPARENT);
			dc.drawText(devXCenter, 1, mController.FONTSMALL, getTimeString(), Graphics.TEXT_JUSTIFY_CENTER); 

            //Get current HeartRate and Percent
       		var heartRate = mModel.getHRbpm();
            var curZone = mModel.getHRZoneColorIndex(heartRate);
	        dc.setColor(uiHRZoneColor[curZone], Graphics.COLOR_TRANSPARENT);
	        dc.drawText(devXCenter, 60, mController.FONTXXLARGE, heartRate, Graphics.TEXT_JUSTIFY_CENTER); //Current HR
	        var currHRRpct = Math.round(( heartRate.toDouble() / maxHR.toDouble() ) * 100).toNumber() + "";
	        dc.drawText(200, 80, mController.FONTLARGE, currHRRpct, Graphics.TEXT_JUSTIFY_CENTER); //Current HR Percent
	        dc.setColor(uiColorsArray[3], Graphics.COLOR_TRANSPARENT);
	        dc.drawText(200 + (dc.getTextWidthInPixels(currHRRpct, mController.FONTLARGE)/2) + 5, 80, mController.FONTXTINY, "%", Graphics.TEXT_JUSTIFY_CENTER); //Percentage Symbol
	        
	        //Update Max/Min HR till the moment
	        if(heartRate > 0){
	        	if (heartRate > heartMax) { heartMax = heartRate; }
				if (heartRate < heartMin) { heartMin = heartRate; }
			}
			//System.println("Max: " + heartMax + " Min: " + heartMin);
	        
	        //Draw only when coming from OnShow or Every 10 Seconds if showing Minutes in HRZones 
        	if(mController.forceOnUpdate || (((timer) % 10) == 0 && mController.hrZoneMode == 2)) { drawZonesLegend(dc); }

        	mController.forceOnUpdate = false;
	        
	        //Check Zone Change after every 5 seconds to prevent back to back vibration events
	    	if((timer - vibeTime) > 5) {zoneChangeEvents(curZone, timer);}
	    	
	    	return;
        }

       //Workout Done Only Drawings, user can Exit Screen 
       if(mController.WorkoutUIState == mController.UISTATE_WORKOUTEND) {
       
			//Draw Avg Label and Value
			dc.setColor(uiColorsArray[3], Graphics.COLOR_TRANSPARENT);	
	    	dc.drawText(195, 73, mController.FONTXTINY, "Avg", Graphics.TEXT_JUSTIFY_CENTER); //Draw Avg String
	        dc.drawText(195, 90, mController.FONTSMALL, mModel.getAvgHRbpm(), Graphics.TEXT_JUSTIFY_CENTER);
	    	
	    	//Draw Saved! Top
			dc.setColor(uiColorsArray[4], Graphics.COLOR_TRANSPARENT);	
			dc.drawText(devXCenter, 4, mController.FONTXTINY, "Saved!", Graphics.TEXT_JUSTIFY_CENTER); //Draw Calories
			
			//Draw End of Workout Fields
			dc.setColor(uiColorsArray[2], Graphics.COLOR_TRANSPARENT);	
			dc.drawText(devXCenter, 70, mController.FONTSMALL, "Workout", Graphics.TEXT_JUSTIFY_CENTER);
			dc.drawText(devXCenter, 95, mController.FONTSMALL, "Done.", Graphics.TEXT_JUSTIFY_CENTER);
			
			mController.hrZoneMode = 2; drawZonesLegend(dc);//Show Minutes in each zone at WorkoutEnd
			
			mTimer.stop(); //Stop Updating UI
			
			return;
		}

		//Waiting for Heart Rate Screen
		if(mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR || mController.WorkoutUIState == mController.UISTATE_READYTOSTART) {
			
			var heartRate = mModel.getHRbpm();
		
			if (heartRate != 0 && mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR) {
				mController.WorkoutUIState = mController.UISTATE_READYTOSTART;
				//Vibrate briefly to alert the user we got HR and we are ready to start workout
				if( (Attention has :vibrate) && (System.getDeviceSettings().vibrateOn) && (mController.getAllowVibration() == true)){ Attention.vibrate([new Attention.VibeProfile(100, 250)]);}
			} 
			
			//Clean Screen
	        dc.setColor(uiColorsArray[0], Gfx.COLOR_TRANSPARENT);
			dc.fillRectangle(0, 0, devWidth, devHeight);
		    
		    //Draw Instructions
		    dc.setColor(uiColorsArray[2], Graphics.COLOR_TRANSPARENT);
			dc.drawText(devXCenter, 7, mController.FONTSMALL, getTimeString(), Graphics.TEXT_JUSTIFY_CENTER);
	        dc.drawText(devXCenter, (devHeight / 4) -20, mController.FONTSMALL, (mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR?"Waiting for\nHeart Rate ...":(uiBlinkToggle?"Ready for\n"+selectedActivityStr+" Workout!":"Press\nStart button.")), Graphics.TEXT_JUSTIFY_CENTER);
	       	dc.drawText(devXCenter, (devHeight / 3) + 70, mController.FONTXTINY, "Settings:\nLongpress on screen\nor press Menu.", Graphics.TEXT_JUSTIFY_CENTER);
	       	
	       	//Draw Blinking Heart
	       	if(uiBlinkToggle) {dc.drawBitmap(devXCenter/3, devYCenter, Ui.loadResource(Rez.Drawables.hr_red_24));}
	       	
	       	//Draw Current HR
	       	dc.setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(heartRate)], Graphics.COLOR_TRANSPARENT);
	       	dc.drawText(devXCenter, devYCenter-13, mController.FONTLARGE, (mController.WorkoutUIState == mController.UISTATE_WAITINGFORHR?"--":heartRate), Graphics.TEXT_JUSTIFY_CENTER);

	        return; 
        }
				
		//View.onUpdate(dc); //Used if a layout is defined
		
    }
    
    function drawSlowUpdatingFields(dc, timer){
    
    	//Update these fields every minute
    	if((timer % 60) == 0 || currTemperature == 0 || currTemperature == 0) {
        currTemperature = mModel.getTemperature();
        currCharge = Sys.getSystemStats().battery;
        }
        
        //Set System Fields Color
        dc.setColor(uiColorsArray[5], Graphics.COLOR_TRANSPARENT);
       
        // Temperature
        dc.drawText(devWidth*0.84, devHeight*0.80, mController.FONTXXTINY, currTemperature, Graphics.TEXT_JUSTIFY_RIGHT); //Draw Temperature String

		//Vertival Battery
        var battX = 42;
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
		dc.setColor(uiColorsArray[1], Gfx.COLOR_TRANSPARENT);
		dc.fillRectangle(0, 190, devWidth, devHeight-190); //Footer Timer Area
    
        //Get Timers Strings    
        var timerString =          Lang.format("$1$:$2$:$3$", [((timer / 60) / 60).format("%2d"), ((timer / 60) % 60).format("%02d"), (timer % 60).format("%02d")]);
        var secondaryTimer = mModel.getSecondaryTimeElapsed();
        var secondaryTimerString = Lang.format("$1$:$2$:$3$", [((secondaryTimer  / 60) / 60).format("%2d"), ((secondaryTimer / 60) % 60).format("%02d"), (secondaryTimer % 60).format("%02d")]);

		//Draw Timers
		dc.setColor(uiColorsArray[4], Gfx.COLOR_TRANSPARENT);
		dc.drawText(devXCenter, 186, mController.FONTSMALL, timerString, Graphics.TEXT_JUSTIFY_CENTER); //Draw timer 
        dc.drawText(devXCenter, 208, mController.FONTSMALL, secondaryTimerString, Graphics.TEXT_JUSTIFY_CENTER); //Draw secondary timer
		//dc.drawBitmap(63, 200, Ui.loadResource(Rez.Drawables.stopwatch_24)); //Timer Icon
    }
    
    function drawZonesLegend(dc){
    
        //Clean legend Area Bkgd
    	dc.setColor(uiColorsArray[0], Gfx.COLOR_TRANSPARENT); dc.fillRectangle(0, 173, devWidth, 17); 
		
		//Zones Rectangle Colors
		dc.setColor(uiHRZoneColor[5], Graphics.COLOR_TRANSPARENT); dc.fillRectangle(11, 174, 49, 15); 
		dc.setColor(uiHRZoneColor[4], Graphics.COLOR_TRANSPARENT); dc.fillRectangle(61, 174, 39, 15);
		dc.setColor(uiHRZoneColor[3], Graphics.COLOR_TRANSPARENT); dc.fillRectangle(101, 174, 39, 15);
		dc.setColor(uiHRZoneColor[2], Graphics.COLOR_TRANSPARENT); dc.fillRectangle(141, 174, 39, 15);
		dc.setColor(uiHRZoneColor[1], Graphics.COLOR_TRANSPARENT); dc.fillRectangle(181, 174, 49, 15);
		
		//System.println("Update Zones: " + timer + " "+ mController.hrZoneMode);
		var hrZoneArray = mController.hrZoneMode == 1? uiHRZoneValue:mModel.getZoneTimes();
		dc.setColor(uiColorsArray[0], Graphics.COLOR_TRANSPARENT);  //Legend Text Color
		dc.drawText(41, 170, mController.FONTXXTINY, 		hrZoneArray[4], Graphics.TEXT_JUSTIFY_CENTER); //Zone5 Text
		dc.drawText(81, 170, mController.FONTXXTINY, 		hrZoneArray[3], Graphics.TEXT_JUSTIFY_CENTER); //Zone4 Text
		dc.drawText(devXCenter, 170, mController.FONTXXTINY, hrZoneArray[2], Graphics.TEXT_JUSTIFY_CENTER); //Zone3 Text
		dc.drawText(161, 170, mController.FONTXXTINY, 		hrZoneArray[1], Graphics.TEXT_JUSTIFY_CENTER); //Zone2 Text
		dc.drawText(201, 170, mController.FONTXXTINY, 		hrZoneArray[0], Graphics.TEXT_JUSTIFY_CENTER); //Zone1 Text
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
    
	//function plotHRgraph(dc, elapsedSecs) {
	function plotHRgraph(dc, timer) {
		
		//Clean Graph Background
		dc.setColor(uiColorsArray[0], Gfx.COLOR_TRANSPARENT);
		dc.fillRectangle(0, 124, devWidth, 50); 
		
		if(!(Toybox has :SensorHistory)){ return;} //Leave Graph empty if no sensor found
			
		//var curHeartMin = 1000; //0;
		//var curHeartMax = 0;    //0;
	
		//Make sure Graph limits are aceptable
		maxSecs = timer;
		if (maxSecs < 900) { maxSecs = 900; }         	// 900sec = 15min
		else if (maxSecs > 14355) { maxSecs = 14355; }  // 14400sec = 4hrs
		var binWidthSecs = Math.floor(binPixels * maxSecs / totWidth).toNumber(); //Amount of time that average a bin	
		var maxSecsDuration = new Time.Duration(maxSecs); 
		var sample = Sensor.getHeartRateHistory( {:duration=>maxSecsDuration,:order=>Sensor.ORDER_NEWEST_FIRST});  //Seems to always return all history
		//System.println("Iterator:" +  sample.getMax() + " " + sample.getMin()); //Always return de whole history Max/min not of the Duration
		//dc.setColor(uiColorsArray[3], Gfx.COLOR_TRANSPARENT);
		//dc.drawText(devXCenter, 120, mController.FONTXTINY, "iMax: " + sample.getMax() + " iMin: " + sample.getMin(), Graphics.TEXT_JUSTIFY_CENTER); 
								
		//If no HR Iterator was found leave Graph space empty	
		if (sample == null) {return;}
		
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
			//dc.setColor(uiColorsArray[3], Gfx.COLOR_TRANSPARENT);
			//dc.drawText(devXCenter, 140, mController.FONTXTINY, "Max: " + heartMax + " Min: " + heartMin, Graphics.TEXT_JUSTIFY_CENTER);
			System.println("Max: " + heartMax + " Min: " + heartMin);
			return;
		}
	  	
		var heart = sample.next();
		//var curHeartMin = sample.getMin();
		//var curHeartMax = sample.getMax();
		var curHeartMin = heartMin;
		var curHeartMax = heartMax;
		//heartMin = 1000;
	    //heartMax = 0;

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
		//var heartBinMid = 0;
		var prevHeight = 0;
		var height = 0;
		var xVal = 0;
		
		//Draw a shadow representing HR measurements out of the workout timeframe	
		/*var xIndicator = (xValConst + (totBins * ((mModel.getTimeElapsed()*1.00)/maxSecs))*binPixels);
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
		for (var i = yVal; i < yVal+totHeight; i=i+2) {
			dc.drawLine(xIndicator, i, (xValConst+totBins), i);
		}
		for (var i = xIndicator; i < (xValConst+totBins); i=i+2) {
			dc.drawLine(i, yVal, i, yVal+totHeight);
		}*/
		
		//Draw an static arrow at top of graph representing current and end workout time	
		var xIndicator = xValConst; // + (totBins * ((mModel.getTimeElapsed()*1.00)/maxSecs))*binPixels);
		dc.setColor(uiColorsArray[3], Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon([[xIndicator-5, (yVal-4)],[xIndicator, (yVal+1)], [xIndicator+5, (yVal-4)]]);
		
		//Draw arrow at top of graph representing when the workout started	
		xIndicator = xValConst - (totBins * ((timer*1.00)/maxSecs)*binPixels);
		//System.println("timer "+timer+" xIndicator "+xIndicator+" xValConst "+xValConst);
		if(xIndicator<xValConst-totWidth){xIndicator = xValConst-totWidth;}
		dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon([[xIndicator-5, (yVal-4)],[xIndicator, (yVal+1)], [xIndicator+5, (yVal-4)]]);
	
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
				if (heartBinMax > 0 && heartBinMax >= heartBinMin){
				
					if (curHeartMax > 0 && curHeartMax > curHeartMin) {

						//heartBinMid = (heartBinMax+heartBinMin)/2;
				
						prevHeight = 0;
						tHeartBinMax = prevHeartBinMin > heartBinMax? prevHeartBinMin:heartBinMax; 
						tempHeartBin = prevHeartBinMax < heartBinMin? prevHeartBinMax:heartBinMin;
						while(tempHeartBin <= tHeartBinMax) { 
							//height = ((tempHeartBin-curHeartMin*0.9) / (curHeartMax-curHeartMin*0.9) * totHeight).toNumber();
							height = ((tempHeartBin-curHeartMin*0.9) / (curHeartMax-curHeartMin*0.9) * totHeight).toNumber();
							if(prevHeight != height){ //Avoid drawing the same dot again
								dc.setColor(uiHRZoneColor[mModel.getHRZoneColorIndex(tempHeartBin)], Gfx.COLOR_TRANSPARENT);
								//dc.setColor(uiHRZoneColor[getHRTestColour(tempHeartBin)], Gfx.COLOR_TRANSPARENT); 
								dc.drawRectangle(xVal, yVal + totHeight - height, 2, 2);
								//dc.fillCircle(xVal, yVal + totHeight - height, 1);
							}
							tempHeartBin++;
							prevHeight = height;
						}
						
						prevHeartBinMin = heartBinMin;
						prevHeartBinMax = heartBinMax;
					}

					//if (heartBinMin < heartMin) 
					//	{ heartMin = heartBinMin; } 
					//if (heartBinMax > heartMax)
					//	{ heartMax = heartBinMax; }
					//System.println(i + "curHeartMax: " +curHeartMax + " sample.getMax: " + sample.getMax() + " curHeartMin: " + heartBinMin + " sample.getMin: " + sample.getMin());
				}		

			} // if !finished

		} // loop over all bins
		
		//Draw a short tick on the line representing the desired time interval
		var xTickIndicator; 
		var iOffSet = 0; //timer/tickInterval;
		//System.println("Interval1 Limit "+maxSecs/(tickInterval)+" "+maxSecs+" "+tickInterval);
		for(var i = 0 - iOffSet; i <= (maxSecs/(tickInterval))+iOffSet; i++){
			xTickIndicator =  xValConst - (totBins * ((tickInterval*i*1.00)/maxSecs))*binPixels; //(xIndicator + (totBins * ((tickInterval*i)/maxSecs))*binPixels);
			//System.println(i+" xTickIndicator1 "+xTickIndicator);
			if(xTickIndicator<xValConst-totWidth){xIndicator = xValConst-totWidth;}
			dc.setColor(uiColorsArray[2], Gfx.COLOR_TRANSPARENT);
			var tickLengh = ((tickInterval*i)%(tickInterval*4)) == 0? 7: ((tickInterval*i)%(tickInterval*2)) == 0? 5 : 3; 
			dc.fillRectangle(xTickIndicator-1, yVal+totHeight-tickLengh, binPixels*3, tickLengh);
		}
			
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
		dc.drawText(devXCenter, devYCenter+10, Ui.loadResource( Rez.Fonts.RobotoCondensedBold30SS4 ), "1234567890", Graphics.TEXT_JUSTIFY_CENTER);
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
}