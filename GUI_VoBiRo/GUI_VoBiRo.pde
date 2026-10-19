import controlP5.*;
import java.net.DatagramSocket;
import java.net.DatagramPacket;
import java.net.InetAddress;

// ==========================================
// DEKLARASI VARIABEL UTAMA & GUI
// ==========================================
ControlP5 cp5;
robot vobiro;
PImage logo;

// ==========================================
// VARIABEL KALIBRASI JOINT (CONTROL P5)
// ==========================================
int numerator = 0;
boolean HIP_YAW_RIGHT_OFFSET, HIP_ROLL_RIGHT_OFFSET, HIP_PITCH_RIGHT_OFFSET;
boolean KNEE_PITCH_RIGHT_OFFSET, FOOT_PITCH_RIGHT_OFFSET, FOOT_ROLL_RIGHT_OFFSET;
boolean HIP_YAW_LEFT_OFFSET, HIP_ROLL_LEFT_OFFSET, HIP_PITCH_LEFT_OFFSET;
boolean KNEE_PITCH_LEFT_OFFSET, FOOT_PITCH_LEFT_OFFSET, FOOT_ROLL_LEFT_OFFSET;

float r_hip_yaw_ = 0, r_hip_roll_ = 0, r_hip_pitch_ = 0;
float r_knee_pitch_ = 0, r_ankle_pitch_ = 0, r_ankle_roll_ = 0;
float l_hip_yaw_ = 0, l_hip_roll_ = 0, l_hip_pitch_ = 0;
float l_knee_pitch_ = 0, l_ankle_pitch_ = 0, l_ankle_roll_ = 0;

// ==========================================
// VARIABEL TUNING PARAMETER
// ==========================================
boolean testMotion = false;
float valPeriod    = 600.0;
float valXOffset   = 10.0;
float valZOffset   = 25.0; // Hip Height
float valYOffset   = 1.0;  // Hip Plane
float valFootH     = 40.0;
float valSwingRL   = 18.0;
float valArmSwing  = 1.5;
float valDSR       = 16.0; // DSR menggantikan posisi Pelvis_Off

String currentMode  = "Standby";

// ==========================================
// VARIABEL DATA WEBOTS & JARINGAN
// ==========================================
float gyroY = 0, gyroZ = 0;
float footTrajZR = 0, footTrajZL = 0;

// Variabel Pitch (Maju/Mundur)
float hipPitchR = 0, kneePitchR = 0, anklePitchR = 0;
float hipPitchL = 0, kneePitchL = 0, anklePitchL = 0;
float sPitchR = 0, ePitchR = 0, sPitchL = 0, ePitchL = 0;

// Variabel Yaw & Roll Pinggul
float hipYawR = 0, hipRollR = 0;
float hipYawL = 0, hipRollL = 0;

// Variabel memori untuk deteksi Status
float prevHipR = 0, prevKneeR = 0, prevAnkleR = 0;
float prevHipL = 0, prevKneeL = 0, prevAnkleL = 0;
String statR = "", statL = "";

String statusKoneksi = "TERPUTUS";
int lastPacketTime = 0;

DatagramSocket udpSocket;
Thread receiveThread;
String webotsIP = "127.0.0.1";
int webotsPort = 12001, listenPort = 12345;

// ==========================================
// VARIABEL PERHITUNGAN KECEPATAN & JARAK & FALL DETECT
// ==========================================
float currentDistance = 0.0; // Dalam meter
float currentSpeed = 0.0;    // Dalam m/s
int startTimeMs = 0;
boolean isWalkingPhase = false;
String fallStatus = "Normal";

// Konstanta mekanis (harus sesuai dengan Webots/Paper)
final float STEP_LENGTH_CM_MAX = 13.1; // Contoh max step length
final float CYCLE_LENGTH_M = (STEP_LENGTH_CM_MAX * 2) / 100.0;

// ==========================================
// TEMA WARNA GRAFIK
// ==========================================
color cBg        = color(44, 76, 116);
color cCard      = color(255, 255, 255);
color cTextDark  = color(44, 76, 116);
color cLineB     = color(30, 136, 229); // Blue
color cLineR     = color(231, 76, 60);  // Red
color cLineO     = color(243, 156, 18); // Orange
color cLineG     = color(46, 204, 113); // Green
color cLineP     = color(155, 89, 182); // Purple

color[] colorsL = { cLineB, cLineG, cLineO };
color[] colorsR = { cLineR, cLineG, cLineO };
color[] colorsFootZ = { cLineG, cLineR }; // Hijau Kiri, Merah Kanan
color[] colorsIMU = { cLineP, cLineG }; // Ungu (Roll), Hijau (Pitch)

int maxGraphPoints = 250;
FloatList[] histLegL = { new FloatList(), new FloatList(), new FloatList() };
FloatList[] motorHistLegR = { new FloatList(), new FloatList(), new FloatList() };

FloatList[] histFootZ = { new FloatList(), new FloatList() };
FloatList[] histIMU = { new FloatList(), new FloatList() };
FloatList histCoMZ = new FloatList(), histCoMY = new FloatList();

// ==========================================
// VARIABEL KHUSUS REKAM DATA EXCEL (CSV)
// ==========================================
Table excelLogTable;
boolean isLoggingActive = false;

// ==========================================
// VARIABEL INPUT KEYBOARD PADA KAPSUL
// ==========================================
// -1: Tidak ada yang aktif, 0-7: Kapsul aktif
int activePillIndex = -1;
String currentInputBuffer = "";
// Menghitung kedipan kursor
int cursorBlinkFrame = 0;

