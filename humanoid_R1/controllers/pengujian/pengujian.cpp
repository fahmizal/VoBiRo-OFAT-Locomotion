#include "control.hpp"

#include <GaitManager.hpp>
#include <MotionPlayManager.hpp>
#include <VisionManager.hpp>
#include <webots/Accelerometer.hpp>
#include <webots/Gyro.hpp>
#include <webots/Keyboard.hpp>
#include <webots/Motor.hpp>
#include <webots/PositionSensor.hpp>
#include <webots/Camera.hpp> 
#include <webots/GPS.hpp> 
#include "Walking.h"
#include "ColorFinder.h" 

#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <ctime> 

// --- HEADER UNTUK KOMUNIKASI UDP ---
#include <string.h>
#ifdef _WIN32
  #include <winsock2.h>
  #pragma comment(lib,"ws2_32.lib")
  typedef int socklen_t;
#else
  #include <sys/socket.h>
  #include <arpa/inet.h>
  #include <fcntl.h>
  #include <unistd.h>
#endif
// -----------------------------------

using namespace webots;
using namespace managers;
using namespace std;

// Menghidupkan kembali variabel file CSV Webots
static ofstream gyroLogFile;
static ofstream trajectoryLogFile;
static ofstream lineFollowLogFile; 

static const char *motorNames[NMOTORS] = {
  "ShoulderR", "ShoulderL", "ArmUpperR", "ArmUpperL", "ArmLowerR",
  "ArmLowerL", "PelvYR",    "PelvYL",    "PelvR",     "PelvL",
  "LegUpperR", "LegUpperL", "LegLowerR", "LegLowerL", "AnkleR",
  "AnkleL",    "FootR",     "FootL",     "Neck",      "Head" 
};

Walk::Walk() : Robot() {
  mTimeStep = getBasicTimeStep();
  
  mAccelerometer = getAccelerometer("Accelerometer");
  mAccelerometer->enable(mTimeStep);

  mCamera = getCamera("Camera");
  if (mCamera) {
    mCamera->enable(2 * mTimeStep);
  } else {
    std::cout << "Error: Perangkat kamera tidak ditemukan!" << std::endl;
  }
  int width = mCamera->getWidth();
  int height = mCamera->getHeight();

  mGyro = getGyro("Gyro");
  mGyro->enable(mTimeStep);

  for (int i = 0; i < NMOTORS; i++) {
    mMotors[i] = getMotor(motorNames[i]);
    string sensorName = motorNames[i];
    sensorName.push_back('S');
    mPositionSensors[i] = getPositionSensor(sensorName);
    mPositionSensors[i]->enable(mTimeStep);
  }

  mKeyboard = getKeyboard();
  mKeyboard->enable(mTimeStep);

  mVisionManager = new VisionManager(
    width, height, 0, 180, 0, 30, 0.1, 30.0
  );

  mMotionManager = new MotionPlayManager(this);
  mGaitManager = new GaitManager(this, "config.ini");

  mStartTime = 0.0;
  mStopwatchRunning = false;
}

Walk::~Walk() {
  delete mVisionManager;
  delete mMotionManager;
  delete mGaitManager;
  if (trajectoryLogFile.is_open()) trajectoryLogFile.close();
  if (gyroLogFile.is_open()) gyroLogFile.close();
  if (lineFollowLogFile.is_open()) lineFollowLogFile.close();
}

void Walk::myStep() {
  int ret = step(mTimeStep);
  if (ret == -1) exit(EXIT_SUCCESS);
}

void Walk::wait(int ms) {
  double startTime = getTime();
  double s = (double)ms / 1000.0;
  while (s + startTime >= getTime()) myStep();
}

