 #include "control.hpp"

//Manager Kontrol
#include <GaitManager.hpp>
#include <MotionPlayManager.hpp>
#include <VisionManager.hpp>

//Include Sensor
#include <webots/Accelerometer.hpp>
#include <webots/Camera.hpp>
#include <webots/Gyro.hpp>
#include <webots/Joystick.hpp>
#include <webots/Keyboard.hpp>
#include <webots/Motor.hpp>
#include <webots/PositionSensor.hpp>
#include <webots/InertialUnit.hpp>

//Kontrol Gerakan
#include "Walking.h"
#include "Kinematics.h"
#include "Matrix.h"
#include "Point.h"

//Include Matematis
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>

using namespace webots;
using namespace managers;
using namespace Robot;
using namespace std;

static ofstream comLogFile;
static ofstream gyroLogFile;


// A helper class for mathematical conversions
class AngleConverter {
public:
  static double toDegrees(double radians) {
    return radians * (180.0 / M_PI);
  }
};

static const char *motorNames[NMOTORS] = {
  "ShoulderR", "ShoulderL", "ArmUpperR", "ArmUpperL", "ArmLowerR", "ArmLowerL", "PelvYR", "PelvYL", "PelvR", "PelvL",
  "LegUpperR", "LegUpperL", "LegLowerR", "LegLowerL", "AnkleR", "AnkleL", "FootR", "FootL", "Neck", "Head"};

Walk::Walk() : Robot() {
  mTimeStep = getBasicTimeStep();
  mLineLostCounter = 0;
  mControlMode = LINE_FOLLOWER; // Mode awal adalah line follower
  mAngleMode = RADIANS;
  
  //Sensor Yang Dibutuhkan
  mInertialUnit = getInertialUnit("InertialUnit");
  mInertialUnit->enable(mTimeStep);
  
  mAccelerometer = getAccelerometer("Accelerometer");
  mAccelerometer->enable(mTimeStep);

  mCamera = getCamera("Camera");
  mCamera->enable(mTimeStep);
  int width = mCamera->getWidth();
  int height = mCamera->getHeight();

  mGyro = getGyro("Gyro");
  mGyro->enable(mTimeStep);

  mKeyboard = getKeyboard();
  mKeyboard->enable(mTimeStep);

  // Inisialisasi Joystick
  mJoystick = getJoystick();
  mJoystick->enable(mTimeStep);

  for (int i = 0; i < NMOTORS; i++) {
    mMotors[i] = getMotor(motorNames[i]);
    string sensorName = motorNames[i];
    sensorName.push_back('S');
    mPositionSensors[i] = getPositionSensor(sensorName);
    mPositionSensors[i]->enable(mTimeStep);
  }

  mVisionManager = new VisionManager(width, height, 0, 180, 0, 30, 0.1, 30.0);
  mMotionManager = new MotionPlayManager(this);
  mGaitManager = new GaitManager(this, "config.ini");
}

Walk::~Walk() {
  delete mVisionManager;
  delete mMotionManager;
  delete mGaitManager;
}

void Walk::myStep() {
  if (step(mTimeStep) == -1)
    exit(EXIT_SUCCESS);
}

void Walk::wait(int ms) {
  double startTime = getTime();
  double s = (double)ms / 1000.0;
  while (s + startTime >= getTime())
    myStep();
}

