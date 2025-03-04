# Sensor Programming Project

## By

Durim Sadiku
Jimmy Mäkinen

## Collaboration Group

Fredrik Svanholm
Lucas Von Scheele

## Project Description

In this project, we built a handheld motion controller in the shape of a steering wheel using an Arduino Uno microcontroller that was used to play a version of Pong. The controller utilized a nRF24L01 transceiver module to wirelessly transmit and receive data from the controller created by the collaboration group, to play the game against each other. The controller uses an ADXL345 accelerometer module to measure the intensity of controller movement in 3 axes. 

Pong was programmed in Processing, a simplified version of Java. The main controller received the accelerometer data from the collaboration group and sent the data from both controllers to Processing to convert it into paddle movement.

## Sensors and actuators used

- ADXL345 accelerometer: Produces accelerometer data to measure the controller's movement.
- nRF24L01 transceiver: Receives or transmits controller accelerometer and IR sensor data.
- Adafruit Monochrome 128x64 OLED display: Displays current score on the screen.
- Infrared sensor: An IR sensor that produces a boolean value, obstacle or no obstacle. Used to simulate a serve, or to start the game when a point is scored or has ended.