void Walk::run() {
  cout << "-------Program Pengujian Robot VoBiRo (UDP & Locomotion & CSV Logger)-------" << endl;
  ::Robot::Walking* walking = mGaitManager->getWalkingInstance();

  GPS *gpsNode = getGPS("gps");
  if (gpsNode) {
    gpsNode->enable(mTimeStep);
    cout << "--> Sensor GPS 'gps' berhasil diaktifkan." << endl;
  } else {
    cout << "--> ERROR: Sensor GPS bernama 'gps' TIDAK ditemukan di Webots!" << endl;
  }

  #ifdef _WIN32
    WSADATA wsaData; WSAStartup(MAKEWORD(2, 2), &wsaData);
  #endif
  int udpSocket = socket(AF_INET, SOCK_DGRAM, 0);
  #ifdef _WIN32
    u_long mode = 1; ioctlsocket(udpSocket, FIONBIO, &mode);
  #else
    fcntl(udpSocket, F_SETFL, O_NONBLOCK);
  #endif

  struct sockaddr_in webotsAddr, procAddr;
  memset(&webotsAddr, 0, sizeof(webotsAddr));
  webotsAddr.sin_family = AF_INET;
  webotsAddr.sin_addr.s_addr = INADDR_ANY;
  webotsAddr.sin_port = htons(12001); 
  bind(udpSocket, (struct sockaddr*)&webotsAddr, sizeof(webotsAddr));

  memset(&procAddr, 0, sizeof(procAddr));
  procAddr.sin_family = AF_INET;
  procAddr.sin_addr.s_addr = inet_addr("127.0.0.1");
  procAddr.sin_port = htons(12345); 

  // Menyiapkan log IMU & Trajectory asli Webots
  gyroLogFile.open("gyro_log.csv");
  if (gyroLogFile.is_open()) gyroLogFile << "Time,GyroX,GyroY,GyroZ" << endl;
  trajectoryLogFile.open("trajectory_log.csv");
  if (trajectoryLogFile.is_open()) trajectoryLogFile << "Time,Actual_AnkleR_Pitch,Actual_AnkleL_Pitch" << endl;

  myStep();
  mMotionManager->playPage(9); 
  wait(200);

  bool loopplay = false;
  bool isLineFollowerMode = false; 
  bool prevLineFollowerMode = false; 
  double cmdX = 0.0, cmdA = 0.0, cmdY = 0.0; 
  
  int mLineLostCounter = 0;
  const int SEARCH_DURATION = 100;

  double filtered_pos[NMOTORS] = {0.0};
  double filtered_imu_roll = 0.0, filtered_imu_pitch = 0.0, filtered_gyro_y = 0.0;
  bool is_first_read = true;
  
  double ALPHA_MOTOR = 0.15; 
  double ALPHA_IMU   = 0.15; 

  const double l_thigh = 9.5; 
  const double l_calf  = 9.5; 
  const double l_ankle = 2.5; 
  const double max_leg_len = l_thigh + l_calf + l_ankle; 

  double startX = 0.0, startY = 0.0, startZ = 0.0;

  while (true) {
    checkIfFallen();

    const double *acc = mAccelerometer->getValues();
    double accX = acc[0] - 512.0; 
    double accY = acc[1] - 512.0; 
    double accZ = acc[2] - 512.0; 
    double raw_imu_roll  = atan2(accX, accZ); 
    double raw_imu_pitch = atan2(accY, accZ); 
    
    const double *gyroValues = mGyro->getValues();
    if (gyroLogFile.is_open()) gyroLogFile << getTime() << "," << gyroValues[0] << "," << gyroValues[1] << "," << gyroValues[2] << endl;
    double raw_gyro_y = gyroValues[1];

    if (is_first_read) {
        for (int i = 0; i < NMOTORS; i++) {
            filtered_pos[i] = mPositionSensors[i]->getValue();
        }
        filtered_imu_roll = raw_imu_roll;
        filtered_imu_pitch = raw_imu_pitch;
        filtered_gyro_y = raw_gyro_y;
        is_first_read = false; 
    } else {
        for (int i = 0; i < NMOTORS; i++) {
            double raw_val = mPositionSensors[i]->getValue();
            filtered_pos[i] = (ALPHA_MOTOR * raw_val) + ((1.0 - ALPHA_MOTOR) * filtered_pos[i]);
        }
        filtered_imu_roll  = (ALPHA_IMU * raw_imu_roll)  + ((1.0 - ALPHA_IMU) * filtered_imu_roll);
        filtered_imu_pitch = (ALPHA_IMU * raw_imu_pitch) + ((1.0 - ALPHA_IMU) * filtered_imu_pitch);
        filtered_gyro_y    = (ALPHA_IMU * raw_gyro_y)    + ((1.0 - ALPHA_IMU) * filtered_gyro_y);
    }

    double hip_yaw_r    = filtered_pos[6];  
    double hip_roll_r   = filtered_pos[8];  
    double hip_pitch_r  = filtered_pos[10]; 
    double knee_pitch_r = filtered_pos[12]; 
    double ankle_pitch_r= filtered_pos[14]; 
    
    double hip_yaw_l    = filtered_pos[7];  
    double hip_roll_l   = filtered_pos[9];  
    double hip_pitch_l  = filtered_pos[11]; 
    double knee_pitch_l = filtered_pos[13]; 
    double ankle_pitch_l= filtered_pos[15]; 
    
    double shoulder_pitch_r = filtered_pos[0];
    double shoulder_pitch_l = filtered_pos[1];
    double elbow_pitch_r    = filtered_pos[4]; 
    double elbow_pitch_l    = filtered_pos[5]; 

    double depth_r = l_thigh * cos(hip_pitch_r) + l_calf * cos(hip_pitch_r + knee_pitch_r) + l_ankle * cos(hip_pitch_r + knee_pitch_r + ankle_pitch_r);
    double depth_l = l_thigh * cos(hip_pitch_l) + l_calf * cos(hip_pitch_l + knee_pitch_l) + l_ankle * cos(hip_pitch_l + knee_pitch_l + ankle_pitch_l);
    
    double actual_foot_z_r = max_leg_len - depth_r;
    double actual_foot_z_l = max_leg_len - depth_l;

    double stance_threshold = 0.35; 
    if(actual_foot_z_r < stance_threshold) actual_foot_z_r = 0.0;
    if(actual_foot_z_l < stance_threshold) actual_foot_z_l = 0.0;

    if (trajectoryLogFile.is_open() && mGaitManager->isWalking()) {        
        trajectoryLogFile << getTime() << "," << ankle_pitch_r << "," << ankle_pitch_l << endl;
    }

    char sendBuf[512]; 
    snprintf(sendBuf, sizeof(sendBuf), 
        "TEL,0,0,0,0,0,0,0,0,0,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f",
        hip_pitch_r, knee_pitch_r, hip_pitch_l, knee_pitch_l, 
        filtered_gyro_y, hip_pitch_r, knee_pitch_r, ankle_pitch_r, hip_pitch_l, knee_pitch_l, ankle_pitch_l, 
        shoulder_pitch_r, elbow_pitch_r, shoulder_pitch_l, elbow_pitch_l,
        hip_yaw_r, hip_roll_r, hip_yaw_l, hip_roll_l,
        filtered_imu_roll, filtered_imu_pitch,
        actual_foot_z_r, actual_foot_z_l); 
    
    sendto(udpSocket, sendBuf, strlen(sendBuf), 0, (struct sockaddr*)&procAddr, sizeof(procAddr));

    char recvBuf[128];
    struct sockaddr_in fAddr; socklen_t fLen = sizeof(fAddr);
    int n = recvfrom(udpSocket, recvBuf, sizeof(recvBuf)-1, 0, (struct sockaddr*)&fAddr, &fLen);
    
    if (n > 0) {
      recvBuf[n] = '\0'; string msg(recvBuf);
      
      if (msg.find("CMD:") != string::npos) {
          string cmd = msg.substr(4);
          if (cmd == "INIT") { 
              loopplay = false; isLineFollowerMode = false; cmdX = 0.0; cmdA = 0.0; cmdY = 0.0; 
              mGaitManager->stop(); mMotionManager->playPage(9); mMotors[19]->setPosition(0.0); 
          }
          else if (cmd == "STEP") { loopplay = true; isLineFollowerMode = false; cmdX = 0.0; cmdA = 0.0; cmdY = 0.0; mGaitManager->start(); mMotors[19]->setPosition(0.0); }
          else if (cmd == "MAJU") { loopplay = true; isLineFollowerMode = false; cmdX = 1.0; cmdA = 0.0; cmdY = 0.0; mGaitManager->start(); mMotors[19]->setPosition(0.0); }
          else if (cmd == "MUNDUR") { loopplay = true; isLineFollowerMode = false; cmdX = -1.0; cmdA = 0.0; cmdY = 0.0; mGaitManager->start(); mMotors[19]->setPosition(0.0); }
          else if (cmd == "TURN_LEFT") { loopplay = true; isLineFollowerMode = false; cmdX = 0.0; cmdA = 0.5; cmdY = 0.0; mGaitManager->start(); mMotors[19]->setPosition(0.0); }
          else if (cmd == "TURN_RIGHT") { loopplay = true; isLineFollowerMode = false; cmdX = 0.0; cmdA = -0.5; cmdY = 0.0; mGaitManager->start(); mMotors[19]->setPosition(0.0); }
          else if (cmd == "LINE") { loopplay = true; isLineFollowerMode = true; mGaitManager->start(); }
          else if (cmd == "STOP") { loopplay = false; isLineFollowerMode = false; cmdX = 0.0; cmdA = 0.0; cmdY = 0.0; mGaitManager->stop(); mMotors[19]->setPosition(0.0); }
      }
      
      else if (msg.find("SET_") != string::npos) {
          size_t sep1 = msg.find(':');
          if (sep1 != string::npos) {
              string key = msg.substr(0, sep1);
              float val = stof(msg.substr(sep1 + 1));
              
              if (key == "SET_PERIOD") { walking->PERIOD_TIME = val; }
              else if (key == "SET_X_OFF") { walking->X_OFFSET = val; }
              else if (key == "SET_Z_OFF") { walking->Z_OFFSET = val; }
              else if (key == "SET_Y_OFF") { walking->Y_OFFSET = val; }
              else if (key == "SET_FOOT_H") { walking->Z_MOVE_AMPLITUDE = val; }
              else if (key == "SET_SWING_RL") { walking->Y_SWAP_AMPLITUDE = val; } 
              else if (key == "SET_ARM_SWING") { walking->ARM_SWING_GAIN = val; }
              else if (key == "SET_DSR") { walking->DSP_RATIO = val / 100.0; } // <-- Pastikan DSP_RATIO public
          }
      }
    }

    if (isLineFollowerMode) {
      mMotors[19]->setPosition(-0.6); 
      const unsigned char *image = mCamera->getImage();
      if (!image) {
        std::cout << "Gagal mengambil gambar" << std::endl;
      } else {
        int width = mCamera->getWidth();
        int height = mCamera->getHeight();

        double line_position = mVisionManager->getLinePosition(image, width, height);
        bool line_detected = (line_position != -9999);

        if (!line_detected) {
          mLineLostCounter++;
          cmdX = 0.0; 

          if (mLineLostCounter <= SEARCH_DURATION) { cmdA = 0.2; } 
          else if (mLineLostCounter <= SEARCH_DURATION * 3) { cmdA = -0.2; } 
          else { mLineLostCounter = 0; }

        } else {
          mLineLostCounter = 0;
          double error = line_position;
          double Kp = 0.0015; 
          double belokan = -error * Kp;
          
          if (belokan > 0.25) belokan = 0.25;
          if (belokan < -0.25) belokan = -0.25;
          
          cmdA = belokan; 

          if (std::abs(error) < (width / 4.0)) { cmdX = 0.5; } 
          else { cmdX = 0.2; }
        }
      }
    }

    mGaitManager->setXAmplitude(cmdX);
    mGaitManager->setAAmplitude(cmdA);
    mGaitManager->setYAmplitude(cmdY);

    int key = 0;
    while ((key = mKeyboard->getKey()) >= 0) {
      switch (key) {
        case ' ':
          if (loopplay) { 
              mGaitManager->stop(); cmdX = cmdA = cmdY = 0.0; 
              loopplay = false; isLineFollowerMode = false;
              mMotors[19]->setPosition(0.0); wait(200); 
          } else { 
              mGaitManager->start(); loopplay = true; wait(200); 
          }
          break;
        case Keyboard::UP: cmdX = 1.0; isLineFollowerMode = false; break;
        case Keyboard::DOWN: cmdX = -1.0; isLineFollowerMode = false; break;
        case Keyboard::RIGHT: cmdA = -0.5; isLineFollowerMode = false; break;
        case Keyboard::LEFT: cmdA = 0.5; isLineFollowerMode = false; break;
        case 'Q': cmdY = 0.5; isLineFollowerMode = false; break;
        case 'E': cmdY = -0.5; isLineFollowerMode = false; break;
      }
    }
    
    if (loopplay && !mGaitManager->isWalking()) {
      mGaitManager->start();
    }
    if (loopplay) {
      mGaitManager->step(mTimeStep);
    }

    // ====================================================================
    // LOGIKA PEREKAMAN CSV WEBOTS
    // ====================================================================
    if (!prevLineFollowerMode && isLineFollowerMode) {
      time_t rawtime;
      struct tm * timeinfo;
      char buffer[80];
      time(&rawtime);
      timeinfo = localtime(&rawtime);
      strftime(buffer, sizeof(buffer), "webots_locomotion_%Y%m%d_%H%M%S.csv", timeinfo);

      lineFollowLogFile.open(buffer);
      if (lineFollowLogFile.is_open()) {
        lineFollowLogFile << "Timestamp_ms,Foot_Trajectory_Z_Left,Foot_Trajectory_Z_Right,CoM_Y_Roll,CoM_Z_Pitch,Speed_m_s,Distance_m,Fall_Status,Hip_Pitch_R,Knee_Pitch_R,Ankle_Pitch_R,Hip_Pitch_L,Knee_Pitch_L,Ankle_Pitch_L\n";
        cout << "--> MEMULAI REKAM DATA CSV WEBOTS KE: " << buffer << endl;
        
        if (gpsNode) {
          const double *gpsVal = gpsNode->getValues();
          startX = gpsVal[0];
          startY = gpsVal[1];
          startZ = gpsVal[2];
        }
      }
    } else if (prevLineFollowerMode && !isLineFollowerMode) {
      if (lineFollowLogFile.is_open()) {
        lineFollowLogFile.close();
        cout << "--> PEREKAMAN CSV WEBOTS SELESAI." << endl;
      }
    }

    if (isLineFollowerMode && lineFollowLogFile.is_open()) {
      double distance_m = 0.0;
      double speed_m_s = 0.0;

      if (gpsNode) {
        const double *gpsVal = gpsNode->getValues();
        double dx = gpsVal[0] - startX;
        double dy = gpsVal[1] - startY;
        double dz = gpsVal[2] - startZ;
        distance_m = sqrt(dx*dx + dy*dy + dz*dz);
        speed_m_s = gpsNode->getSpeed(); 
      }

      string fall_status = "Normal";
      if (acc[1] < 512.0 - 60.0 || acc[1] > 512.0 + 60.0 || acc[0] < 400.0 || acc[0] > 600.0) {
        fall_status = "FALL DETECTED!";
      }

      long long timestamp_ms = static_cast<long long>(getTime() * 1000.0);

      lineFollowLogFile << timestamp_ms << ","
                        << actual_foot_z_l << ","
                        << actual_foot_z_r << ","
                        << filtered_imu_roll << ","
                        << filtered_imu_pitch << ","
                        << speed_m_s << ","
                        << distance_m << ","
                        << fall_status << ","
                        << hip_pitch_r << ","
                        << knee_pitch_r << ","
                        << ankle_pitch_r << ","
                        << hip_pitch_l << ","
                        << knee_pitch_l << ","
                        << ankle_pitch_l << "\n";
    }

    prevLineFollowerMode = isLineFollowerMode; 
    
    myStep();
  }
}