// Fungsi baru untuk menangani logika line follower
void Walk::handleLineFollowing() {
  const unsigned char *image = mCamera->getImage();
  if (!image) return;

  int width = mCamera->getWidth();
  int height = mCamera->getHeight();

  double line_position = mVisionManager->getLinePosition(image, width, height);
  bool line_detected = (line_position != -9999);

  if (!line_detected) {
    mLineLostCounter++;
    cout << "Status: Garis Hilang! Mencari... (" << mLineLostCounter << ")" << endl;
    mGaitManager->setXAmplitude(0.0);
    if (mLineLostCounter <= 100) mGaitManager->setAAmplitude(0.5);
    else if (mLineLostCounter <= 300) mGaitManager->setAAmplitude(-0.5);
    else mLineLostCounter = 0;
  } else {
    mLineLostCounter = 0;
    double error = line_position;
    double turn_threshold = width / 6.0;

    if (std::abs(error) < turn_threshold) {
      cout << "Status: Jalan Lurus (Posisi: " << error << ")" << endl;
      mGaitManager->setXAmplitude(1.0);
      mGaitManager->setAAmplitude(-error * 0.005);
    } else if (error < 0) {
      cout << "Status: Belok Kiri (Posisi: " << error << ")" << endl;
      mGaitManager->setXAmplitude(0.8);
      mGaitManager->setAAmplitude(0.4);
    } else {
      cout << "Status: Belok Kanan (Posisi: " << error << ")" << endl;
      mGaitManager->setXAmplitude(0.8);
      mGaitManager->setAAmplitude(-0.4);
    }
  }
}

double map_joystick_axis(int value) {
  // Nilai maksimum absolut dari joystick. Anda bisa sesuaikan jika perlu.
  const double MAX_JOYSTICK_VALUE = 32768.0;
  
  // Lakukan pembagian untuk normalisasi
  double normalized_value = static_cast<double>(value) / MAX_JOYSTICK_VALUE;

  // Pastikan nilai tidak melebihi rentang -1.0 hingga 1.0
  if (normalized_value > 1.0) return 1.0;
  if (normalized_value < -1.0) return -1.0;
  
  return normalized_value;
}

double map_joystick_axis2(int value) {
  // Nilai maksimum absolut dari joystick. Anda bisa sesuaikan jika perlu.
  const double MAX_JOYSTICK_VALUE = 32768.0;
  
  // Lakukan pembagian untuk normalisasi
  double normalized_value = static_cast<double>(value) / MAX_JOYSTICK_VALUE;

  // Pastikan nilai tidak melebihi rentang -0.5 hingga 0.5
  if (normalized_value > 0.5) return 0.5;
  if (normalized_value < -0.5) return -0.5;
  
  return normalized_value;
}

double map_joystick_axis3(int value) {
  // Nilai maksimum absolut dari joystick. Anda bisa sesuaikan jika perlu.
  const double MAX_JOYSTICK_VALUE = 32768.0;
  
  // Lakukan pembagian untuk normalisasi
  double normalized_value = static_cast<double>(value) / MAX_JOYSTICK_VALUE;

  // Pastikan nilai tidak melebihi rentang -0.3 hingga 0.3
  if (normalized_value > 0.3) return 0.3;
  if (normalized_value < -0.3) return -0.3;
  
  return normalized_value;
}

void Walk::handleJoystick() {
  // Dapatkan nilai mentah dari joystick
  int raw_foward = mJoystick->getAxisValue(0); // Maju/Mundur (Stik Kiri Vertikal)
  int raw_side   = mJoystick->getAxisValue(1); // Geser Kiri/Kanan (Stik Kiri Horizontal)
  int raw_turn   = mJoystick->getAxisValue(2); // Putar Kiri/Kanan (Stik Kanan Horizontal)

  // Petakan nilai mentah ke rentang -1.0 hingga 1.0
  double foward = -map_joystick_axis(raw_foward); // Diberi negatif agar stik ke depan = maju
  double side   = map_joystick_axis2(raw_side);
  double turn   = -map_joystick_axis3(raw_turn);   // Diberi negatif agar stik ke kanan = putar kanan

  // Terapkan dead-zone untuk menghindari gerakan kecil saat stik diam
  if (std::abs(foward) < 0.1) foward = 0.0;
  if (std::abs(side) < 0.1) side = 0.0;
  if (std::abs(turn) < 0.1) turn = 0.0;
  
  // Atur gerakan robot menggunakan nilai yang sudah dipetakan
  mGaitManager->setXAmplitude(foward);
  mGaitManager->setYAmplitude(side);
  mGaitManager->setAAmplitude(turn);
}

