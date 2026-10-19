#include <math.h>
#include "Kinematics.h"


using namespace Robot;

const double Kinematics::LEG_SIDE_OFFSET       = 56.5; //mm
const double Kinematics::THIGH_LENGTH          = 180.0; //mm
const double Kinematics::CALF_LENGTH           = 180.0; //mm
const double Kinematics::ANKLE_LENGTH          = 42.0; //mm
const double Kinematics::LEG_LENGTH            = 402.0; //mm (THIGH_LENGTH + CALF_LENGTH + ANKLE_LENGTH)

const double Kinematics::CW_LIMIT_R_SHOULDER_ROLL    = -75.0; // degree
const double Kinematics::CCW_LIMIT_R_SHOULDER_ROLL   = 135.0; // degree
const double Kinematics::CW_LIMIT_L_SHOULDER_ROLL    = -135.0; // degree
const double Kinematics::CCW_LIMIT_L_SHOULDER_ROLL   = 75.0; // degree
const double Kinematics::CW_LIMIT_R_ELBOW            = -95.0; // degree
const double Kinematics::CCW_LIMIT_R_ELBOW           = 70.0; // degree
const double Kinematics::CW_LIMIT_L_ELBOW            = -70.0; // degree
const double Kinematics::CCW_LIMIT_L_ELBOW           = 95.0; // degree
const double Kinematics::CW_LIMIT_R_HIP_YAW          = -123.0; // degree
const double Kinematics::CCW_LIMIT_R_HIP_YAW         = 53.0; // degree
const double Kinematics::CW_LIMIT_L_HIP_YAW          = -53.0; // degree
const double Kinematics::CCW_LIMIT_L_HIP_YAW         = 123.0; // degree
const double Kinematics::CW_LIMIT_R_HIP_ROLL         = -45.0; // degree
const double Kinematics::CCW_LIMIT_R_HIP_ROLL        = 59.0; // degree
const double Kinematics::CW_LIMIT_L_HIP_ROLL         = -59.0; // degree
const double Kinematics::CCW_LIMIT_L_HIP_ROLL        = 45.0; // degree
const double Kinematics::CW_LIMIT_R_HIP_PITCH        = -100.0; // degree
const double Kinematics::CCW_LIMIT_R_HIP_PITCH       = 29.0; // degree
const double Kinematics::CW_LIMIT_L_HIP_PITCH        = -29.0; // degree
const double Kinematics::CCW_LIMIT_L_HIP_PITCH       = 100.0; // degree
const double Kinematics::CW_LIMIT_R_KNEE             = -6.0; // degree
const double Kinematics::CCW_LIMIT_R_KNEE            = 130.0; // degree
const double Kinematics::CW_LIMIT_L_KNEE             = -130.0; // degree
const double Kinematics::CCW_LIMIT_L_KNEE            = 6.0; // degree
const double Kinematics::CW_LIMIT_R_ANKLE_PITCH      = -72.0; // degree
const double Kinematics::CCW_LIMIT_R_ANKLE_PITCH     = 80.0; // degree
const double Kinematics::CW_LIMIT_L_ANKLE_PITCH      = -80.0; // degree
const double Kinematics::CCW_LIMIT_L_ANKLE_PITCH     = 72.0; // degree
const double Kinematics::CW_LIMIT_R_ANKLE_ROLL       = -44.0; // degree
const double Kinematics::CCW_LIMIT_R_ANKLE_ROLL      = 63.0; // degree
const double Kinematics::CW_LIMIT_L_ANKLE_ROLL       = -63.0; // degree
const double Kinematics::CCW_LIMIT_L_ANKLE_ROLL      = 44.0; // degree
const double Kinematics::CW_LIMIT_HEAD_PAN           = -90.0; // degree
const double Kinematics::CCW_LIMIT_HEAD_PAN          = 90.0; // degree
const double Kinematics::CW_LIMIT_HEAD_TILT          = -25.0; // degree
const double Kinematics::CCW_LIMIT_HEAD_TILT         = 55.0; // degree

// Estimasi Massa (kg)
// Berdasarkan asumsi rangka akrilik (1.18 g/cm^3), link 5x5cm, dan motor MX-28 (72g)
const double Kinematics::MASS_TORSO        = 1.5;   // Estimasi kasar
const double Kinematics::MASS_HEAD         = 0.5;   // Estimasi kasar
const double Kinematics::MASS_UPPER_ARM    = 0.11;  // Tidak digunakan di forward kinematics kaki
const double Kinematics::MASS_LOWER_ARM    = 0.11;  // Tidak digunakan di forward kinematics kaki
const double Kinematics::MASS_THIGH        = 0.60;  // (18*5*5*1.18)/1000 + 0.072
const double Kinematics::MASS_CALF         = 0.60;  // (18*5*5*1.18)/1000 + 0.072
const double Kinematics::MASS_ANKLE        = 0.20;  // (4.2*5*5*1.18)/1000 + 0.072
const double Kinematics::MASS_FOOT         = 0.15;  // Estimasi kasar
const double Kinematics::MASS_TOTAL        = MASS_TORSO + MASS_HEAD + 2*(MASS_UPPER_ARM + MASS_LOWER_ARM + MASS_THIGH + MASS_CALF + MASS_ANKLE + MASS_FOOT);

// Posisi CoM Lokal (mm) - diasumsikan berada di tengah link
const Point3D Kinematics::CoM_HEAD_LOCAL         = Point3D(0, 0, 30.0); // Estimasi
const Point3D Kinematics::CoM_UPPER_ARM_LOCAL    = Point3D(0, 0, -52.5); // Setengah panjang lengan atas
const Point3D Kinematics::CoM_LOWER_ARM_LOCAL    = Point3D(0, 0, -52.5); // Setengah panjang lengan bawah
const Point3D Kinematics::CoM_THIGH_LOCAL        = Point3D(0, 0, -THIGH_LENGTH / 2.0);
const Point3D Kinematics::CoM_CALF_LOCAL         = Point3D(0, 0, -CALF_LENGTH / 2.0);
const Point3D Kinematics::CoM_ANKLE_LOCAL        = Point3D(0, 0, -ANKLE_LENGTH / 2.0);
const Point3D Kinematics::CoM_FOOT_LOCAL         = Point3D(0, 0, -ANKLE_LENGTH); // Disederhanakan

Kinematics* Kinematics::m_UniqueInstance = new Kinematics();

Kinematics::Kinematics()
{
}

Kinematics::~Kinematics()
{
}


//setting kamera jika ingin dipakai
const double Kinematics::CAMERA_DISTANCE       = 33.2; //mm
const double Kinematics::EYE_TILT_OFFSET_ANGLE = 40.0; //degree
