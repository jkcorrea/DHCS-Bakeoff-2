import java.util.Arrays;
import java.util.Collections;

final static int DPI = 320; // you will need to look up the DPI or PPI of your device to make sure you get the right scale!!
final static float SIZE_OF_INPUT_AREA = DPI * 1; // aka, 1.0 inches square!
final static int WATCHFACE_CORNER_RADIUS = 10;
final static int INPUT_AREA_X = 200;
final static int INPUT_AREA_Y = 500;
final static char[] ALPHABET = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'};
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

// You can modify anything in here. This is just a basic implementation.
void setup() {
  phrases = loadStrings("phrases2.txt"); // load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases)); // randomize the order of the phrases

  orientation(PORTRAIT); // can also be LANDSCAPE -- sets orientation on android device
  size(displayWidth, displayHeight); //Sets the size of the app. You may want to modify this to your device. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", 24)); // set the font to arial 24
  noStroke(); // my code doesn't use any strokes.

  setupKeyboard();
}

void setupKeyboard() {
  float radius = (SIZE_OF_INPUT_AREA / 2) - 25;
  float originX = INPUT_AREA_X + radius + 25;
  float originY = INPUT_AREA_Y + radius + 25;
  float arclength = 0;
  float letterSpacing = 16.2;

  for (int i = 0; i < ALPHABET.length; i++) {
    arclength += letterSpacing;
    float theta = arclength / radius;
    float x = originX + (radius * cos(theta));
    float y = originY + (radius * sin(theta));

    // Save letter position
    keyPositions[i] = new PVector(x, y);

    // Move halfway again
    arclength += letterSpacing;
  }
}

// You can modify anything in here. This is just a basic implementation.
void draw() {
  background(0); // clear background

  image(loadImage("watchhand3.png"), -200, 400);
  fill(100);
  rect(INPUT_AREA_X, INPUT_AREA_Y, SIZE_OF_INPUT_AREA, SIZE_OF_INPUT_AREA, WATCHFACE_CORNER_RADIUS); // input area should be 2" by 2"

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
    // you will need something like the next 10 lines in your code. Output does not have to be within the 2 inch area!
    textAlign(LEFT); // align the text left
    fill(128);
    text("Phrase " + (currTrialNum + 1) + " of " + totalTrialNum, 70, 50); // draw the trial count
    fill(255);
    text("Target:   " + currentPhrase, 70, 100); // draw the target string
    text("Entered:  " + currentTyped, 70, 140); // draw what the user has entered thus far
    fill(255, 0, 0);
    rect(800, 0, 200, 200); // drag next button
    fill(255);
    text("NEXT > ", 850, 100); // draw next label
  }

  // Draw the keyboard
    fill(255);
    textAlign(CENTER);
    for (int i = 0; i < ALPHABET.length; i++)
      text(ALPHABET[i], keyPositions[i].x, keyPositions[i].y);
}

void mousePressed() {

  // Check for user input
  if (didMouseClick(INPUT_AREA_X, INPUT_AREA_Y, SIZE_OF_INPUT_AREA, SIZE_OF_INPUT_AREA)) {
    getNearestKey();
  }

  // Check if click is in next button
  if (didMouseClick(800, 00, 200, 200)) {
    nextTrial(); // if so, advance to next trial
  }
}

// simple function to do hit testing
boolean didMouseClick(float x, float y, float w, float h) { return (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h); }

// get the nearest key to the current mouse
int getNearestKey() {
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

  println(ALPHABET[nearest]);
  return nearest;
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