// ===== [FIX] Koreksi Definisi dan Implementasi Fungsi calculateCoM =====
void Walk::calculateCoM(double *x, double *y, double *z) {
    // 1. Dapatkan sudut sendi saat ini (dalam radian)
    double angles[NMOTORS + 1] = {0};
    for (int i = 0; i < NMOTORS; i++) {
        angles[i + 1] = mPositionSensors[i]->getValue();
    }

    // 2. Lakukan Forward Kinematics
    Matrix3D T_head;
    Matrix3D T_r_leg, T_l_leg;
    
    Point3D total_mass_moment(0, 0, 0);
    double total_mass = 0;

    // --- TORSO ---
    total_mass_moment += Point3D(0,0,0) * Kinematics::MASS_TORSO;
    total_mass += Kinematics::MASS_TORSO;

    // --- KEPALA ---
    T_head.SetTransform(Point3D(0, 0, 0), Vector3D(0, angles[JointData::ID_HEAD_TILT] * 180.0 / M_PI, angles[JointData::ID_HEAD_PAN] * 180.0 / M_PI));
    Point3D com_head_global = T_head.Transform(Kinematics::CoM_HEAD_LOCAL);
    total_mass_moment += com_head_global * Kinematics::MASS_HEAD;
    total_mass += Kinematics::MASS_HEAD;
    
    // --- KAKI KANAN ---
    T_r_leg.SetTransform(Point3D(0, -Kinematics::LEG_SIDE_OFFSET, 0), Vector3D(0,0,0));
    T_r_leg.Rotate(angles[JointData::ID_R_HIP_YAW] * 180.0 / M_PI, Vector3D(0,0,1));
    T_r_leg.Rotate(angles[JointData::ID_R_HIP_ROLL] * 180.0 / M_PI, Vector3D(1,0,0));
    T_r_leg.Rotate(angles[JointData::ID_R_HIP_PITCH] * 180.0 / M_PI, Vector3D(0,1,0));
    total_mass_moment += T_r_leg.Transform(Kinematics::CoM_THIGH_LOCAL) * Kinematics::MASS_THIGH;
    total_mass += Kinematics::MASS_THIGH;
    
    T_r_leg.Translate(Vector3D(0,0, -Kinematics::THIGH_LENGTH));
    T_r_leg.Rotate(angles[JointData::ID_R_KNEE] * 180.0 / M_PI, Vector3D(0,1,0));
    total_mass_moment += T_r_leg.Transform(Kinematics::CoM_CALF_LOCAL) * Kinematics::MASS_CALF;
    total_mass += Kinematics::MASS_CALF;
    
    T_r_leg.Translate(Vector3D(0,0, -Kinematics::CALF_LENGTH));
    T_r_leg.Rotate(angles[JointData::ID_R_ANKLE_PITCH] * 180.0 / M_PI, Vector3D(0,1,0));
    T_r_leg.Rotate(angles[JointData::ID_R_ANKLE_ROLL] * 180.0 / M_PI, Vector3D(1,0,0));
    total_mass_moment += T_r_leg.Transform(Kinematics::CoM_ANKLE_LOCAL) * Kinematics::MASS_ANKLE;
    total_mass += Kinematics::MASS_ANKLE;
    
    T_r_leg.Translate(Vector3D(0,0, -Kinematics::ANKLE_LENGTH));
    total_mass_moment += T_r_leg.Transform(Kinematics::CoM_FOOT_LOCAL) * Kinematics::MASS_FOOT;
    total_mass += Kinematics::MASS_FOOT;

    // --- KAKI KIRI ---
    T_l_leg.SetTransform(Point3D(0, Kinematics::LEG_SIDE_OFFSET, 0), Vector3D(0,0,0));
    T_l_leg.Rotate(angles[JointData::ID_L_HIP_YAW] * 180.0 / M_PI, Vector3D(0,0,1));
    T_l_leg.Rotate(angles[JointData::ID_L_HIP_ROLL] * 180.0 / M_PI, Vector3D(1,0,0));
    T_l_leg.Rotate(angles[JointData::ID_L_HIP_PITCH] * 180.0 / M_PI, Vector3D(0,1,0));
    total_mass_moment += T_l_leg.Transform(Kinematics::CoM_THIGH_LOCAL) * Kinematics::MASS_THIGH;
    total_mass += Kinematics::MASS_THIGH;

    T_l_leg.Translate(Vector3D(0,0, -Kinematics::THIGH_LENGTH));
    T_l_leg.Rotate(angles[JointData::ID_L_KNEE] * 180.0 / M_PI, Vector3D(0,1,0));
    total_mass_moment += T_l_leg.Transform(Kinematics::CoM_CALF_LOCAL) * Kinematics::MASS_CALF;
    total_mass += Kinematics::MASS_CALF;

    T_l_leg.Translate(Vector3D(0,0, -Kinematics::CALF_LENGTH));
    T_l_leg.Rotate(angles[JointData::ID_L_ANKLE_PITCH] * 180.0 / M_PI, Vector3D(0,1,0));
    T_l_leg.Rotate(angles[JointData::ID_L_ANKLE_ROLL] * 180.0 / M_PI, Vector3D(1,0,0));
    total_mass_moment += T_l_leg.Transform(Kinematics::CoM_ANKLE_LOCAL) * Kinematics::MASS_ANKLE;
    total_mass += Kinematics::MASS_ANKLE;

    T_l_leg.Translate(Vector3D(0,0, -Kinematics::ANKLE_LENGTH));
    total_mass_moment += T_l_leg.Transform(Kinematics::CoM_FOOT_LOCAL) * Kinematics::MASS_FOOT;
    total_mass += Kinematics::MASS_FOOT;

    // Hitung CoM final
    Point3D com(0, 0, 0);
    if (total_mass > 0) {
        com = total_mass_moment / total_mass;
    }
    
    // Kembalikan nilai melalui pointer
    *x = com.X;
    *y = com.Y;
    *z = com.Z;
}