void setup() {
  fullScreen(P3D);
  smooth(8);

  println("Memuat UI dan Objek 3D... Mohon tunggu!");
  try {
    logo = loadImage("logo.png");
    if (logo != null) logo.resize(0, 70);
  }
  catch(Exception e) {
  }

  cp5 = new ControlP5(this);
  vobiro = new robot();

  println("Selesai memuat!");
  initUDPReceiver();
}

void draw() {
  background(cBg);

  if (millis() - lastPacketTime > 2000) statusKoneksi = "TERPUTUS";
  set_offset_joint();

  // ==========================================
  // DATA SIMULASI / UPDATE VARIABEL
  // ==========================================
  float currentHipR   = testMotion ? sin(frameCount * 0.04) * 0.4 : hipPitchR;
  float currentKneeR  = testMotion ? (sin(frameCount * 0.04 - PI/2) + 1) * 0.5 : kneePitchR;
  float currentAnkleR = testMotion ? sin(frameCount * 0.04) * -1: anklePitchR;
  float currentHipYawR  = testMotion ? sin(frameCount * 0.05) * 0.2 : hipYawR;
  float currentHipRollR = testMotion ? cos(frameCount * 0.04) * 0.2 : hipRollR;

  float currentHipL   = testMotion ? sin(frameCount * 0.04 + PI) * 0.4 : hipPitchL;
  float currentKneeL  = testMotion ? (sin(frameCount * 0.04 + PI - PI/2) + 1) * 0.5 : kneePitchL;
  float currentAnkleL = testMotion ? sin(frameCount * 0.04 + PI) * -1 : anklePitchL;
  float currentHipYawL  = testMotion ? sin(frameCount * 0.05 + PI) * 0.2 : hipYawL;
  float currentHipRollL = testMotion ? cos(frameCount * 0.04 + PI) * 0.2 : hipRollL;

  float currentSPitchR = testMotion ? sin(frameCount * 0.04 + PI) * 0.3 : sPitchR;
  float currentEPitchR = testMotion ? -0.5 + sin(frameCount * 0.04 + PI)*1.2 : ePitchR;
  float currentSPitchL = testMotion ? sin(frameCount * 0.04) * 0.3 : sPitchL;
  float currentEPitchL = testMotion ? -0.5 + sin(frameCount * 0.04)*1.2 : ePitchL;

  float currentCoMY = testMotion ? sin(frameCount * 0.05) * 0.3 : gyroY;
  float currentCoMZ = testMotion ? cos(frameCount * 0.05) * 0.3 : gyroZ;

  float currentFootZL = testMotion ? max(0, sin(frameCount * 0.08) * 1.5) : (4.8 - footTrajZL);
  float currentFootZR = testMotion ? max(0, -sin(frameCount * 0.08) * 1.5) : (4.8 - footTrajZR);

  float velR = abs(currentHipR - prevHipR) + abs(currentKneeR - prevKneeR) + abs(currentAnkleR - prevAnkleR);
  float velL = abs(currentHipL - prevHipL) + abs(currentKneeL - prevKneeL) + abs(currentAnkleL - prevAnkleL);

  statR = (velR > 0.005) ? "RIGHT FOOT" : "";
  statL = (velL > 0.005) ? "LEFT FOOT" : "";

  // Deteksi Jatuh Sederhana berdasarkan IMU (Roll / Pitch terlalu miring)
  if (abs(currentCoMY) > 0.8 || abs(currentCoMZ) > 0.8) {
    fallStatus = "FALL DETECTED!";
    currentSpeed = 0;
  } else {
    fallStatus = "Normal";

    if (currentMode.equals("Line Follower") || currentMode.equals("Forward")) {
      if (!isWalkingPhase) {
        isWalkingPhase = true;
        startTimeMs = millis();
      }
      float cyclesPerSec = 1000.0 / valPeriod;
      currentSpeed = CYCLE_LENGTH_M * cyclesPerSec * 0.5;
      currentDistance += currentSpeed * (1.0/60.0);
    } else {
      isWalkingPhase = false;
      currentSpeed = 0;
    }
  }

  prevHipR = currentHipR;
  prevKneeR = currentKneeR;
  prevAnkleR = currentAnkleR;
  prevHipL = currentHipL;
  prevKneeL = currentKneeL;
  prevAnkleL = currentAnkleL;

  updateGraphs(currentHipL, currentKneeL, currentAnkleL, currentHipR, currentKneeR, currentAnkleR, currentFootZL, currentFootZR, currentCoMZ, currentCoMY);

  // LOGIKA PEREKAMAN DATA REAL-TIME EXCEL
  if (isLoggingActive) {
    TableRow newRow = excelLogTable.addRow();
    newRow.setInt("Timestamp_ms", millis());
    newRow.setFloat("Foot_Trajectory_Z_Left", currentFootZL);
    newRow.setFloat("Foot_Trajectory_Z_Right", currentFootZR);
    newRow.setFloat("CoM_Y_Roll", currentCoMY);
    newRow.setFloat("CoM_Z_Pitch", currentCoMZ);
    newRow.setFloat("Speed_m_s", currentSpeed);
    newRow.setFloat("Distance_m", currentDistance);
    newRow.setString("Fall_Status", fallStatus);
  }

  // ==========================================
  // RENDER LAYER 2D GUI MODERN & GRAFIK
  // ==========================================
  hint(DISABLE_DEPTH_TEST);
  drawDashboardGUI();
  hint(ENABLE_DEPTH_TEST);

  // ==========================================
  // RENDER 3D VIEWPORT KINEMATIKA ROBOT
  // ==========================================
  vobiro.rotFoot_Right(degrees(currentHipYawR) + r_hip_yaw_, degrees(currentHipR) + r_hip_pitch_, degrees(currentHipRollR) + r_hip_roll_, degrees(currentKneeR) + r_knee_pitch_, degrees(currentAnkleR) + r_ankle_pitch_, r_ankle_roll_);
  vobiro.rotFoot_Left(degrees(currentHipYawL) + l_hip_yaw_, degrees(currentHipL) + l_hip_pitch_, degrees(currentHipRollL) + l_hip_roll_, degrees(currentKneeL) + l_knee_pitch_, degrees(currentAnkleL) + l_ankle_pitch_, l_ankle_roll_);

  vobiro.rotHand_Right(degrees(currentSPitchR), 15, 0, -degrees(currentEPitchR)*3);
  vobiro.rotHand_Left(degrees(currentSPitchL), 15, 0, -degrees(currentEPitchL)*3);

  if (fallStatus.equals("FALL DETECTED!")) {
    vobiro.rotBody(45);
  } else {
    vobiro.rotBody(10);
  }

  vobiro.rotHead(0, 0);

  pushMatrix();
  translate(width * 0.80, height * 0.40, 0);

  lights();
  ambientLight(180, 180, 180);
  directionalLight(255, 255, 255, 0, 0, -1);
  directionalLight(120, 130, 140, -1, 1, -0.5);

  if (mousePressed && mouseX > width * 0.70 && mouseY > 200) {
    rotateX(map(mouseY, 0, height, PI, -PI));
    rotateY(map(mouseX, width * 0.75, width, -PI, PI));
  } else {
    rotateX(radians(0));
    rotateY(radians(-40));
  }

  scale(1.8);
  fill(240);
  noStroke();
  vobiro.update();
  popMatrix();
}

