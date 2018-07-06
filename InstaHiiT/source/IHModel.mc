//! IHApp Model which handles the data processing of the activity

using Toybox.System;
using Toybox.Attention;
using Toybox.FitContributor as Fit;
using Toybox.Activity;
using Toybox.ActivityRecording as Recording;
using Toybox.UserProfile as Profile;
using Toybox.Time;
using Toybox.Timer;
using Toybox.Math;
using Toybox.WatchUi as Ui;
using Toybox.Sensor; 
using Toybox.Position;

class IHModel
{
    // Internal Timer and monitoring variables
    hidden var mTimer;
    hidden var mSeconds;
    hidden var mSecondarySeconds;
    hidden var mSession = null;
    //hidden var mSplatsField = null;
    hidden var mStability;
    hidden var mStabilityTimer;
    hidden var mStabilityOn;
    hidden var mGPSOn = false;

    // Primary stats used during intervals
    hidden var mHeartRate;
    hidden var mHeartRatePct;
    //hidden var mHeartRateZone;
    hidden var mMaxHR;
    hidden var mZones;
    hidden var mZoneTimes;
    //hidden var mSplats;
    //hidden var mSecondsSplat;
    hidden var mAverageHR;
    hidden var mPeakHR;
    hidden var mCalories;

    // Summarized and exposed statistics
    //var elapsedTime;
    //var calories;
    //var averageHR;
    //var averageHRPct;
    //var PeakHR;
    //var peakHRPct;
    //var splatPoints;
    var zoneTimes;
    var actType;

    //Time in Zones
    hidden var tz1 = 0;
    hidden var tz2 = 0;
    hidden var tz3 = 0;
    hidden var tz4 = 0;
    hidden var tz5 = 0;

    //HR Zone Percentage settings, based on Orange Theory, override user
    //hidden var blueZone = 0.61;
    //hidden var greenZone = 0.71;
    //hidden var orangeZone = 0.84;
    //hidden var redZone = 0.92;
    
    //Activities Supported
    var mActTypes = [Recording.SPORT_TRAINING,
					Recording.SPORT_TRAINING,
					Recording.SPORT_RUNNING,
					Recording.SPORT_WALKING,
					Recording.SPORT_ROWING,
					Recording.SPORT_CYCLING];
    var mActSubTypes = 	[Recording.SUB_SPORT_STRENGTH_TRAINING,
						[Recording.SUB_SPORT_CARDIO_TRAINING,
							Recording.SUB_SPORT_STRENGTH_TRAINING,
							Recording.SUB_SPORT_FLEXIBILITY_TRAINING],
						Recording.SUB_SPORT_TREADMILL,
						Recording.SUB_SPORT_TREADMILL,
						Recording.SUB_SPORT_INDOOR_ROWING,
						Recording.SUB_SPORT_INDOOR_CYCLING];
	var mActTypesStr = 	["Strenght Training",
							["Cardio Training",
							"Strenght Training",
							"Flexibility Training"],
						"Treadmill Running",
						"Treadmill Walking",
						"Indoor Rowing",
						"Indoor Cycling"];
	
    // Initialize Activity
    function initialize() {
        // Sensor Heart Rate
        mHeartRate = 0;
        // Heart Rate as a Percentage
        mHeartRatePct = 0;
        // Current Heart Rate Zone
        //mHeartRateZone = 0;
        // Max Heart Rate
        mMaxHR = 0;
        // Splat Points
        //mSplats = 0;
        // Time elapsed
        mSeconds = 0;
        //Secondary Timer Seconds
        mSecondarySeconds = -2;
        // Time HR is in Orange or Red range
        //mSecondsSplat = 0;
        // HR Zones
        mZones = new [4];
        // HR Time in Each Zone
        mZoneTimes = new [5];
        mStability = true; //Make HR Stability Option ON by Default Default
        mStabilityOn = false; // HR Stability internal logic variable
        mGPSOn = false;
        mStabilityTimer = 0;
        mCalories = 0;
        
        mAverageHR = 0;
    	mPeakHR = 0;

        // Define HR Zones
        setZones();
        
    }

    // Start session
    function start() {
        // Allocate the timer
        mTimer = new Timer.Timer();
        // Process the sensors at 10 Hz
        mTimer.start(method(:hrFieldsCallback), 1000, true);
        // Start the FIT recording
        if ( mSession != null ) { mSession.start(); }
    }

    // Stop sensor processing
    function stop() {
        // Stop the timer
        mTimer.stop();
        // Stop the FIT recording
        if ( mSession != null ) { mSession.stop();}
    }

    // Save the current session
    function save() {
    	if(mGPSOn == true) {Position.enableLocationEvents( Position.LOCATION_DISABLE, method( :onPosition ) );} //GPS will be disabled if previously enabled
        if ( mSession != null ) { mSession.save();}
    }

    // Discard the current session
    function discard() {
    	if(mGPSOn == true) {Position.enableLocationEvents( Position.LOCATION_DISABLE, method( :onPosition ) );} //GPS will be disabled if previously enabled
        if ( mSession != null ) {mSession.discard();}
    }

