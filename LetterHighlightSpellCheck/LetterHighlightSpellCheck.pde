import com.swabunga.spell.engine.SpellDictionaryHashMap;
import com.swabunga.spell.event.SpellChecker;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Arrays;
import java.util.Map;
import java.util.Collections;


final static float DPI = 577; // For Ramya's Galaxy S6
final static float BASE_DPI = 165.63; // For Roger's
final static float DPI_Scale =  DPI / BASE_DPI;

final static float SIZE_OF_INPUT_AREA = DPI * 1; // aka, 1.0 inches square!
final static int INPUT_AREA_X = 200;
final static int INPUT_AREA_Y = 500;
// final static char[] ALPHABET = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'};
final static char[] ALPHABET = {'Q','W','E','R','T','Y','U','I','O','P','A','S','D','F','G','H','J','K','L','Z','X','C','V','B','N','M'};
final static int FIRST_ROW_LENGTH = 10;
final static int SECOND_ROW_LENGTH = 9;
final static int THIRD_ROW_LENGTH = 7;
final static int ROW_SPACING = 27 * (int)DPI_Scale;
final static int LETTER_SPACING = 8 * (int)DPI_Scale;
final static int KEYBOARD_FONT_SIZE = 16 * (int)DPI_Scale;
final static float KEY_RESIZE_THRESHOLD = 100 * DPI_Scale;
final static float KEYBOARD_VERTICAL_OFFSET = 70 * DPI_Scale; ///This changes based on DPI

PVector[] keyPositions = new PVector[ALPHABET.length];

String[] phrases; // contains all of the phrases
int totalTrialNum = 4; // the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; // the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; // a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; // a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; // a running total of the number of errors (when hitting next)
String currentPhrase = ""; // the current target phrase
String currentTyped = ""; // what the user has typed so far

//Text needle code
int time;
boolean tick;
int wait = 500;

//Backspace code
float backXPos = INPUT_AREA_X;
float backYPos = INPUT_AREA_Y;

float backWidth = SIZE_OF_INPUT_AREA/3;
float backHeight = SIZE_OF_INPUT_AREA/2;

//Autocompleter graphical parameters
float autoXPos = INPUT_AREA_X + SIZE_OF_INPUT_AREA/3;
float autoYPos = INPUT_AREA_Y;

float autoWidth = SIZE_OF_INPUT_AREA - SIZE_OF_INPUT_AREA/3;
float autoHeight = SIZE_OF_INPUT_AREA/2;

float autoCols = 1;
float autoRows = 2;

float textOffsetX = (autoWidth/autoCols)/2;
float textOffsetY = (autoHeight/autoRows)/2;

//Autocompleter code
protected static SuggestTree autoCompleter;
String[] suggestions = new String[(int) autoCols * (int) autoRows];


// You can modify anything in here. This is just a basic implementation.
void setup() {
  phrases = loadStrings("phrases2.txt"); // load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases)); // randomize the order of the phrases

  orientation(PORTRAIT); // can also be LANDSCAPE -- sets orientation on android device
  size(displayWidth, displayHeight); //Sets the size of the app. You may want to modify this to your device. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", KEYBOARD_FONT_SIZE)); // set the font to arial 24
  noStroke(); // my code doesn't use any strokes.

  setupAutoComplete();

  setupKeyboard();
}

void setupAutoComplete()
{
  //initializing suggestions
  for(int i = 0; i < suggestions.length; i++)
  suggestions[i] = "";
  
  //setting up the autocompleter
  String[] words = loadStrings("autoCompleteWords.txt"); //load the phrase set into memory
  String[] counts = loadStrings("autoCompleteCounts.txt"); //load the phrase set into memory
  
  //Setting up the timer
  time = millis();//store the current time
  
  Map<String, Long> freqDict = new HashMap<String, Long>();
  for(int i = 0; i < words.length; i++)
    freqDict.put(words[i].trim(), Long.parseLong(counts[i]));
  
  autoCompleter = new SuggestTree((int) autoCols * (int) autoRows);
  for (String word : freqDict.keySet())
  {
    autoCompleter.put(word, freqDict.get(word));
  }
}

void setupKeyboard() {
  float offsetX = 5 * DPI_Scale;
  float offsetY = ROW_SPACING + KEYBOARD_VERTICAL_OFFSET;
  for (int i = 0; i < FIRST_ROW_LENGTH; i++) {
    offsetX += LETTER_SPACING;
    keyPositions[i] = new PVector(INPUT_AREA_X + offsetX, INPUT_AREA_Y + offsetY);
    offsetX += LETTER_SPACING;
  }

  offsetX = 15 * DPI_Scale;
  offsetY += ROW_SPACING;
  for (int i = 0; i < SECOND_ROW_LENGTH; i++) {
    offsetX += LETTER_SPACING;
    keyPositions[i + FIRST_ROW_LENGTH] = new PVector(INPUT_AREA_X + offsetX, INPUT_AREA_Y + offsetY);
    offsetX += LETTER_SPACING;
  }

  offsetX = 25 * DPI_Scale;
  offsetY += ROW_SPACING;
  for (int i = 0; i < THIRD_ROW_LENGTH; i++) {
    offsetX += LETTER_SPACING;
    keyPositions[i + FIRST_ROW_LENGTH + SECOND_ROW_LENGTH] = new PVector(INPUT_AREA_X + offsetX, INPUT_AREA_Y + offsetY);
    offsetX += LETTER_SPACING;
  }
}