// ==========================================
// FUNGSI GUI GRAFIK & DESAIN
// ==========================================
void updateGraphs(float hl, float kl, float al, float hr, float kr, float ar, float fzl, float fzr, float cz, float cy) {
  histLegL[0].append(hl);
  histLegL[1].append(kl);
  histLegL[2].append(al);
  motorHistLegR[0].append(hr);
  motorHistLegR[1].append(kr);
  motorHistLegR[2].append(ar);
  histFootZ[0].append(fzl);
  histFootZ[1].append(fzr);

  histCoMZ.append(cz);
  histCoMY.append(cy);
  histIMU[0].append(cy);
  histIMU[1].append(cz);

  if (histLegL[0].size() > maxGraphPoints) {
    for (int i=0; i<3; i++) {
      histLegL[i].remove(0);
      motorHistLegR[i].remove(0);
    }
    histFootZ[0].remove(0);
    histFootZ[1].remove(0);
    histCoMZ.remove(0);
    histCoMY.remove(0);
    histIMU[0].remove(0);
    histIMU[1].remove(0);
  }
}

void drawDashboardGUI() {
  float startX = 60;
  float startY = 40;

  float leftW = 580;
  float leftH = 185;
  float gapY  = 35;

  float midX = startX + leftW + 40;
  float midW = 550;
  float midH = 135;

  drawTabCardMulti("Degree_Motor_Left", startX, startY, leftW, leftH, histLegL, colorsL, statL, -1.5, 1.5);
  drawTabCardMulti("Degree_Motor_Right", startX, startY + leftH + gapY, leftW, leftH, motorHistLegR, colorsR, statR, -1.5, 1.5);
  drawTabCardMultiIMU("IMU Sensor (Roll & Pitch)", startX, startY + (leftH + gapY) * 2, leftW, leftH, histIMU, colorsIMU, -1.0, 1.0);

  drawTabCard("Com -Y Axis (Roll)", midX, startY, midW, midH, histCoMY, cLineP, -0.6, 0.6);
  drawTabCard("Com -Z Axis (Pitch)", midX, startY + midH + gapY, midW, midH, histCoMZ, cLineG, -0.6, 0.6);
  drawTabCardMultiZ("Foot Trajectory Z", midX, startY + (midH + gapY) * 2, midW, midH, histFootZ, colorsFootZ, "FOOT Z (L/R)", 0.0, 5.0);

  float radioY = startY + (leftH + gapY) * 3 + 30;
  float spaceUI = 190;

  drawRadio("Standby", startX, radioY, currentMode.equals("Standby"));
  drawRadio("Stepping", startX + spaceUI, radioY, currentMode.equals("Stepping"));
  drawRadio("Turn Right", startX + spaceUI * 2, radioY, currentMode.equals("Turn Right"));
  drawRadio("Line Follower", startX + spaceUI * 3, radioY, currentMode.equals("Line Follower"));

  drawRadio("Forward", startX, radioY + 60, currentMode.equals("Forward"));
  drawRadio("Backward", startX + spaceUI, radioY + 60, currentMode.equals("Backward"));
  drawRadio("Turn Left", startX + spaceUI * 2, radioY + 60, currentMode.equals("Turn Left"));

  if (isLoggingActive) {
    fill(231, 76, 60);
    noStroke();
    ellipse(startX + 450, radioY - 30, 12, 12);
    fill(255);
    textSize(13);
    text("RECORDING DATA TO EXCEL...", startX + 470, radioY - 25);
  }

  float pillY1 = radioY + 145;
  float pillY2 = pillY1 + 85;
  float paramSpace = 155;

  drawParamPill("Period", valPeriod, startX, pillY1, 0);
  drawParamPill("X_Offset", valXOffset, startX + paramSpace, pillY1, 1);
  drawParamPill("Z_Offset", valZOffset, startX + paramSpace * 2, pillY1, 2);
  drawParamPill("Y_Offset", valYOffset, startX + paramSpace * 3, pillY1, 3);

  drawParamPill("FootHeight", valFootH, startX, pillY2, 4);
  drawParamPill("Swing_R_L", valSwingRL, startX + paramSpace, pillY2, 5);
  drawParamPill("Arm_Swing", valArmSwing, startX + paramSpace * 2, pillY2, 6);
  // ---> DSR menggantikan Pelvis_Off di posisi index 7 <---
  drawParamPill("DSR (%)", valDSR, startX + paramSpace * 3, pillY2, 7);

  // ==========================================
  // COM VISUALIZER & KOTAK STATUS
  // ==========================================
  float comXPos = midX + 30;
  float comYPos = pillY1 - 30;

  float curComY = histCoMY.size() > 0 ? histCoMY.get(histCoMY.size()-1) : 0;
  float curFzL = histFootZ[0].size() > 0 ? histFootZ[0].get(histFootZ[0].size()-1) : 0;
  float curFzR = histFootZ[1].size() > 0 ? histFootZ[1].get(histFootZ[1].size()-1) : 0;

  if (currentMode.equals("Standby")) {
    curComY = 0;
    curFzL = 0;
    curFzR = 0;
  }

  drawCOMVisualizer("COM Trajectory", comXPos, comYPos, 150, 170, curComY, curFzL, curFzR);

  float statusBoxX = midX + 240;
  float statusBoxY = pillY1 - 80;
  drawStatusBox(statusBoxX, statusBoxY, 320, 220);

  drawBrandingCorner();
}