    // Return the Total calories burned
    function getCalories() {
  		return mCalories;
    }
    
    //Return GPS Status
    function isGPSOn(){
    	return mGPSOn;
    }

     // Return Info HeartRate 
    function getInfoHeartRate() {
       var info = Sensor.getInfo();
       var heartRate = info.heartRate;
       if ( heartRate != null ) {
            return heartRate;
        } else {
            return 0;
        }
    }
    
     // Return the Temperature 
    function getTemperature() {
    	if(Toybox has :SensorHistory){
	       var sensorIter = Toybox.SensorHistory.getTemperatureHistory({});
	       var temp = (sensorIter != null)? sensorIter.next().data:null;
	       
	       var tempUnit = System.getDeviceSettings().temperatureUnits; 
	         
	       if ( temp != null ) {
	       		if(tempUnit == System.UNIT_STATUTE) { temp = temp * 1.8 + 32; } 
	            return Math.round(temp).toNumber()+(tempUnit == System.UNIT_STATUTE?"°F":"°C");
	        } else {
	            return "--";
	        }
        } 
        return ""; //if no sensor found, display nothing
    }
    
    // Return the current Current Workout Peak HRBpm
    function getPeakHR() {
        return mPeakHR;
    }
    
    // Return the current Current Workout Peak Percentage HRBpm
    function getPeakHRpct() {
        return Math.round(( mPeakHR.toDouble() / mMaxHR.toDouble() ) * 100).toNumber();
    }

    // Return the current heart rate in bpm
    function getHRbpm() {
        return mHeartRate;
    }

    // Return the calculate max heart rate in bpm
    function getMaxHRbpm() {
        return mMaxHR;
    }
    
    // Return the calculate average heart rate in bpm
    function getAvgHRbpm() {
        return mAverageHR;
    }

    // Return the current heart rate in bpm
    function getHRpct() {
        return mHeartRatePct;
    }

    // Return the current heart rate zone number
    /*
    function getHRzone() {
        return mHeartRateZone;
    }*/

    // Return the total elapsed recording time
    function getTimeElapsed() {
        return mSeconds;
    }
    
    // Return the total secondary timer elapsed time
    function getSecondaryTimeElapsed() {
        return (mSecondarySeconds < 0)? 0 : mSecondarySeconds;
    }
    
    // Enable Secondary Timer Seconds
    function startSecondaryTimer(firstStart) {
        mSecondarySeconds = firstStart?0:-1;
    }
    
    // Resets Secondary Timer Seconds
    function resetSecondaryTimer() {
        mSecondarySeconds = -2;
    }
    
    // Gets array with minutes in each HR Zone
    function getZoneTimes(){
    
    	var hrZoneMinutes = new [5];
    	for( var i = 0; i < mZoneTimes.size(); i++ ) {
    		if(mZoneTimes[i] == null){
    			hrZoneMinutes[i] = 0; 
    		}
    		else {
            	hrZoneMinutes[i] = mZoneTimes[i] / 60; //(Math.round((mZoneTimes[i]*1.0) / 60)).toNumber();
            }
		}
    
    	return hrZoneMinutes; 
    }
    
    function getIntesityMinutes(){
    
    	var zt4 = (mZoneTimes[3]==null)?0:mZoneTimes[3]/60; //HR Zone 4 = Array Index 3
    	var zt5 = (mZoneTimes[4]==null)?0:mZoneTimes[4]/60; //HR Zone 5 = Array Index 4
    	
    	return zt4+zt5;
    }
    
    

    // Handle controller sensor events
    function setSensor(sensor_info) {
        if( sensor_info has :heartRate ) {
            if( sensor_info.heartRate != null ) {
                mHeartRate = sensor_info.heartRate;
                mHeartRate = mHeartRate == null? 0: mHeartRate;
                mStabilityTimer = 0;
                mStabilityOn = false;
            } else {
                // if HR stability is off or the timer has expired
                if ( mStability == false || mStabilityTimer > 9 ) {
                    //Log.debug("No HR Detected: Stability Off, Stability Timer Expired");
                    mHeartRate = 0;
                } else {
                   mStabilityOn = true;
                }
            }
        }
    }

    // HR Stability Setting
    //function setStability(option) {
    //    mStability = option;
    //}
    
    function setGPSTracking(option) {
    	mGPSOn = option;
    	if(mGPSOn == true) {Position.enableLocationEvents( Position.LOCATION_CONTINUOUS, method( :onPosition ));}
    }


