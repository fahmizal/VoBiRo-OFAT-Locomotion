#ifndef VOBIRO_FIXED_GAIT_PROFILE_HPP
#define VOBIRO_FIXED_GAIT_PROFILE_HPP
static const char *const GAIT_NAME = "DEFAULT";
static const double GAIT_PERIOD_MS = 600.0;
static const double GAIT_LATERAL_MM = 18.0;
static const double GAIT_FOOT_MM = 30.0;
static const double GAIT_DSR = 0.16; // fraction, not percent
static const double GAIT_ARM_GAIN = 1.5;
static const unsigned short GAIT_COMMAND_PORT = 12011;
static const unsigned short GAIT_TELEMETRY_PORT = 12351;
template <typename WalkingT> inline void applyFixedGait(WalkingT *walking) {
  walking->PERIOD_TIME = GAIT_PERIOD_MS;
  walking->Y_SWAP_AMPLITUDE = GAIT_LATERAL_MM;
  walking->Z_MOVE_AMPLITUDE = GAIT_FOOT_MM;
  walking->DSP_RATIO = GAIT_DSR;
  walking->ARM_SWING_GAIN = GAIT_ARM_GAIN;
}
#endif