void drawStatusBox(float x, float y, float w, float h) {
  fill(0, 20);
  noStroke();
  rect(x+5, y+5, w, h, 40);
  fill(cCard);
  noStroke();
  rect(x, y, w, h, 40);

  fill(cTextDark);
  textSize(20);
  textAlign(LEFT, TOP);
  float spacing = 45;

  text("Speed        : " + nf(currentSpeed, 1, 2) + " m/s", x + 40, y + 30);
  text("Distance   : " + nf(currentDistance, 1, 2) + " m", x + 40, y + 30 + spacing);
  text("Mode         : " + currentMode, x + 40, y + 30 + spacing*2);

  if (fallStatus.equals("Normal")) {
    fill(cLineG);
  } else {
    fill(cLineR);
  }
  text("Status       : " + fallStatus, x + 40, y + 30 + spacing*3);
}

void drawTabCard(String label, float x, float y, float w, float h, FloatList data, color cLine, float minVal, float maxVal) {
  fill(0, 20);
  noStroke();
  rect(x+5, y+5, w, h, 15);
  fill(cCard);
  noStroke();
  rect(x, y, w, h, 15);
  fill(cCard);
  rect(x + 20, y + h - 2, 170, 35, 0, 0, 10, 10);
  fill(cTextDark);
  textSize(12);
  textAlign(CENTER, CENTER);
  text(label, x + 105, y + h + 15);
  textAlign(LEFT, TOP);

  if (data.size() < 2) return;
  stroke(cLine);
  noFill();
  strokeWeight(2.0);
  beginShape();
  float stepX = (w - 30) / (float)maxGraphPoints;
  for (int i = 0; i < data.size(); i++) {
    float px = x + 15 + (i * stepX);
    float py = map(data.get(i), minVal, maxVal, y + h - 15, y + 15);
    vertex(px, constrain(py, y+15, y+h-15));
  }
  endShape();
  strokeWeight(1);
}

void drawTabCardMulti(String label, float x, float y, float w, float h, FloatList[] dataArray, color[] cLines, String status, float minVal, float maxVal) {
  fill(0, 20);
  noStroke();
  rect(x+5, y+5, w, h, 15);
  fill(cCard);
  noStroke();
  rect(x, y, w, h, 15);
  fill(cCard);
  rect(x + 20, y + h - 2, 170, 35, 0, 0, 10, 10);
  fill(cTextDark);
  textSize(12);
  textAlign(CENTER, CENTER);
  text(label, x + 105, y + h + 15);

  textAlign(LEFT, TOP);
  textSize(14);

  if (status.equals("FOOT Z (L/R)")) {
    fill(cLines[0]);
    text("Left", x + 15, y + 15);
    fill(cLines[1]);
    text("Right", x + 50, y + 15);
  } else if (!status.equals("")) {
    fill(cLineB);
    text(status, x + 15, y + 15);
  }

  float stepX = (w - 30) / (float)maxGraphPoints;
  for (int j=0; j<dataArray.length; j++) {
    if (dataArray[j].size() < 2) continue;
    stroke(cLines[j]);
    noFill();
    strokeWeight(2.0);
    beginShape();
    for (int i = 0; i < dataArray[j].size(); i++) {
      float px = x + 15 + (i * stepX);
      float py = map(dataArray[j].get(i), minVal, maxVal, y + h - 15, y + 15);
      vertex(px, constrain(py, y+15, y+h-15));
    }
    endShape();
  }
  strokeWeight(1);
}

void drawTabCardMultiIMU(String label, float x, float y, float w, float h, FloatList[] dataArray, color[] cLines, float minVal, float maxVal) {
  fill(0, 20);
  noStroke();
  rect(x+5, y+5, w, h, 15);
  fill(cCard);
  noStroke();
  rect(x, y, w, h, 15);
  fill(cCard);
  rect(x + 20, y + h - 2, 210, 35, 0, 0, 10, 10);
  fill(cTextDark);
  textSize(12);
  textAlign(CENTER, CENTER);
  text(label, x + 125, y + h + 15);

  textAlign(LEFT, TOP);
  textSize(14);
  fill(cLines[0]);
  text("Roll (Y)", x + 15, y + 10);
  fill(cLines[1]);
  text("Pitch (Z)", x + 85, y + 10);

  float stepX = (w - 30) / (float)maxGraphPoints;
  for (int j=0; j<dataArray.length; j++) {
    if (dataArray[j].size() < 2) continue;
    stroke(cLines[j]);
    noFill();
    strokeWeight(2.0);
    beginShape();
    for (int i = 0; i < dataArray[j].size(); i++) {
      float px = x + 15 + (i * stepX);
      float py = map(dataArray[j].get(i), minVal, maxVal, y + h - 15, y + 15);
      vertex(px, constrain(py, y+15, y+h-15));
    }
    endShape();
  }
  strokeWeight(1);
}

