#ifndef CONTROL_HPP
#define CONTROL_HPP

#define NMOTORS 20

#include <webots/Robot.hpp>

namespace managers {
  class MotionPlayManager;
  class GaitManager;
  class VisionManager;
}  // namespace managers

namespace webots {
  class Motor;
  class PositionSensor;
  class InertialUnit;
  class LED;
  class Camera;
  class Accelerometer;
  class Gyro;
  class Keyboard;
  class Speaker;
  class Joystick;
};  // namespace webots

// Enum untuk mengelola mode kontrol
enum ControlMode {
  LINE_FOLLOWER,
  MANUAL_KEYBOARD,
  MANUAL_JOYSTICK
};

// Enum untuk mengelola mode IMU
enum ControlImu {
  RADIANS,
  DEGREES
};

class Walk : public webots::Robot {
public:
  Walk();
  virtual ~Walk();
  void run();
  void checkIfFallen();
  void calculateCoM(double *x, double *y, double *z);

private:
  int mTimeStep;
  double mStartTime;
  ControlMode mControlMode;
  ControlImu mAngleMode;
  bool mStopwatchRunning;

 int mLineLostCounter; 


  void myStep();
  void wait(int ms);
  void handleJoystick();
  void handleLineFollowing();

  webots::Motor *mMotors[NMOTORS];
  webots::PositionSensor *mPositionSensors[NMOTORS];
  webots::Accelerometer *mAccelerometer;
  webots::InertialUnit *mInertialUnit;
  webots::Gyro *mGyro;
  webots::Keyboard *mKeyboard;
  webots::Camera *mCamera;
  webots::Joystick *mJoystick;

  managers::VisionManager *mVisionManager;
  managers::MotionPlayManager *mMotionManager;
  managers::GaitManager *mGaitManager;
};

#endif
