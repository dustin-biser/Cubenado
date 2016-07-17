//
//  Mesh.hpp
//

#pragma once

#import <OpenGLES/ES3/gl.h>
#import <vector>


// Forward declaration.
class MeshImpl;


class Mesh {
public:
    struct Vertex {
        GLfloat position[3];
        GLfloat normal[3];
    };
    
    typedef GLushort Index;
    
    
    Mesh();
    
    ~Mesh();
    
    
    GLuint vao() const;
    
    GLuint vbo() const;
    
    GLsizei numIndices() const;
    
    void uploadVertexData (
        const std::vector<Mesh::Vertex> & vertices
    );
    
    void uploadIndexData (
        const std::vector<Mesh::Index> & indices
    );
    
private:
    MeshImpl * impl;
};