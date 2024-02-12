import processing.serial.*;

/*
ballX, ballY           = position of ball
ballW, ballH           = size of ball
ballSpeedX, ballSpeedY = movement speed of ball
P1X, P2X               = racket distance of player 1 and 2 from edges of play area
P1Y, P2Y               = racket position of player 1 and 2, to move up and down
racketW, racketH       = Size of racket
P1Speed, P2Speed       = Rate of up/down movement of player rackets
                         Changes depending on Z-value from accelerometer
speedMultiplier        = Makes the ball go faster after each racket bounce
P1color, P2color       = racket color
P1Serve, P2Serve       = 0/1 from sensor data from player controller, to serve the ball
P1Turn, P2Turn         = Checks who's turn it is to serve the ball
*/

Serial myPort;
String data = "";

String gameState = "Start";

int ballW = 50;
int ballH = 50; 
float ballX, ballY, ballSpeedX, ballSpeedY;
float speedMultiplier = 1.05;

int P1X, P2X, P1Y, P2Y;
int racketW = 20;
int racketH = 200;
float P1Speed, P2Speed;

int originalSpeed = 6;

int P1Score = 0;
int P2Score = 0;
int winScore = 5;

/* 
 Due to weird issues with how Arduino interprets information from Processing,
 the points were not able to be sent directly to Arduino as everything was 
 translated into ASCII code. We therefore chose to assign different game states
 with a number that Arduino could identify in ASCII, and manually add a point.
 */
int pointToP1 = 2;
int pointToP2 = 5;
int noPoints = 8;

int P1Serve = 0;
int P2Serve = 0;

// Due to packet loss from Player 2's transciever, these variables are used to eliminate unintentional serves
int P2Serve_raw = 0;
int P2Serve_counter = 0;
int P2Serve_counter_max = 60;

Boolean P1Turn = false;
Boolean P2Turn = false;

color P1color = color(255, 0, 0);
color P2color = color(0, 0, 255);

PFont font;


void setup() {
  String portName = Serial.list()[1];
  myPort = new Serial(this, portName, 9600); // enables communication with Arduino
  fullScreen();
  //size(1000, 1000);
  background(0);
  
  ballX = width/2;
  ballY = height/2;
  ballSpeedX = 6;
  ballSpeedY = 6;
  
  P1X = 40;
  P2X = width - 40;
  P1Y = height/2;
  P2Y = height/2;
  
  rectMode(CENTER);
  fill(255);
  font = loadFont("font.vlw");
  textSize(50);
  textFont(font);
  textAlign(CENTER, CENTER);
  delay(2000);
}


void draw() {
  background(0);
  if (gameState == "Start") {
    myPort.write(str(noPoints));
    drawBall();
    drawRacket();
    fill(255);
    text("Welcome to Pong! Player 1 - Serve to start!", width/2, height/3);
    delay(1000);
    if (P1Serve == 1) {
      gameState = "Game";
    }
  }
  
  if (gameState == "Serve") { // game state that handles serves when the ball has gone out of play
    drawBall();
    drawRacket();
    moveRacket();
    limitRackets();
    if (P1Turn == true) { // if player 2 scored, player 1 serves
      myPort.write(str(pointToP2)); // communicates to arduino that player 2 scored
      fill(P1color);
      text("Player 1 - Your turn!", width/2, height/3);
      ballY = P1Y;
      ballX = P1X + racketW*2;
      if (P1Serve == 1) {
        gameState = "Game";
      }    
    } else if (P2Turn == true) { // same as the above if-statement but for player 2
        myPort.write(str(pointToP1));
        fill(P2color);
        text("Player 2 - Your turn!", width/2, height/3);
        ballY = P2Y;
        ballX = P2X - racketW*2;
        if (P2Serve == 1) {
          gameState = "Game";
        }
      }
  }
  
  if (gameState == "Game") { // updates game arena when ball is in play
    drawBall();
    moveBall();
    checkBallAgainstEdges();
    drawRacket();
    moveRacket();
    limitRackets();
    racketBounce();
    score();
    gameOver();
    myPort.write(str(noPoints)); // communicates to Arduino that the ball is in play
  }

  if (gameState == "GameOver") { // when the max score has been reached, this ends the game
    myPort.write("1");
    P1Y = height/2;
    P2Y = height/2;
    ballX = width/2;
    ballY = height/2;
    ballSpeedX = originalSpeed;
    ballSpeedY = originalSpeed;
    myPort.write(str(noPoints));
    
    if (P1Score == winScore) {
      endScreen("Player 1 Wins!", P1color);
    }
    if (P2Score == winScore) {
      endScreen("Player 2 Wins!", P2color);
    }
  }
}


