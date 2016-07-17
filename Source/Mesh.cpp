//
//  Mesh.cpp
//

#include "Mesh.hpp"

#include "VertexAttributeDefines.h"


class MeshImpl {
private:
    friend class Mesh;
    
    GLuint m_vao;
    GLuint m_vbo;
    GLuint m_indexBuffer;
    GLsizei m_numIndices;
    
    
    MeshImpl();
};


//---------------------------------------------------------------------------------------
Mesh::Mesh()
{
    impl = new MeshImpl();
}


//---------------------------------------------------------------------------------------
Mesh::~Mesh()
{
    delete impl;
    impl = nullptr;
}

//---------------------------------------------------------------------------------------
MeshImpl::MeshImpl()
{
    glGenVertexArrays(1, &m_vao);
    glGenBuffers(1, &m_vbo);
    glGenBuffers(1, &m_indexBuffer);
    
    
    glBindVertexArray(m_vao);
    
    // Record the index buffer to be used
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_indexBuffer);

    // Enable vertex attribute slots
    {
        glEnableVertexAttribArray(ATTRIBUTE_POSITION);
        glEnableVertexAttribArray(ATTRIBUTE_NORMAL);

        CHECK_GL_ERRORS;
    }

    // Map position data from vertex buffer to vertex attribute slot.
    {
        GLint stride = sizeof(Mesh::Vertex);
        GLint startOffset(0);
        glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
        glVertexAttribPointer(ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(startOffset));

        CHECK_GL_ERRORS;
    }

    // Map normal data from vertex buffer to vertex attribute slot.
    {
        GLint stride = sizeof(Mesh::Vertex);
        GLint startOffset = sizeof(Mesh::Vertex::position);
        glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
        glVertexAttribPointer(ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(startOffset));

        CHECK_GL_ERRORS;
    }
    
    // Unbind vao
    glBindVertexArray(0);
}


//---------------------------------------------------------------------------------------
GLuint Mesh::vao() const
{
    return impl->m_vao;
}


//---------------------------------------------------------------------------------------
GLuint Mesh::vbo() const
{
    return impl->m_vbo;
}


//---------------------------------------------------------------------------------------
GLsizei Mesh::numIndices() const
{
    return impl->m_numIndices;
}


//---------------------------------------------------------------------------------------
void Mesh::uploadVertexData (
    const std::vector<Mesh::Vertex> & vertices
) {
    size_t numVertices = vertices.size();
    if (numVertices > 0) {
        glBindBuffer(GL_ARRAY_BUFFER, impl->m_vbo);
        const GLsizeiptr numBytes = sizeof(Mesh::Vertex) * numVertices;
        glBufferData(GL_ARRAY_BUFFER, numBytes, vertices.data(), GL_STATIC_DRAW);
        
        CHECK_GL_ERRORS;
    }
    
}

//---------------------------------------------------------------------------------------
void Mesh::uploadIndexData (
    const std::vector<Mesh::Index> & indices
){
    size_t numIndices = indices.size();
    
    if (numIndices > 0) {
        impl->m_numIndices = static_cast<GLsizei>(numIndices);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, impl->m_indexBuffer);
        const GLsizeiptr numBytes = sizeof(Mesh::Index) * numIndices;
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, numBytes, indices.data(), GL_STATIC_DRAW);
        
        CHECK_GL_ERRORS;
    }
}