void Walk::checkIfFallen() {
  static int fup = 0;
  static int fdown = 0;
  static int fleft = 0;
  static int fright = 0;
  static const double acc_tolerance = 60.0; 
  static const double acc_step = 150;

  const double *acc = mAccelerometer->getValues();

  if (acc[1] < 512.0 - acc_tolerance) fup++; else fup = 0;
  if (acc[1] > 512.0 + acc_tolerance) fdown++; else fdown = 0;
  if (acc[0] < 400.0 + acc_tolerance) fleft++; else fleft = 0;
  if (acc[0] > 600.0 - acc_tolerance) fright++; else fright = 0;

  if (fup > acc_step) {
    cout << "-------Jatuh Kedepan-------" << endl;
    mMotionManager->playPage(10);  
    mMotionManager->playPage(9);   
    fup = 0; fdown = 0; fleft = 0; fright = 0; 
  }
  else if (fdown > acc_step) {
    cout << "-------Jatuh Kebelakang-------" << endl;
    mMotionManager->playPage(11);  
    mMotionManager->playPage(9);   
    fdown = 0; fup = 0; fleft = 0; fright = 0; 
  }
  else if (fleft > acc_step) {
    cout << "-------Jatuh Kesamping Kanan, mendorong...-------" << endl;
    mGaitManager->stop();
    mMotors[2]->setPosition(-1.0); 
    mMotors[0]->setPosition(-1.5); 
    mMotors[4]->setPosition(0.5);  
    wait(500);
    mMotors[0]->setPosition(1.5); 
    wait(500);
    mMotionManager->playPage(9); 
    wait(200);
    fup = 0; fdown = 0; fleft = 0; fright = 0;
  }
  else if (fright > acc_step) {
    cout << "-------Jatuh Kesamping Kiri, mendorong...-------" << endl;
    mGaitManager->stop();
    mMotors[3]->setPosition(1.0); 
    mMotors[1]->setPosition(-1.5); 
    mMotors[5]->setPosition(-0.5); 
    wait(500);
    mMotors[3]->setPosition(-1.0); 
    wait(500);
    mMotionManager->playPage(9); 
    wait(200);
    fup = 0; fdown = 0; fleft = 0; fright = 0;
  }
}