void Walk::run() {
  myStep();
  mMotionManager->playPage(9);
  wait(200);

  // Buka file log CoM dan tulis headernya
  comLogFile.open("com_log.csv");
  if (comLogFile.is_open()) {
    comLogFile << "Time,CoMX,CoMY,CoMZ" << endl;
    //cout << "[INFO] Memulai perekaman data CoM ke com_log.csv" << endl;
  } else {
    //cout << "[ERROR] Gagal membuka com_log.csv untuk perekaman." << endl;
  }

  // Buka file log gyro dan tulis headernya
  gyroLogFile.open("gyro_log.csv");
  if (gyroLogFile.is_open()) {
    gyroLogFile << "Time,GyroX,GyroY,GyroZ" << endl;
    //cout << "[INFO] Memulai perekaman data Gyro ke gyro_log.csv" << endl;
  } else {
    //cout << "[ERROR] Gagal membuka gyro_log.csv untuk perekaman." << endl;
  }

  bool loopplay = false;

  while (true) {
    checkIfFallen();
    myStep(); // myStep() di awal loop untuk update sensor

    mGaitManager->setXAmplitude(0.0);
    mGaitManager->setAAmplitude(0.0);
    mGaitManager->setYAmplitude(0.0);

    if (mControlMode == LINE_FOLLOWER) {
      cout << "Mode Kontrol: Line Follower" << endl;
    } else if (mControlMode == MANUAL_KEYBOARD) {
      cout << "Mode Kontrol: Manual Keyboard" << endl;
    } else {
      cout << "Mode Kontrol: Manual Joystick" << endl;
    }

    // ===== [FIX] Ubah Cara Memanggil dan Menampilkan CoM =====
    double com_x, com_y, com_z;
    calculateCoM(&com_x, &com_y, &com_z);
    
    // Konversi dari mm ke meter untuk display
    cout << "CoM [m]: X=" << com_x / 1000.0 << ", Y=" << com_y / 1000.0 << ", Z=" << com_z / 1000.0 << endl;

    if (comLogFile.is_open()) {
        comLogFile << getTime() << ","
                    << com_x << ","
                    << com_y << ","
                    << com_z << endl;
    }

    if (gyroLogFile.is_open()) {
        const double *gyroValues = mGyro->getValues();
        gyroLogFile << getTime() << ","
                    << gyroValues[0] << ","
                    << gyroValues[1] << ","
                    << gyroValues[2] << endl;
    }

    // Dapatkan nilai roll, pitch, yaw (dalam radian)
    const double *imuValues = mInertialUnit->getRollPitchYaw();
    double roll = imuValues[0];
    double pitch = imuValues[1];
    double yaw = imuValues[2];
    
    if (mAngleMode == DEGREES) {
      roll = AngleConverter::toDegrees(roll);
      pitch = AngleConverter::toDegrees(pitch);
      yaw = AngleConverter::toDegrees(yaw);
      std::cout << "IMU [Degree]: Roll: " << roll << ", Pitch: " << pitch << ", Yaw: " << yaw << std::endl;
    } else { // RADIANS
      std::cout << "IMU [Radian]: Roll: " << roll << ", Pitch: " << pitch << ", Yaw: " << yaw << std::endl;
    }

    int key = 0;
    while ((key = mKeyboard->getKey()) >= 0) {
    switch (key) {
        case ' ':  // Space bar
          if (loopplay) {
            mGaitManager->stop();
            loopplay = false;
            wait(200);
          } else {
            mGaitManager->start();
            loopplay = true;
            wait(200);
          }
          break;
        case 'M':
          if (mControlMode == LINE_FOLLOWER) {
          mControlMode = MANUAL_KEYBOARD;
          cout << "Mode Kontrol: Manual Keyboard" << endl;
          wait(200);
        } else if (mControlMode == MANUAL_KEYBOARD) {
          mControlMode = MANUAL_JOYSTICK;
          cout << "Mode Kontrol: Manual Joystick" << endl;
          wait(200);
        } else {
          mControlMode = LINE_FOLLOWER;
          cout << "Mode Kontrol: Line Follower" << endl;
          wait(200);
        }
        break;
        case 'R': // Set display mode to Radians
          mAngleMode = RADIANS;
          break;
        case 'D': // Set display mode to Degrees
          mAngleMode = DEGREES;
          break;
        case Keyboard::UP:    
        if(mControlMode == MANUAL_KEYBOARD){
          mGaitManager->setXAmplitude(1.0);} break;
        case Keyboard::DOWN:  
        if(mControlMode == MANUAL_KEYBOARD){
          mGaitManager->setXAmplitude(-1.0);} break;
        case Keyboard::RIGHT: 
        if(mControlMode == MANUAL_KEYBOARD){
          mGaitManager->setAAmplitude(-0.5);} break;
        case Keyboard::LEFT:  
        if(mControlMode == MANUAL_KEYBOARD){
          mGaitManager->setAAmplitude(0.5);} break;
        case ',':             
        if(mControlMode == MANUAL_KEYBOARD){
          mGaitManager->setYAmplitude(0.3);} break;
        case '.':             
        if(mControlMode == MANUAL_KEYBOARD){
          mGaitManager->setYAmplitude(-0.3);} break;
        }
      }

    // --- Jalankan Logika Sesuai Mode ---
    if (loopplay) {
      if (!mGaitManager->isWalking()) mGaitManager->start();

      switch (mControlMode) {
        case LINE_FOLLOWER:
          mMotors[19]->setPosition(-0.6); // Arahkan kepala ke bawah
          handleLineFollowing();
          break;
        case MANUAL_KEYBOARD:
          mMotors[19]->setPosition(0.0); // Arahkan kepala lurus
          break;
        case MANUAL_JOYSTICK:
          mMotors[19]->setPosition(0.0); // Arahkan kepala lurus
          handleJoystick();
          break;
      }
      mGaitManager->step(mTimeStep);
    }
  }
}