void serialEvent (Serial myPort) {
  // function that recieves sensor data from both players and assigns them accordingly
  // Can be modified if player wants inverted controls or use different tilt
  
  data = myPort.readStringUntil('\n');

  if (data != null) {
    data = trim(data);

    String items[] = split(data, ',');
    if (items.length == 8) {

      P1Speed = float(items[0]);
      P1Serve = int(items[3]);
      P2Speed = float(items[5]);
      P2Serve_raw = int(items[7]);
    } else {
      P2Serve_counter -= 1;
    }
  }
  
  // This eliminates accidental serves from player 2 due to packet loss
  if (P2Serve_raw == 1){
    P2Serve_counter += 1;
  } else {
    P2Serve_counter -= 1; 
  }
  if (P2Serve_counter <= 0){
    P2Serve_counter = 0; 
  }
  if (P2Serve_counter >= P2Serve_counter_max){
    P2Serve = 1;
    P2Serve_counter = P2Serve_counter_max; 
  } else {
    P2Serve = 0; 
  }
}


void drawBall() {
  //Draws the ball on to the game area
  fill(255);
  ellipse(ballX, ballY, ballW, ballH);
  
}


void moveBall() {
  //Moves ball to new position
  ballX = ballX + ballSpeedX;
  ballY = ballY + ballSpeedY;
}


void checkBallAgainstEdges() {
  //Bounces the ball off of top and bottom
  //if the ball touches the left or right, it resets the ball and gives points
  if (ballX < ballW/2) {
    ballSpeedX = originalSpeed;
    ballSpeedY = originalSpeed;
    P2Score += 1;
    P1Turn = true;
    P2Turn = false;
    gameState = "Serve";
  } else if (ballX > width - ballW/2) {
      ballSpeedX = -originalSpeed;
      ballSpeedY = -originalSpeed;
      P1Score += 1;
      P1Turn = false;
      P2Turn = true;
      gameState = "Serve";
    }
  if (ballY > height - ballH/2) {
    ballSpeedY = -ballSpeedY;
  } else if (ballY < ballH/2) {
      ballSpeedY = -ballSpeedY;
    }  
}


void drawRacket() {
  //Draws the rackets on to the game area
  fill(P1color);
  rect(P1X, P1Y, racketW, racketH);
  fill(P2color);
  rect(P2X, P2Y, racketW, racketH);
}


void moveRacket() {
  //Moves rackets depending on user input 
  P1Y += round(P1Speed);
  P2Y += round(P2Speed);
}


void limitRackets() {
  //Limits rackets to the game area 
  if (P1Y - racketH/2 < 0) {
    P1Y = racketH/2;
  }
  if (P1Y + racketH/2 > height) {
    P1Y = height - racketH/2;
  }
  if (P2Y - racketH/2 < 0) {
    P2Y = racketH/2;
  }
  
  if (P2Y + racketH/2 > height) {
    P2Y = height - racketH/2;
  }
}


void racketBounce() {
  //Checks if the ball touches the rackets, adjusts bounce depending on where the ball struck
  if (ballX - ballW/2 < P1X + racketW/2 && ballY - ballH/2 < P1Y + racketH/2 && ballY + ballH/2 > P1Y - racketH/2 ) {
    ballSpeedX = -ballSpeedX*speedMultiplier;
    if (ballY - ballH > P1Y + racketH/3) {
      ballSpeedY = abs(ballSpeedY)*1.2;
    } 
      else if (ballY + ballH < P1Y - racketH/3) {
        ballSpeedY = -abs(ballSpeedY)*1.2;
      } 
        else if (ballY - ballH < P1Y + racketH/10 && ballY + ballH > P1Y - racketH/10) {
          ballSpeedY = ballSpeedY*0.92;
        }
  }
  else if (ballX + ballW/2 > P2X - racketW/2 && ballY - ballH/2 < P2Y  + racketH/2 && ballY + ballH/2 > P2Y - racketH/2 ) {
    ballSpeedX = -ballSpeedX*speedMultiplier;
    if (ballY - ballH > P2Y + racketH/3) {
      ballSpeedY = abs(ballSpeedY)*1.2;
    } 
      else if (ballY + ballH < P2Y - racketH/3) {
        ballSpeedY = -abs(ballSpeedY)*1.2;
      }  
        else if (ballY - ballH < P2Y + racketH/10  && ballY + ballH > P2Y - racketH/10) {
           ballSpeedY = ballSpeedY*0.8;
         }
  }
}

void score() {
  //Displays the score
  fill(P1color);
  text(P1Score, width/2-40, 20);
  fill(P2color);
  text(P2Score, width/2+40, 20);
}

void gameOver() {
  //Checks for a winner 
  if (P1Score == winScore) {
    gameState = "GameOver";
  }
  if (P2Score == winScore) {
    gameState = "GameOver";
  }
}


void endScreen(String text, color winner) {
  //Creates the end game screen with the ability to restart
  fill(255);
  text("Game Over", width/2, height/3-40);
  fill(winner);
  text(text, width/2, height/3);
  fill(255);
  text("To play again, twist both controllers to the right", width/2, height/3+40);
  if (P1Speed >= 9 && -(P2Speed) >= 9) {
    gameState = "Start";
    P1Score = 0;
    P2Score = 0;
  }
}