	//Before Saving Workout get last values to the Activity class one for End WorkOut Screen
    function setStats() {
        var activity = Activity.getActivityInfo();
        if (activity != null){

            if ( activity.elapsedTime != null ) {
               mSeconds = activity.elapsedTime/1000;
            } 

            if ( activity.calories != null ) {
                mCalories = activity.calories;
            } else {
                mCalories = 0;
            }
            
           	if ( activity.maxHeartRate != null ) {
	            mPeakHR = activity.maxHeartRate;
	        } 
        
	        if ( activity.averageHeartRate != null ) {
	            mAverageHR = activity.averageHeartRate;
	        }

        }
    }
    
    
    function getHRZoneColorIndex(fHeartRate){
        
        // Gray Zone
        if ( fHeartRate < mZones[0] ) {
            return 1;
        // Blue Zone
        } else if ( fHeartRate < mZones[1] ) {
            return 2;
        // Green Zone
        } else if ( fHeartRate < mZones[2] ) {
            return 3;
        // Orange Zone
        } else if ( fHeartRate < mZones[3] ) {
            return 4;
        //Red Zone
        } else if ( fHeartRate >= mZones[3] ) {
            return 5;
        }
        
        return 0;
    }

    // Fetch HR Fields each second
    function hrFieldsCallback() {
    
        if( mHeartRate == null ) { return; }

        //Set Zone and Count Zone Seconds
        if ( mHeartRate < mZones[0] ) { // Gray Zone
            tz1++; //mHeartRateZone = 1;
        } else if ( mHeartRate < mZones[1] ) { // Blue Zone
            tz2++; //mHeartRateZone = 2;
        } else if ( mHeartRate < mZones[2] ) {  // Green Zone
            tz3++; //mHeartRateZone = 3;
        } else if ( mHeartRate < mZones[3] ) { // Orange Zone
            tz4++; //mHeartRateZone = 4;
        } else if ( mHeartRate >= mZones[3] ) { // Red Zone
            tz5++; //mHeartRateZone = 5;
        }

        mHeartRatePct = Math.round(( mHeartRate.toDouble() / mMaxHR.toDouble() ) * 100).toNumber();
        mZoneTimes = [ tz1, tz2, tz3, tz4, tz5 ];

		 var activity = Activity.getActivityInfo();
		 if (activity != null) {
		 
	        if ( activity.maxHeartRate != null ) {
	            mPeakHR = activity.maxHeartRate; 
	        } else {
	            mPeakHR = 0;
	        }
        
	        if ( activity.averageHeartRate != null ) {
	            mAverageHR = activity.averageHeartRate;
	        } else {
	            mAverageHR = 0;
	        }
	        
	        if ( activity.calories != null ) {
	            mCalories = activity.calories;
	        } else {
	            mCalories = 0;
	        }
        }

        // Increment timer
        mSeconds++;
        
        //Increment Secondary Timer if it has been started
        mSecondarySeconds = (mSecondarySeconds == -2) ? (-2):(mSecondarySeconds + 1);

        // Increment Stability timer if needed
        if ( mStabilityOn == true ) {
        	mStabilityTimer++;
            //Log.debug("Stability Mode On, Timer: " + mStabilityTimer);
        }
    }

    // Define the HR Zones from Garmin Profile
    hidden function setZones() {

        var birthYear = Profile.getProfile().birthYear;
        var todayYear = Time.Gregorian.info(Time.today(), Time.FORMAT_SHORT).year;
        var gender = Profile.getProfile().gender;

        // SDK 2.3.x Simulator Bug?
        if ( birthYear < 1900 ) {
            birthYear += 1900;
        }

        // Get the users age (will not be exact due to Garmin only providing users birth year)
        // If user has not provided a birth year or the device cannot get the current date
        // default max HR is set to 230
        if ( birthYear == null || todayYear == null ) {
            mMaxHR = 230;
        } else {
            var userAge = ( todayYear - birthYear );

            // If the user age is out of bounds set it to an age of 30 just for sanity
            if ( userAge <= 0 || userAge > 120 ) {
                userAge = 30;
            }

            if ( gender == 0 ) {
                //Log.debug("User Gender: Female");
                mMaxHR = ( 230 - userAge );
            } else {
                //Log.debug("User Gender: Male");
                mMaxHR = ( 225 - userAge );
            }

            // If we aren't getting a valid max HR
            if ( mMaxHR <= 0 || mMaxHR == null ) {
                mMaxHR = 230;
            }
            //Log.debug("User Age: " + userAge);
            //Log.debug("Max HR Set to: " + mMaxHR);
        }

		//Get Zones from Garmin User Profile
        var genericZoneInfo = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        mZones = [genericZoneInfo[1],genericZoneInfo[2],genericZoneInfo[3],genericZoneInfo[4]];  
    }

    // Set the recording activity type as per user preferences
    function setActivity(type, subType) {
        if(Toybox has :ActivityRecording) {
        // Create a new FIT recording session
        System.println("Activity Recording Type: " + type + " Sub: " + subType);
        mSession = Recording.createSession({:sport=>type, :subSport=>subType, :name => "HIIT Training"});
        //Log.debug("Activity Recording Type: " + type + " Sub: " + subType + "Act Str: "+ actType);
        }
    }
	
    function onPosition( info ) {
   		//System.println( "Position " + info.position.toGeoString( Position.GEO_DM ) + " Accurracy " + info.accuracy);
	}

}
