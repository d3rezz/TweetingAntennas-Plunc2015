import processing.serial.*;
import cc.arduino.*;
import oauthP5.oauth.*;
import oauthP5.apis.*;
import java.util.Date;


//define arduino pins here
int direction_pin1 = 7;
int steps_pin1 = 8;

int direction_pin2 = 2;
int steps_pin2 = 4;

int num_teeth_small = 24;
int num_teeth_big = 126;

int speed = 1;

int output1;
int output2;


//Twitter stuff;
final String READ_URL_CAIS = "https://api.twitter.com/1.1/search/tweets.json?geocode=38.7059946,-9.1435078,2km&result_type=recent&since_id="; //
final String READ_URL_CASA = "https://api.twitter.com/1.1/search/tweets.json?geocode=38.6841628,-9.1591074,2km&result_type=recent&since_id="; //
final String READ_URL_KEYWORD = "https://api.twitter.com/1.1/search/tweets.json?q=plunc&result_type=recent&since_id=";   //hashtag is %23


final String POST_URL = "https://api.twitter.com/1/statuses/update.json";
final String CONSUMER_KEY = ""; // use your own app's key...
final String CONSUMER_SECRET = "";
final String TOKEN = "";
final String TOKEN_SECRET="";

// OAuth
OAuthService service = new ServiceBuilder()
    .provider(TwitterApi.class)
      .apiKey(CONSUMER_KEY)
        .apiSecret(CONSUMER_SECRET)
          .build();
Token accessToken = new Token(TOKEN, TOKEN_SECRET);

//Messages Stuff
StringList messages = new StringList();
long lastId_cais = 0;
long lastId_casa = 0;
long lastId_keyword = 0;

int timeLastTweets = -1000000;
int timeTweetFetching = 1000*90;
int timeShowingChar = 2000;  //ms


final String alphabet="abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ#áéóÁÉÓãõÃÕêôÊÔ";
int[][] positions = {{2,1},     //a
                    {3,1},      //b
                    {4,1},      //c
                    {5,1},      //d
                    {1,4},      //e
                    {1,3},      //f
                    {1,2},      //g
                    {3,0},      //h
                    {5,0},      //i
                    {5,3},      //j
                    {2,5},      //k
                    {2,4},      //l
                    {2,3},      //m
                    {2,2},      //n
                    {3,6},      //o
                    {3,5},      //p
                    {3,4},      //q
                    {3,3},      //r
                    {3,2},      //s
                    {4,5},      //t
                    {4,4},      //u
                    {5,2},      //v
                    {6,3},      //w
                    {6,2},      //x
                    {4,3},      //y
                    {0,3},      //z
                    {1,1},     //space
                    {2,1},     //A
                    {3,1},      //B
                    {4,1},      //C
                    {5,1},      //d
                    {1,4},      //e
                    {1,3},      //f
                    {1,2},      //g
                    {3,0},      //h
                    {5,0},      //i
                    {5,3},      //j
                    {2,5},      //k
                    {2,4},      //l
                    {2,3},      //m
                    {2,2},      //n
                    {3,6},      //o
                    {3,5},      //p
                    {3,4},      //q
                    {3,3},      //r
                    {3,2},      //s
                    {4,5},      //t
                    {4,4},      //u
                    {5,2},      //v
                    {6,3},      //w
                    {6,2},      //x
                    {4,3},      //y
                    {0,3},      //Z
                    {5,4},     //#
                    
                    //PT LETTERS
                    {2,1},     //á
                    {1,4},     //é
                    {3,6},     //ó
                    {2,1},     //Á
                    {1,4},     //É
                    {3,6},     //Ó
                    {2,1},     //ã
                    {3,6},     //õ
                    {2,1},     //Ã
                    {3,6},     //Õ
                    {1,4},     //ê
                    {3,6},     //ô
                    {1,4},     //Ê
                    {3,6}};     //Ô
                    
int currentCharPos;

int currentSteps1;
int goalSteps1;
int currentSteps2;
int goalSteps2;

int savedTime_steps;


Arduino arduino;

void setup(){
  currentCharPos = 0;
  currentSteps1 = 131;
  goalSteps1 = 131;
  currentSteps2 = 131;
  goalSteps2 = 131;
  savedTime_steps = millis();
  output1 = 0;
  output2 = 0;
  
  //Setup arduino
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  arduino.pinMode(steps_pin1, Arduino.OUTPUT); 
  arduino.pinMode(direction_pin1, Arduino.OUTPUT); 
  arduino.pinMode(steps_pin2, Arduino.OUTPUT); 
  arduino.pinMode(direction_pin2, Arduino.OUTPUT); 
  
  //update last ids
  getLastTweetId();
}

void draw(){
  getTweets();
  moveMotors();
}