//Kode untuk recover jatuh
void Walk::checkIfFallen() {
  static int fup = 0;
  static int fdown = 0;
  static int fleft = 0;
  static int fright = 0;
  static const double acc_tolerance = 30.0;
  static const double acc_step = 100;

  const double *acc = mAccelerometer->getValues();

  // Cek jatuh ke depan (sumbu Y)
  if (acc[1] < 512.0 - acc_tolerance)
    fup++;
  else
    fup = 0;

  // Cek jatuh ke belakang (sumbu Y)
  if (acc[1] > 512.0 + acc_tolerance)
    fdown++;
  else
    fdown = 0;

  // Cek jatuh ke kiri (sumbu X)
  if (acc[0] < 400.0 + acc_tolerance)
    fleft++;
  else
    fleft = 0;

  // Cek jatuh ke kanan (sumbu X)
  if (acc[0] > 600.0 - acc_tolerance)
    fright++;
  else
    fright = 0;

  // Jatuh Kedepan
  if (fup > acc_step) {
    cout << "-------Jatuh Kedepan-------" << endl;
    mMotionManager->playPage(10);  // f_up
    mMotionManager->playPage(9);   // init position
    fup = 0; fdown = 0; fleft = 0; fright = 0; // Reset semua counter
  }
  // Jatuh Kebelakang
  else if (fdown > acc_step) {
    cout << "-------Jatuh Kebelakang-------" << endl;
    mMotionManager->playPage(11);  // b_up
    mMotionManager->playPage(9);   // init position
    fdown = 0; fup = 0; fleft = 0; fright = 0; // Reset semua counter
  }
  // Jatuh Kesamping Kiri
  else if (fleft > acc_step) {
    cout << "-------Jatuh Kesamping Kanan, mendorong dengan tangan kanan...-------" << endl;
    
    // Hentikan mode berjalan jika aktif
    mGaitManager->stop();
    
    // --- Urutan Gerakan Tangan Kanan ---
    // Tahap 1: Posisikan lengan untuk mendorong
    mMotors[2]->setPosition(-1.0); // ArmUpperR (bahu kanan ke samping)
    mMotors[0]->setPosition(-1.5); // ShoulderR (bahu kanan ke depan)
    mMotors[4]->setPosition(0.5);  // ArmLowerR (tekuk siku kanan)
    wait(500);

    // Tahap 2: Dorong!
    mMotors[0]->setPosition(1.5); // ArmUpperR (dorong dengan bahu kanan)
    wait(500);

    // Tahap 3: Kembali ke posisi siap
    mMotionManager->playPage(9); // Kembali ke posisi awal
    wait(200);

    // Reset semua counter agar loop berikutnya bisa mendeteksi kondisi baru (jatuh ke depan)
    fup = 0; fdown = 0; fleft = 0; fright = 0;
  }
  // Jatuh Kesamping Kanan
  else if (fright > acc_step) {
    cout << "-------Jatuh Kesamping Kiri, mendorong dengan tangan kiri...-------" << endl;
    
    // Hentikan mode berjalan jika aktif
    mGaitManager->stop();
    
    // --- Urutan Gerakan Tangan Kiri ---
    // Tahap 1: Posisikan lengan untuk mendorong
    mMotors[3]->setPosition(1.0); // ArmUpperL (bahu kiri ke samping)
    mMotors[1]->setPosition(-1.5); // ShoulderL (bahu kiri ke depan)
    mMotors[5]->setPosition(-0.5); // ArmLowerL (tekuk siku kiri)
    wait(500);

    // Tahap 2: Dorong!
    mMotors[3]->setPosition(-1.0); // ArmUpperL (dorong dengan bahu kiri)
    wait(500);

    // Tahap 3: Kembali ke posisi siap
    mMotionManager->playPage(9); // Kembali ke posisi awal
    wait(200);

    // Reset semua counter agar loop berikutnya bisa mendeteksi kondisi baru (jatuh ke depan)
    fup = 0; fdown = 0; fleft = 0; fright = 0;
  }
}
