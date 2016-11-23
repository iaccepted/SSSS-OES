#ifndef CAMERA_H
#define CAMERA_H

#include <iostream>

#include <glm/glm.hpp>

using glm::vec2;
using glm::vec3;
using glm::vec4;
using glm::mat4;

class Camera {
public:
	Camera() :
		distance(0.0f),
		distanceVelocity(0.0f),
		angle(0.0f, 0.0f),
		angularVelocity(0.0f, 0.0f),
		panPosition(0.0f, 0.0f),
		panVelocity(0.0f, 0.0f),
		viewportSize(1.0f, 1.0f),
		attenuation(0.0f)
	{
		build();
	}


	void frameMove(float elapsedTime);

	void setDistance(float distance) { this->distance = distance; }
	float getDistance() const { return distance; }

	void setDistanceVelocity(float distanceVelocity) { this->distanceVelocity = distanceVelocity; }
	float getDistanceVelocity() const { return distanceVelocity; }

	void setPanPosition(const vec2 &panPosition) { this->panPosition = panPosition; }
	const vec2 &getPanPosition() const { return panPosition; }

	void setPanVelocity(const vec2 &panVelocity) { this->panVelocity = panVelocity; }
	const vec2 &getPanVelocity() const { return panVelocity; }

	void setAngle(const vec2 &angle) { this->angle = angle; }
	const vec2 &getAngle() const { return angle; }

	void setAngularVelocity(const vec2 &angularVelocity) { this->angularVelocity = angularVelocity; }
	const vec2 &getAngularVelocity() const { return angularVelocity; }

	void setProjection(float fov, float aspect, float nearPlane, float farPlane);
	void setViewportSize(const vec2 &viewportSize) { this->viewportSize = viewportSize; }
	void setViewportSize(const int width, const int height) { this->viewportSize.x = (float)width; this->viewportSize.y = (float)height; }

	const mat4 &getViewMatrix() { return view; }
	const mat4 &getProjectionMatrix() const { return projection; }

	const vec3 &getLookAtPosition() { return lookAtPosition; }
	const vec3 &getEyePosition() { return eyePosition; }

	friend std::ostream& operator <<(std::ostream &os, const Camera &camera);
	friend std::istream& operator >>(std::istream &is, Camera &camera);

	void build();
	void updatePosition(vec2 delta);
    
    //event function
    void touchMoved(float dx, float dy);
    void scale(float s);

private:
	float distance, distanceVelocity;
	vec2 panPosition, panVelocity;
	vec2 angle, angularVelocity;
	vec2 viewportSize;

	mat4 view, projection;
	vec3 lookAtPosition;
	vec3 eyePosition;
    
	float attenuation;
};

#endif