void drawTabCardMultiZ(String label, float x, float y, float w, float h, FloatList[] dataArray, color[] cLines, String status, float minVal, float maxVal) {
  fill(0, 20);
  noStroke();
  rect(x+5, y+5, w, h, 15);
  fill(cCard);
  noStroke();
  rect(x, y, w, h, 15);
  fill(cCard);
  rect(x + 20, y + h - 2, 170, 35, 0, 0, 10, 10);
  fill(cTextDark);
  textSize(12);
  textAlign(CENTER, CENTER);
  text(label, x + 105, y + h + 15);

  textAlign(LEFT, TOP);
  textSize(14);
  fill(cLines[0]);
  text("Left", x + 15, y + 10);
  fill(cLines[1]);
  text("Right", x + 50, y + 10);

  float stepX = (w - 30) / (float)maxGraphPoints;
  for (int j=0; j<dataArray.length; j++) {
    if (dataArray[j].size() < 2) continue;
    stroke(cLines[j]);
    noFill();
    strokeWeight(2.0);
    beginShape();
    for (int i = 0; i < dataArray[j].size(); i++) {
      float px = x + 15 + (i * stepX);
      float py = map(dataArray[j].get(i), minVal, maxVal, y + h - 15, y + 15);
      vertex(px, constrain(py, y+15, y+h-15));
    }
    endShape();
  }
  strokeWeight(1);
}

void drawRadio(String label, float x, float y, boolean active) {
  fill(cCard);
  noStroke();
  ellipse(x, y, 22, 22);
  if (active) {
    fill(cBg);
    noStroke();
    ellipse(x, y, 12, 12);
  }
  fill(255);
  textSize(15);
  textAlign(LEFT, CENTER);
  text(label, x + 18, y - 2);
  textAlign(LEFT, TOP);
}

void drawParamPill(String label, float val, float x, float y, int idx) {
  fill(cCard);
  noStroke();

  if (idx == activePillIndex) {
    strokeWeight(3);
    stroke(cLineR);
  } else {
    noStroke();
  }

  rect(x, y, 110, 50, 20);
  fill(cTextDark);
  textSize(16);
  textAlign(CENTER, CENTER);

  String displayValue = "";

  if (idx == activePillIndex) {
    cursorBlinkFrame++;
    String cursorStr = (cursorBlinkFrame % 40 < 20) ? "|" : "";
    displayValue = currentInputBuffer + cursorStr;
    fill(cLineR);
  } else {
    displayValue = nf(val, 1, 1);
    fill(cTextDark);
  }

  text(displayValue, x + 55, y + 23);
  fill(255);
  textSize(13);
  text(label, x + 55, y + 65);
  textAlign(LEFT, TOP);
  strokeWeight(1);
}

void drawBrandingCorner() {
  fill(255);
  noStroke();
  ellipse(width, height + 100, 1000, 500);
  float textRightMargin = 140;
  fill(cTextDark);
  textAlign(RIGHT, BOTTOM);
  textSize(22);
  text("VoBiRo Bipedal Robot", width - textRightMargin, height - 40);
  textSize(13);
  text("Sinusoidal Oscillator-Based Gait", width - textRightMargin, height - 20);

  if (logo != null) {
    imageMode(CENTER);
    image(logo, width - 60, height - 50);
    imageMode(CORNER);
  }
  textAlign(LEFT, TOP);
}