// You can modify anything in here. This is just a basic implementation.
void draw() {
  background(0); // clear background

  image(loadImage("watchhand3.png"), -200, 400);
  fill(100);
  rect(INPUT_AREA_X, INPUT_AREA_Y, SIZE_OF_INPUT_AREA, SIZE_OF_INPUT_AREA); // input area should be 2" by 2"

  if (finishTime != 0) {
    fill(255);
    textAlign(CENTER);
    text("Finished", 280, 150);
    return;
  }

  if (startTime == 0 && !mousePressed) {
    fill(255);
    textAlign(CENTER);
    text("Click to start time!", 280, 150); // display this messsage until the user clicks!
  }

  if (startTime == 0 && mousePressed) {
    nextTrial(); // start the trials!
  }

  if (startTime != 0) {
    textFont(createFont("Arial", 24)); // set the font to arial 24
    // you will need something like the next 10 lines in your code. Output does not have to be within the 2 inch area!
    textAlign(LEFT); // align the text left
    fill(128);
    text("Phrase " + (currTrialNum + 1) + " of " + totalTrialNum, 70, 50); // draw the trial count
    fill(255);
    text("Target:   " + currentPhrase, 70, 100); // draw the target string
    
    //Code for drawing the typed sentence
    if(millis() - time >= wait){
      tick = !tick;//if it is, do something
      time = millis();//also update the stored time
    }
    if(tick)
      text("Entered:  " + currentTyped + "|", 70, 140); //draw what the user has entered thus far 
    else
      text("Entered:  " + currentTyped, 70, 140); //draw what the user has entered thus far 
    
    fill(255, 0, 0);
    rect(800, 0, 200, 200); // drag next button
    fill(255);
    text("NEXT > ", 850, 100); // draw next label
  }

  drawKeyboard();
  
  drawBackspace();
  
  // Drawing the suggestions
  drawSuggestions();
}

void drawKeyboard() {
  fill(255);
  textAlign(CENTER);

  for (int i = 0; i < ALPHABET.length; i++) {
    float keyboardFontSize = KEYBOARD_FONT_SIZE;
    /*
    float dist = keyPositions[i].dist(new PVector(mouseX, mouseY));
    if (dist <= KEY_RESIZE_THRESHOLD) {
      keyboardFontSize = KEYBOARD_FONT_SIZE * 25/dist;
      
      if(keyboardFontSize > KEYBOARD_FONT_SIZE * 3)
        keyboardFontSize = KEYBOARD_FONT_SIZE * 3;
      if (keyboardFontSize < KEYBOARD_FONT_SIZE)
        keyboardFontSize = KEYBOARD_FONT_SIZE;
    }
    */
    textFont(createFont("Arial", keyboardFontSize)); // set the font to arial 24
    text(ALPHABET[i], keyPositions[i].x, keyPositions[i].y + keyboardFontSize/4);
  }

  textFont(createFont("Arial", KEYBOARD_FONT_SIZE)); // set the font to arial 24
}

void drawBackspace()
{
  //drawing the container for the backspace
    fill(255, 0, 0);
    rect(backXPos, backYPos, backWidth, backHeight);
    stroke(0);
    strokeWeight(5);
}

void drawSuggestions()
{
  //drawing the container for the suggestions
    fill(255, 255, 255);
    rect(autoXPos, autoYPos, autoWidth, autoHeight);
    stroke(0);
    strokeWeight(5);
    for(int i = 1; i < autoCols; i++)
    {
      line(autoXPos+ i * autoWidth/autoCols, autoYPos, autoXPos+ i * autoWidth/autoCols, autoYPos+autoHeight);
    }
    
    for(int i = 1; i < autoRows; i++)
    {
      line(autoXPos, autoYPos+ i * autoHeight/autoRows, autoXPos+autoWidth, autoYPos+ i * autoHeight/autoRows);
    }
    strokeWeight(0);
    
    //drawing the suggestions
    fill(0, 0, 0);
    for(int i = 0; i < autoRows; i++)
    {
      for(int j = 0; j < autoCols; j++)
      {
        text("" + suggestions[i * (int)autoCols + j], autoXPos + (j*autoWidth/autoCols)+ textOffsetX, autoYPos+ (i*autoHeight/autoRows)  + textOffsetY); 
      }
    }
}

