/***************************************
*author: guohongzhi  zju
*date:2015.8.23
*func: program manager
****************************************/
#ifndef _PROGRAMMANAGER_H_
#define _PROGRAMMANAGER_H_
#import <OpenGLES/ES3/gl.h>
#import <glm/glm.hpp>
#import <string>

namespace GLSLShader
{
	typedef enum
	{
		VERTEX = 0, FRAGMENT, GEOMETRY,
		TESS_CONTROL, TESS_EVALUATION
	}shaderType;
};

class Program
{
public:
	Program();

	void compileShaderFromFile(const char *verName, const char *fragName);

	bool compileShaderFromFile(const char *fileName, GLSLShader::shaderType type);
	bool compileShaderFromString(const char *source, GLSLShader::shaderType type);
	bool link();
	bool validate();
	void use();
	void deleteProgram();
	std::string log();
	GLuint getHandle();
	bool isLinked();

	void   bindAttribLocation(GLuint location, const char *name);
	void   bindFragDataLocation(GLuint location, const char *name);

	void   setUniform(const char *name, float x, float y, float z);
	void   setUniform(const char *name, const glm::vec2 &v);
	void   setUniform(const char *name, const glm::vec3 &v);
	void   setUniform(const char *name, const glm::vec4 &v);
	void   setUniform(const char *name, const glm::mat4 &m);
	void   setUniform(const char *name, const glm::mat3 &m);
	void   setUniform(const char *name, float val);
	void   setUniform(const char *name, int val);
	void   setUniform(const char *name, bool val);
    void   setTexture(const char *name, GLuint texId, GLuint index, GLenum type = GL_TEXTURE_2D);

	void   printActiveUniforms();
	void   printActiveAttribs();

private:
	GLuint handle;
	bool linked;
	std::string logString;

	bool fileExits(const char *fileName);
	const char *shaderSourceFromFile(const char *fileName);
	GLuint getUniformLocation(const char *name);
};

#endif