void mousePressed() {
  String modeSebelumKlik = currentMode;

  cp5.setMouseWheelRotation(0);

  if (mouseX > width - 300 && mouseY > height - 80) {
    testMotion = !testMotion;
  }

  float startX = 60;
  float leftH = 185;
  float gapY = 35;

  float radioY = 40 + (leftH + gapY) * 3 + 30;
  float spaceUI = 190;

  if (mouseX > startX-10 && mouseX < startX+130 && mouseY > radioY-15 && mouseY < radioY+15) {
    currentMode = "Standby";
    sendUDPCommand("CMD:INIT");
    currentSpeed=0;
  }
  if (mouseX > startX+spaceUI-10 && mouseX < startX+spaceUI+130 && mouseY > radioY-15 && mouseY < radioY+15) {
    currentMode = "Stepping";
    sendUDPCommand("CMD:STEP");
  }
  if (mouseX > startX+(spaceUI*2)-10 && mouseX < startX+(spaceUI*2)+130 && mouseY > radioY-15 && mouseY < radioY+15) {
    currentMode = "Turn Right";
    sendUDPCommand("CMD:TURN_RIGHT");
  }
  if (mouseX > startX+(spaceUI*3)-10 && mouseX < startX+(spaceUI*3)+130 && mouseY > radioY-15 && mouseY < radioY+15) {
    currentMode = "Line Follower";
    sendUDPCommand("CMD:LINE");
  }

  if (mouseX > startX-10 && mouseX < startX+130 && mouseY > radioY+60-15 && mouseY < radioY+60+15) {
    currentMode = "Forward";
    sendUDPCommand("CMD:MAJU");
  }
  if (mouseX > startX+spaceUI-10 && mouseX < startX+spaceUI+130 && mouseY > radioY+60-15 && mouseY < radioY+60+15) {
    currentMode = "Backward";
    sendUDPCommand("CMD:MUNDUR");
  }
  if (mouseX > startX+(spaceUI*2)-10 && mouseX < startX+(spaceUI*2)+130 && mouseY > radioY+60-15 && mouseY < radioY+60+15) {
    currentMode = "Turn Left";
    sendUDPCommand("CMD:TURN_LEFT");
  }

  if ((!modeSebelumKlik.equals("Line Follower") && currentMode.equals("Line Follower")) ||
    (!modeSebelumKlik.equals("Forward") && currentMode.equals("Forward"))) {
    mulaiRekamExcel();
  } else if (!currentMode.equals("Line Follower") && !currentMode.equals("Forward")) {
    selesaiDanSimpanExcel();
  }

  float pillY1 = radioY + 145;
  float pillY2 = pillY1 + 85;
  float paramSpace = 155;
  float pillW = 110;
  float pillH = 50;

  int oldActiveIndex = activePillIndex;
  activePillIndex = -1;
  currentInputBuffer = "";

  // Cek klik di Baris 1 (index 0-3)
  if (mouseY > pillY1 && mouseY < pillY1 + pillH) {
    if (mouseX > startX && mouseX < startX + pillW) {
      activePillIndex = 0;
    }
    if (mouseX > startX+paramSpace && mouseX < startX+paramSpace + pillW) {
      activePillIndex = 1;
    }
    if (mouseX > startX+paramSpace*2 && mouseX < startX+paramSpace*2 + pillW) {
      activePillIndex = 2;
    }
    if (mouseX > startX+paramSpace*3 && mouseX < startX+paramSpace*3 + pillW) {
      activePillIndex = 3;
    }
  }

  // Cek klik di Baris 2 (index 4-7)
  if (mouseY > pillY2 && mouseY < pillY2 + pillH) {
    if (mouseX > startX && mouseX < startX + pillW) {
      activePillIndex = 4;
    }
    if (mouseX > startX+paramSpace && mouseX < startX+paramSpace + pillW) {
      activePillIndex = 5;
    }
    if (mouseX > startX+paramSpace*2 && mouseX < startX+paramSpace*2 + pillW) {
      activePillIndex = 6;
    }
    if (mouseX > startX+paramSpace*3 && mouseX < startX+paramSpace*3 + pillW) {
      activePillIndex = 7;
    } // Index 7 sekarang DSR
  }

  if (oldActiveIndex != -1 && activePillIndex == -1) {
    println("Input Keyboard dinonaktifkan.");
  }
}

void keyPressed() {
  if (activePillIndex != -1) {
    if (key == ENTER || key == RETURN) {
      if (currentInputBuffer.length() > 0) {
        float newVal = float(currentInputBuffer);
        if (!Float.isNaN(newVal)) {
          updateParameterValue(activePillIndex, newVal);
        }
      }
      activePillIndex = -1;
      currentInputBuffer = "";
    } else if (key == BACKSPACE) {
      if (currentInputBuffer.length() > 0) {
        currentInputBuffer = currentInputBuffer.substring(0, currentInputBuffer.length()-1);
      }
    } else if (key == ESC) {
      activePillIndex = -1;
      currentInputBuffer = "";
      key = 0;
    }
  }
}

void keyTyped() {
  if (activePillIndex != -1) {
    if ((key >= '0' && key <= '9') || key == '.' || key == '-') {
      currentInputBuffer += key;
    }
  }
}

// ---> MODIFIKASI: Mengirim perintah UDP untuk Case 7 yang baru (DSR) <---
void updateParameterValue(int idx, float val) {
  switch(idx) {
  case 0:
    valPeriod = val;
    sendUDPCommand("SET_PERIOD:" + nf(valPeriod, 1, 1));
    break;
  case 1:
    valXOffset = val;
    sendUDPCommand("SET_X_OFF:" + nf(valXOffset, 1, 1));
    break;
  case 2:
    valZOffset = val;
    sendUDPCommand("SET_Z_OFF:" + nf(valZOffset, 1, 1));
    break;
  case 3:
    valYOffset = val;
    sendUDPCommand("SET_Y_OFF:" + nf(valYOffset, 1, 1));
    break;
  case 4:
    valFootH = val;
    sendUDPCommand("SET_FOOT_H:" + nf(valFootH, 1, 1));
    break;
  case 5:
    valSwingRL = val;
    sendUDPCommand("SET_SWING_RL:" + nf(valSwingRL, 1, 1));
    break;
  case 6:
    valArmSwing = val;
    sendUDPCommand("SET_ARM_SWING:" + nf(valArmSwing, 1, 1));
    break;
  case 7:
    valDSR = val;
    sendUDPCommand("SET_DSR:" + nf(valDSR, 1, 1));
    break; // DSR menggantikan Pelvis_Off
  }
  println("Parameter berhasil diubah via Keyboard (Kapsul " + idx + ") menjadi: " + val);
}

void initUDPReceiver() {
  try {
    udpSocket = new DatagramSocket(listenPort);
    receiveThread = new Thread(new Runnable() {
      public void run() {
        byte[] buffer = new byte[1024];
        while (true) {
          try {
            DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
            udpSocket.receive(packet);
            String message = new String(packet.getData(), 0, packet.getLength()).trim();
            if (message.startsWith("TEL")) {
              String[] tokens = split(message, ',');
              if (tokens.length >= 33) {
                statusKoneksi = "TERHUBUNG (AKTIF)";
                lastPacketTime = millis();

                footTrajZR  = float(tokens[31]);
                footTrajZL  = float(tokens[32]);

                float imuRoll  = float(tokens[29]);
                float imuPitch = float(tokens[30]);

                gyroY = imuRoll;
                gyroZ = imuPitch;

                hipPitchR   = float(tokens[15]);
                kneePitchR  = float(tokens[16]);
                anklePitchR = float(tokens[17]);
                hipPitchL   = float(tokens[18]);
                kneePitchL  = float(tokens[19]);
                anklePitchL = float(tokens[20]);
                sPitchR     = float(tokens[21]);
                ePitchR     = float(tokens[22]);
                sPitchL     = float(tokens[23]);
                ePitchL     = float(tokens[24]);

                hipYawR     = float(tokens[25]);
                hipRollR    = float(tokens[26]);
                hipYawL     = float(tokens[27]);
                hipRollL    = float(tokens[28]);
              }
            }
          }
          catch (Exception e) {
          }
        }
      }
    }
    );
    receiveThread.start();
  }
  catch (Exception e) {
  }
}