void mousePressed() {

  // Check if the user clicked on the autocomplete entry
  for(int i = 0; i < autoRows; i++)
  {
    for(int j = 0; j < autoCols; j++)
    {
      if (didMouseClick(autoXPos + (j*autoWidth/autoCols), autoYPos + (i*autoHeight/autoRows), autoWidth/autoCols, autoHeight/autoRows)) //check if clicked a suggestion
      {
        completeWord(suggestions[i * (int)autoCols + j]);
        clearSuggestions();
        return;
      }
    }
  }
  
  //check for backspace
  if (didMouseClick(backXPos, backYPos, backWidth, backHeight)) {
    if(currentTyped.length() == 0)
      return;
    currentTyped = currentTyped.substring(0, currentTyped.length()-1);
    if(currentTyped.length() == 0)
      return;

    
    //Autocomplete & spellchecker code
    String currentWord = getCurrentWord(currentTyped); //gets the word we are currently typing
    
    if(currentWord.length() != 0){
      SuggestTree.Node wordNode = autoCompleter.getAutocompleteSuggestions(currentWord);
      if(wordNode != null)
      {
        for(int i = 0; i < wordNode.listLength(); i++)
        {
          if(i < suggestions.length)
          {
            suggestions[i] = wordNode.getSuggestion(i).getTerm();
          }
        }
      }
    }
    return;
  }
  
  // Check for user input
  if (didMouseClick(INPUT_AREA_X, INPUT_AREA_Y, SIZE_OF_INPUT_AREA, SIZE_OF_INPUT_AREA)) {
    currentTyped+=getNearestKey();
    
    //Autocomplete & spellchecker code
    String currentWord = getCurrentWord(currentTyped); //gets the word we are currently typing
    if(currentWord.trim() != ""){
      SuggestTree.Node wordNode = autoCompleter.getAutocompleteSuggestions(currentWord);
      if(wordNode != null)
      {
        for(int i = 0; i < wordNode.listLength(); i++)
        {
          if(i < suggestions.length)
          {
            suggestions[i] = wordNode.getSuggestion(i).getTerm();
          }
        }
      }
    }
  }

  // Check if click is in next button
  if (didMouseClick(800, 00, 200, 200)) {
    nextTrial(); // if so, advance to next trial
  }
}

// simple function to do hit testing
boolean didMouseClick(float x, float y, float w, float h) { return (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h); }

// get the nearest key to the current mouse
char getNearestKey() {
  PVector origin = new PVector(mouseX, mouseY);
  int nearest = 0;
  float currDist = MAX_FLOAT;

  for (int i = 0; i < ALPHABET.length; i++) {
    float dist = origin.dist(keyPositions[i]);
    if (dist < currDist) {
      nearest = i;
      currDist = dist;
    }
  }

  return Character.toLowerCase(ALPHABET[nearest]);
}

//Autocorrect helper functions
public String getCurrentWord(String sentence)
{
  return sentence.substring(sentence.lastIndexOf(" ")+1);
}

public void completeWord(String word)
{
  currentTyped = currentTyped.substring(0, currentTyped.lastIndexOf(" ")+1) + word + " ";
}

public void clearSuggestions()
{
  for(int i = 0; i < suggestions.length; i++)
  {
    suggestions[i] = "";
  }
}

void nextTrial() {
  if (currTrialNum >= totalTrialNum) // check to see if experiment is done
    return; // if so, just return

  if (startTime != 0 && finishTime == 0) { // in the middle of trials
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum + 1) + " of " + totalTrialNum); // output
    System.out.println("Target phrase: " + currentPhrase); // output
    System.out.println("Phrase length: " + currentPhrase.length()); // output
    System.out.println("User typed: " + currentTyped); // output
    System.out.println("User typed length: " + currentTyped.length()); // output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); // trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + (millis() - lastTime)); // output
    System.out.println("Time taken since beginning: " + (millis() - startTime)); // output
    System.out.println("==================");
    lettersExpectedTotal += currentPhrase.length();
    lettersEnteredTotal += currentTyped.length();
    errorsTotal += computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  if (currTrialNum == totalTrialNum - 1) { // check to see if experiment just finished
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); // output
    System.out.println("Total time taken: " + (finishTime - startTime)); // output
    System.out.println("Total letters entered: " + lettersEnteredTotal); // output
    System.out.println("Total letters expected: " + lettersExpectedTotal); // output
    System.out.println("Total errors entered: " + errorsTotal); // output
    System.out.println("WPM: " + (lettersEnteredTotal / 5.0f) / ((finishTime - startTime) / 60000f)); // output
    System.out.println("==================");
    currTrialNum++; // increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime == 0) { // first trial starting now
    System.out.println("Trials beginning! Starting timer..."); // output we're done
    startTime = millis(); // start the timer!
  } else {
    currTrialNum++; // increment trial number
  }

  lastTime = millis(); // record the time of when this trial ended
  currentTyped = ""; // clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  // currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}




// ========= SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL! ==============
// Computes error between two strings
int computeLevenshteinDistance(String phrase1, String phrase2)  {
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}