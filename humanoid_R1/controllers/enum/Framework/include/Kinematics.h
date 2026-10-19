/*
 *   Kinematics.h
 *
 *   Author: ROBOTIS
 *
 */

#ifndef _KINEMATICS_H_
#define _KINEMATICS_H_

#include "Matrix.h"
#include "JointData.h"

namespace Robot
{
	class Kinematics
	{
	private:
		static Kinematics* m_UniqueInstance;
		Kinematics();

	protected:

	public:
		static const double CAMERA_DISTANCE; //mm
		static const double EYE_TILT_OFFSET_ANGLE; //degree
		static const double LEG_SIDE_OFFSET; //mm
		static const double THIGH_LENGTH; //mm
		static const double CALF_LENGTH; //mm
		static const double ANKLE_LENGTH; //mm
		static const double LEG_LENGTH; //mm (THIGH_LENGTH + CALF_LENGTH + ANKLE_LENGTH)

		static const double CW_LIMIT_R_SHOULDER_ROLL; // degree
		static const double CCW_LIMIT_R_SHOULDER_ROLL; // degree
		static const double CW_LIMIT_L_SHOULDER_ROLL; // degree
		static const double CCW_LIMIT_L_SHOULDER_ROLL; // degree
		static const double CW_LIMIT_R_ELBOW; // degree
		static const double CCW_LIMIT_R_ELBOW; // degree
		static const double CW_LIMIT_L_ELBOW; // degree
		static const double CCW_LIMIT_L_ELBOW; // degree
		static const double CW_LIMIT_R_HIP_YAW; // degree
		static const double CCW_LIMIT_R_HIP_YAW; // degree
		static const double CW_LIMIT_L_HIP_YAW; // degree
		static const double CCW_LIMIT_L_HIP_YAW; // degree
		static const double CW_LIMIT_R_HIP_ROLL; // degree
		static const double CCW_LIMIT_R_HIP_ROLL; // degree
		static const double CW_LIMIT_L_HIP_ROLL; // degree
		static const double CCW_LIMIT_L_HIP_ROLL; // degree
		static const double CW_LIMIT_R_HIP_PITCH; // degree
		static const double CCW_LIMIT_R_HIP_PITCH; // degree
		static const double CW_LIMIT_L_HIP_PITCH; // degree
		static const double CCW_LIMIT_L_HIP_PITCH; // degree
		static const double CW_LIMIT_R_KNEE; // degree
		static const double CCW_LIMIT_R_KNEE; // degree
		static const double CW_LIMIT_L_KNEE; // degree
		static const double CCW_LIMIT_L_KNEE; // degree
		static const double CW_LIMIT_R_ANKLE_PITCH; // degree
		static const double CCW_LIMIT_R_ANKLE_PITCH; // degree
		static const double CW_LIMIT_L_ANKLE_PITCH; // degree
		static const double CCW_LIMIT_L_ANKLE_PITCH; // degree
		static const double CW_LIMIT_R_ANKLE_ROLL; // degree
		static const double CCW_LIMIT_R_ANKLE_ROLL; // degree
		static const double CW_LIMIT_L_ANKLE_ROLL; // degree
		static const double CCW_LIMIT_L_ANKLE_ROLL; // degree
		static const double CW_LIMIT_HEAD_PAN; // degree
		static const double CCW_LIMIT_HEAD_PAN; // degree
		static const double CW_LIMIT_HEAD_TILT; // degree
		static const double CCW_LIMIT_HEAD_TILT; // degree

		// Estimasi Massa setiap bagian tubuh (dalam kg)
		static const double MASS_TORSO;
		static const double MASS_HEAD;
		static const double MASS_UPPER_ARM;
		static const double MASS_LOWER_ARM;
		static const double MASS_THIGH;
		static const double MASS_CALF;
		static const double MASS_ANKLE;
		static const double MASS_FOOT;
		static const double MASS_TOTAL;

		// Posisi Center of Mass Lokal (relatif terhadap sendi induknya, dalam mm)
		static const Point3D CoM_HEAD_LOCAL;
		static const Point3D CoM_UPPER_ARM_LOCAL;
		static const Point3D CoM_LOWER_ARM_LOCAL;
		static const Point3D CoM_THIGH_LOCAL;
		static const Point3D CoM_CALF_LOCAL;
		static const Point3D CoM_ANKLE_LOCAL;
		static const Point3D CoM_FOOT_LOCAL;

		~Kinematics();

		static Kinematics* GetInstance()			{ return m_UniqueInstance; }
	};
}

#endif