void sendUDPCommand(String command) {
  try {
    byte[] sendData = command.getBytes();
    InetAddress serverAddr = InetAddress.getByName(webotsIP);
    DatagramPacket sendPacket = new DatagramPacket(sendData, sendData.length, serverAddr, webotsPort);
    if (udpSocket != null) udpSocket.send(sendPacket);
  }
  catch (Exception e) {
  }
}

void mulaiRekamExcel() {
  excelLogTable = new Table();
  excelLogTable.addColumn("Timestamp_ms");
  excelLogTable.addColumn("Foot_Trajectory_Z_Left");
  excelLogTable.addColumn("Foot_Trajectory_Z_Right");
  excelLogTable.addColumn("CoM_Y_Roll");
  excelLogTable.addColumn("CoM_Z_Pitch");
  excelLogTable.addColumn("Speed_m_s");
  excelLogTable.addColumn("Distance_m");
  excelLogTable.addColumn("Fall_Status");
  isLoggingActive = true;
  println("--> Berhasil membuat file rekaman baru. Memulai pencatatan data locomotion...");
  currentDistance = 0;
}

void selesaiDanSimpanExcel() {
  if (isLoggingActive && excelLogTable != null) {
    String namaFile = "data/locomotion_" + year() + nf(month(), 2) + nf(day(), 2) + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".csv";
    saveTable(excelLogTable, namaFile);
    println("--> Perekaman selesai! Berkas excel sukses disimpan ke: " + namaFile);
    isLoggingActive = false;
  }
}

void set_offset_joint() {
}
public void PLUS() {
  numerator = 1;
}
public void MINUS() {
  numerator = 2;
}
void setup_calibration_joint() {
}

void drawCOMVisualizer(String label, float x, float y, float w, float h, float comY, float fzL, float fzR) {
  fill(0, 255, 0);
  textSize(16);
  textAlign(CENTER, TOP);
  text(label, x + w/2, y - 15);

  float cx = x + w/2;
  float floorY = y + h;

  stroke(0, 0, 255);
  strokeWeight(2);
  line(cx - 70, floorY, cx + 70, floorY);

  float liftR = constrain(map(fzR, 0.3, 1.5, 0, 35), 0, 15);
  float liftL = constrain(map(fzL, 0.3, 1.5, 0, 35), 0, 15);

  noStroke();
  float baseY = floorY-15;
  fill(0, 255, 255);
  rect(cx - 45, baseY - liftR, 40, 15);
  fill(255, 255, 0);
  rect(cx + 5, baseY - liftL, 40, 15);

  float clampedComY = constrain(comY, -0.6, 0.6);
  float mappedCOM_X = cx + map(clampedComY, -0.6, 0.6, -80, 80);

  float topCOM_Y = y + 20;

  stroke(0, 0, 255);
  strokeWeight(3);
  line(cx, floorY, mappedCOM_X, topCOM_Y);

  fill(139, 69, 19);
  stroke(0, 0, 255);
  strokeWeight(3);
  ellipse(mappedCOM_X, topCOM_Y, 24, 24);

  textAlign(LEFT, TOP);
}

class robot {
  float sc=9;
  PShape hip, legU, legL, ankle, lfoot, rfoot, body, pelv;
  PShape neck, head, shoulder, uarm, larm, conarm;
  float[] r1=new float[6];
  float[] r2=new float[6];
  float[] h1=new float[4];
  float[] h2=new float[4];
  float[] hd=new float[2];
  float rb;

