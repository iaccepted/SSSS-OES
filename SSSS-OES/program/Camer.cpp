#include "Camera.h"
#include <glm/gtc/matrix_transform.hpp>

#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>
#include "GLError.h"

using namespace std;

void Camera::frameMove(float elapsedTime)
{
	angle += angularVelocity * elapsedTime / 150.0f;
	angularVelocity = angularVelocity / (1.0f + attenuation * elapsedTime);
	distance += distanceVelocity * elapsedTime / 150.0f;
	panPosition += panVelocity * elapsedTime / 150.0f;
	build();
}


void Camera::setProjection(float fov, float aspect, float nearPlane, float farPlane)
{
	projection = glm::perspective(fov, aspect, nearPlane, farPlane);
}

void Camera::build()
{
	view = glm::translate(mat4(1.0f), glm::vec3(-panPosition.x, -panPosition.y, -distance));
	view = glm::rotate(view, -angle.y, glm::vec3(1, 0, 0));
	view = glm::rotate(view, -angle.x, glm::vec3(0, 1, 0));

	mat4 viewInverse = glm::inverse(view);
	lookAtPosition = vec3(viewInverse * vec4(0.0f, 0.0f, -distance, 1.0f));
	eyePosition = vec3(viewInverse * vec4(0.0f, 0.0f, 0.0f, 1.0f));
}


void Camera::updatePosition(vec2 delta) {
	delta.x /= viewportSize.x / 2.0f;
	delta.y /= viewportSize.y / 2.0f;

	mat4 transform = mat4(1.0f);
	transform = glm::translate(transform, vec3(0.0f, 0.0f, distance));
	transform = projection * transform;

	mat4 inverse = glm::inverse(transform);

	vec4 t = vec4(panPosition.x, panPosition.y, 0.0f, 1.0f);
	t = transform * t;
	t.x -= delta.x * t.w;
	t.y -= delta.y * t.w;
	t = inverse * t;
	panPosition = vec2(t);
}

void Camera::touchMoved(float dx, float dy)
{
    glm::vec2 delta = glm::vec2(dx, dy);
    angularVelocity -= delta;
    attenuation = 4.0;
    //cout << angularVelocity.x << "---" << angularVelocity.y << endl;
}

void Camera::scale(float s)
{
    float d = distance * s;
    if (d > 9.0f)d = 9.0f;
    if (d < 2.5f)d = 2.5f;
    
    this->distance = d;
}

ostream &operator <<(ostream &os, const Camera &camera) {
	os << camera.distance << endl;
	os << camera.angle.x << " " << camera.angle.y << endl;
	os << camera.panPosition.x << " " << camera.panPosition.y << endl;
	os << camera.angularVelocity.x << " " << camera.angularVelocity.y << endl;
	return os;
}


istream &operator >>(istream &is, Camera &camera) {
	is >> camera.distance;
	is >> camera.angle.x >> camera.angle.y;
	is >> camera.panPosition.x >> camera.panPosition.y;
	is >> camera.angularVelocity.x >> camera.angularVelocity.y;
	return is;
}
