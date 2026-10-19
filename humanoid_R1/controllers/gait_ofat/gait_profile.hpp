#ifndef VOBIRO_FIXED_GAIT_PROFILE_HPP
#define VOBIRO_FIXED_GAIT_PROFILE_HPP
static const char *const GAIT_NAME = "OFAT";
static const double GAIT_PERIOD_MS = 600.0;
static const double GAIT_LATERAL_MM = 30.0;
static const double GAIT_FOOT_MM = 40.0;
static const double GAIT_DSR = 0.16; // fraction, not percent
static const double GAIT_ARM_GAIN = 2.0;
static const unsigned short GAIT_COMMAND_PORT = 12012;
static const unsigned short GAIT_TELEMETRY_PORT = 12352;
template <typename WalkingT> inline void applyFixedGait(WalkingT *walking) {
  walking->PERIOD_TIME = GAIT_PERIOD_MS;
  walking->Y_SWAP_AMPLITUDE = GAIT_LATERAL_MM;
  walking->Z_MOVE_AMPLITUDE = GAIT_FOOT_MM;
  walking->DSP_RATIO = GAIT_DSR;
  walking->ARM_SWING_GAIN = GAIT_ARM_GAIN;
}
#endif