  robot() {
    try {
      pelv = loadShape("pelv.obj");
      pelv.scale(sc);
      hip = loadShape("HIP_Servo.obj");
      hip.scale(sc);
      legU = loadShape("LEGupper.obj");
      legU.scale(sc);
      legL = loadShape("LEGlower.obj");
      legL.scale(sc);
      ankle = loadShape("HIP_Servo.obj");
      ankle.scale(sc);
      lfoot = loadShape("Foot.obj");
      lfoot.scale(sc);
      rfoot = loadShape("RightFoot.obj");
      rfoot.scale(sc);
      body =  loadShape("Body.obj");
      body.scale(sc);
      neck =  loadShape("Neck.obj");
      neck.scale(sc);
      head = loadShape("Head.obj");
      head.scale(sc);
      shoulder = loadShape("Shoulder.obj");
      shoulder.scale(sc);
      uarm = loadShape("UpperArm.obj");
      uarm.scale(sc);
      conarm = loadShape("ArmConnector.obj");
      conarm.scale(sc);
      larm = loadShape("ARMlower.obj");
      larm.scale(sc);
    }
    catch(Exception e) {
    }
  }
  void rotBody(float rbody) {
    rb = radians(rbody);
  }
  void rotHead(float pan, float tilt) {
    hd[0] = radians(pan);
    hd[1] = radians(tilt);
  }
  void rotHand_Right(float pitch_up, float roll_up, float yaw_up, float pitch_low  ) {
    h1[0] = radians(pitch_up);
    h1[1] = radians(roll_up);
    h1[2] = radians(yaw_up);
    h1[3] = radians(pitch_low);
  }
  void rotHand_Left(float pitch_up, float roll_up, float yaw_up, float pitch_low  ) {
    h2[0] = radians(pitch_up);
    h2[1] = radians(roll_up);
    h2[2] = radians(yaw_up);
    h2[3] = radians(pitch_low);
  }
  void rotFoot_Right(float hip_yaw, float hip_pitch, float hip_roll, float knee, float ankle_pitch, float ankle_roll) {
    r1[0] = radians(hip_yaw);
    r1[1] = radians(hip_pitch);
    r1[2] = radians(hip_roll);
    r1[3] = radians(knee);
    r1[4] = radians(ankle_pitch);
    r1[5] = radians(ankle_roll);
  }
  void rotFoot_Left(float hip_yaw, float hip_pitch, float hip_roll, float knee, float ankle_pitch, float ankle_roll) {
    r2[0] = radians(hip_yaw);
    r2[1] = radians(hip_pitch);
    r2[2] = radians(hip_roll);
    r2[3] = radians(knee);
    r2[4] = radians(ankle_pitch);
    r2[5] = radians(ankle_roll);
  }
  void update() {
    pushMatrix();
    rotateZ(PI/2);
    rotateX(PI);
    waist();
    popMatrix();
  }
  void waist() {
    pushMatrix();
    rotateZ(PI/2);
    rotateY(PI);
    translate(0, sc*5, 0);
    body();
    leg_Right();
    leg_Left();
    popMatrix();
  }
  void head() {
    pushMatrix();
    rotateX(PI/2);
    rotateY(PI);
    translate(0, 0, sc*9);
    rotateZ(-hd[0]);
    if (neck != null) shape(neck);
    rotateX(-PI/2);
    rotateZ(PI);
    rotateZ(-hd[1]);
    if (head != null) shape(head);
    fill(0, 0, 200);
    translate(sc*1.3, sc*3.4, 0);
    box(0.5, sc*2, sc*6);
    popMatrix();
  }
  void body() {
    pushMatrix();
    rotateY(-PI/2);
    rotateZ(-rb);
    if (body != null) shape(body);
    head();
    hand_Right();
    hand_Left();
    popMatrix();
  }
  void hand_Right() {
    pushMatrix();
    translate(0, sc*4.4, -sc*7.9);
    rotateZ(h1[0]);
    if (shoulder != null) shape(shoulder);
    rotateY(PI/2);
    translate(sc*1, -sc*1.5, 0);
    rotateZ(h1[1]);
    if (uarm != null) shape(uarm);
    rotateX(PI/2);
    translate(0, sc*1, sc*9.5);
    rotateZ(h1[2]);
    if (conarm != null) shape(conarm);
    rotateY(PI/2);
    rotateZ(PI);
    translate(sc*1.2, -sc*1, 0);
    rotateZ(h1[3]);
    if (larm != null) shape(larm);
    popMatrix();
  }
  void hand_Left() {
    pushMatrix();
    rotateY(PI);
    translate(0, sc*4.4, -sc*7.9);
    rotateZ(h2[0]);
    if (shoulder != null) shape(shoulder);
    rotateY(PI/2);
    rotateX(PI);
    rotateZ(PI);
    translate(-sc*1, -sc*1.5, 0);
    rotateZ(-h2[1]);
    if (uarm != null) shape(uarm);
    rotateX(PI/2);
    translate(0, sc*1, sc*9.5);
    rotateZ(h2[2]);
    if (conarm != null) shape(conarm);
    rotateY(PI/2);
    rotateX(PI);
    rotateZ(PI);
    translate(sc*1.2, sc*1, 0);
    rotateZ(h2[3]);
    if (larm != null) shape(larm);
    popMatrix();
  }
  void leg_Right() {
    pushMatrix();
    translate(sc*3.9, -sc*9, 0);
    rotateZ(-PI/2);
    rotateX(-PI/2);
    rotateX(-r1[0]);
    if (pelv != null) shape(pelv);
    rotateY(-r1[2]);
    if (hip != null) shape(hip);
    rotateZ(r1[1]);
    if (legU != null) shape(legU);
    rotateZ(PI/2);
    rotateY(PI);
    translate(0, -sc*9.5, 0);
    rotateZ(-r1[3]);
    if (legL != null) shape(legL);
    rotateZ(PI/2);
    translate(-sc*9.5, 0, 0);
    rotateZ(r1[4]);
    if (ankle != null) shape(ankle);
    rotateZ(PI);
    rotateX(PI/2);
    rotateX(PI);
    rotateZ(r1[5]);
    if (lfoot != null) shape(lfoot);
    popMatrix();
  }
  void leg_Left() {
    pushMatrix();
    translate(-sc*3.7, -sc*9, 0);
    rotateZ(-PI/2);
    rotateX(-PI/2);
    rotateX(-r2[0]);
    if (pelv != null) shape(pelv);
    rotateY(-r2[2]);
    if (hip != null) shape(hip);
    rotateZ(-r2[1]);
    if (legU != null) shape(legU);
    rotateZ(PI/2);
    rotateY(PI);
    translate(0, -sc*9.5, 0);
    rotateZ(r2[3]);
    if (legL != null) shape(legL);
    rotateZ(PI/2);
    translate(-sc*9.5, 0, 0);
    rotateZ(-r2[4]);
    if (ankle != null) shape(ankle);
    rotateZ(PI);
    rotateX(PI/2);
    rotateY(PI);
    rotateZ(r2[5]);
    if (rfoot != null) shape(rfoot);
    popMatrix();
  }
}