void moveMotors(){
  
  if (messages.size() > 0 ) {  
    try{
      
      int steps1 = posToSteps(positions[alphabet.indexOf(messages.get(0).charAt(currentCharPos))][0]);
      goalSteps1 = steps1;
      
      int steps2 = posToSteps(positions[alphabet.indexOf(messages.get(0).charAt(currentCharPos))][1]);
      goalSteps2 = steps2;
    }catch(Exception e){
      println("Invalid Character");
      goalSteps1 = currentSteps1;
      goalSteps2 = currentSteps2;
    }
  } else {
    //there are no tweets
    goalSteps1 = 131;
    goalSteps2 = 131;
  }
  
  //See if time to move motors has passed
  int passedTime_steps = millis()-savedTime_steps;
  if(passedTime_steps > speed){
    //Move motor 1
    if(goalSteps1 > currentSteps1){
      arduino.digitalWrite(direction_pin1, Arduino.HIGH);
      //move once
      if( output1 == 0 ){
        arduino.digitalWrite(steps_pin1, Arduino.HIGH);
        output1 = 1;
      } else {
        arduino.digitalWrite(steps_pin1, Arduino.LOW);
        output1 = 0;
        currentSteps1++;
      }
    }
    if(goalSteps1 < currentSteps1){
      arduino.digitalWrite(direction_pin1, Arduino.LOW);
      //move once
      if( output1 == 0 ){
        arduino.digitalWrite(steps_pin1, Arduino.HIGH);
        output1 = 1;
      } else {
        arduino.digitalWrite(steps_pin1, Arduino.LOW);
        output1 = 0;
        currentSteps1--;
      }
    }
    
    //Move motor 2
    if(goalSteps2 > currentSteps2){
      arduino.digitalWrite(direction_pin2, Arduino.LOW);
      //move once
      if( output2 == 0 ){
        arduino.digitalWrite(steps_pin2, Arduino.HIGH);
        output2 = 1;
      } else {
        arduino.digitalWrite(steps_pin2, Arduino.LOW);
        output2 = 0;
        currentSteps2++;
      }
    }
    if(goalSteps2 < currentSteps2){
      arduino.digitalWrite(direction_pin2, Arduino.HIGH);
      //move once
      if( output2 == 0 ){
        arduino.digitalWrite(steps_pin2, Arduino.HIGH);
        output2 = 1;
      } else {
        arduino.digitalWrite(steps_pin2, Arduino.LOW);
        output2 = 0;
        currentSteps2--;
      }
    }
     
    
    
    savedTime_steps = millis();
    //println("Current Steps Changed: "+ currentSteps1 +" " + currentSteps2);
  }
  
  
  if(goalSteps1 == currentSteps1 && goalSteps2 == currentSteps2){
    if( messages.size() > 0) {
       delay(timeShowingChar);  
      //go to next char
      currentCharPos++;
      if(currentCharPos>=messages.get(0).length()){
        //finished message
        messages.remove(0);
        currentCharPos = 0;
      }
      
      if(messages.size()> 0 ) {
        println("Current Char: "+messages.get(0).charAt(currentCharPos)+", "+currentCharPos);
      }
    } else {
      //println("There are no tweets");
    }
  }
}
    
    
//Helper functions
int posToSteps(int pos){
  return (pos*1048)/8;
}


void getLastTweetId() {
  //Last id Cais
  OAuthRequest request = new OAuthRequest(Verb.GET, READ_URL_CAIS);
  service.signRequest(accessToken, request);

  // No query parameters for our read-only case.
  Response response = request.send();


  if (response.getCode() == 200) {
    //println(response);
    JSONObject json = JSONObject.parse(response.getBody());
    JSONArray data = json.getJSONArray("statuses");
    JSONObject elem = data.getJSONObject(0);
    long elem_id = Long.parseLong(elem.getString("id_str"));
    
    //getLastId
    lastId_cais = elem_id;
    println("Last ID Cais" + lastId_cais);
  } else {
    println("ERROR: cant get lastID_cais");
  }
  
   //Last id Casa
  request = new OAuthRequest(Verb.GET, READ_URL_CAIS);
  service.signRequest(accessToken, request);

  // No query parameters for our read-only case.
  response = request.send();


  if (response.getCode() == 200) {
    //println(response);
    JSONObject json = JSONObject.parse(response.getBody());
    JSONArray data = json.getJSONArray("statuses");
    JSONObject elem = data.getJSONObject(0);
    long elem_id = Long.parseLong(elem.getString("id_str"));
    
    //getLastId
    lastId_casa = elem_id;
    println("Last ID Casa" + lastId_casa);
  } else {
    println("ERROR: cant get lastID_casa");
  }
  
   //Last id Keyword
  request = new OAuthRequest(Verb.GET, READ_URL_KEYWORD);
  service.signRequest(accessToken, request);

  // No query parameters for our read-only case.
  response = request.send();


  if (response.getCode() == 200) {
    //println(response);
    JSONObject json = JSONObject.parse(response.getBody());
    JSONArray data = json.getJSONArray("statuses");
    JSONObject elem = data.getJSONObject(0);
    long elem_id = Long.parseLong(elem.getString("id_str"));
    
    //getLastId
    lastId_keyword = elem_id;
    println("Last ID Keyword" + lastId_keyword);
  } else {
    println("ERROR: cant get lastID_keyword");
  }
}


void getTweets() {
  if ((millis() - timeLastTweets) >= timeTweetFetching) {
    println("Fetching new tweets...");
    println("1 minute has passed");
    timeLastTweets = millis();


    //Get Tweets Cais
    OAuthRequest request = new OAuthRequest(Verb.GET, READ_URL_CAIS + lastId_cais);
    service.signRequest(accessToken, request);

    // No query parameters for our read-only case.
    Response response;
    try {
      response = request.send();
    } catch(Exception e) {
      println("No Internet connection available...");
      return;
    }


    if (response.getCode() == 200) {
      //println(response);
      JSONObject json = JSONObject.parse(response.getBody());
      JSONArray data = json.getJSONArray("statuses");
      println("Tweets Cais:");
      for (int i=data.size()-1; i>=0; i--) {
        JSONObject elem = data.getJSONObject(i);
        println(elem.getString("text"));
        println("Tweet parsed: " + removeLinkAndLocation(elem.getString("text")) );
        long elem_id = Long.parseLong(elem.getString("id_str"));
        println("ID " + elem_id);
        
        println((new Date().getTime() - new Date(elem.getString("created_at")).getTime())/1000/60/60 );
        //you could filter them by date.
        messages.append(removeLinkAndLocation(elem.getString("text")));

        //getLastId
        if (elem_id >= lastId_cais) {  
         lastId_cais = elem_id;
          println("Last ID Cais" + lastId_cais);
        }
      }

      
    } else {
      println("Error fetching Cais Tweets");
    }
    
    //Get Tweets Casa
    request = new OAuthRequest(Verb.GET, READ_URL_CASA + lastId_casa);
    service.signRequest(accessToken, request);

    // No query parameters for our read-only case.
    response = request.send();


    if (response.getCode() == 200) {
      //println(response);
      JSONObject json = JSONObject.parse(response.getBody());
      JSONArray data = json.getJSONArray("statuses");
      println("Tweets Casa:");
      for (int i=data.size()-1; i>=0; i--) {
        JSONObject elem = data.getJSONObject(i);
        println(elem.getString("text"));
         println("Tweet parsed: " + removeLinkAndLocation(elem.getString("text")) );
        long elem_id = Long.parseLong(elem.getString("id_str"));
        println("ID " + elem_id);
        
        println((new Date().getTime() - new Date(elem.getString("created_at")).getTime())/1000/60/60 );
        //you could filter them by date.
        messages.append(removeLinkAndLocation(elem.getString("text")));

        //getLastId
        if (elem_id >= lastId_casa) {  
         lastId_casa = elem_id;
          println("Last ID Casa" + lastId_casa);
        }
      }

    } else {
      println("Error fetching Casa tweets.");
    }
    
    
    
    //Get Tweets Keyword
    request = new OAuthRequest(Verb.GET, READ_URL_KEYWORD + lastId_keyword);
    service.signRequest(accessToken, request);

    // No query parameters for our read-only case.
    response = request.send();


    if (response.getCode() == 200) {
      //println(response);
      JSONObject json = JSONObject.parse(response.getBody());
      JSONArray data = json.getJSONArray("statuses");
      println("Tweets keyword:");
      for (int i=data.size()-1; i>=0; i--) {
        JSONObject elem = data.getJSONObject(i);
        println(elem.getString("text"));
         println("Tweet parsed: " + removeLinkAndLocation(elem.getString("text")) );
        long elem_id = Long.parseLong(elem.getString("id_str"));
        println("ID " + elem_id);
        
        println((new Date().getTime() - new Date(elem.getString("created_at")).getTime())/1000/60/60 );
        //you could filter them by date.
        //add element in beginning
        messages.reverse();
        messages.append(removeLinkAndLocation(elem.getString("text")));
        messages.reverse();

        //getLastId
        if (elem_id >= lastId_keyword) {  
         lastId_keyword = elem_id;
          println("Last ID Keyword" + lastId_keyword);
        }
      }
    } else {
      println("Error fetching keyword tweets");
    }
    
    println("Finished fetching tweets. Tweets in queue: "+messages.size());
  }
  
   //println("Messages in Queue");
   //println(messages);
}


String removeLinkAndLocation(String str) {
  //Remove location
  str = str.split("@", 2)[0];

  //remove link
  str = str.split("http", 2)[0];
  
  return str;
}
