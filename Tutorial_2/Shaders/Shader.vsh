//
//  Shader.vsh
//  ES2Framework
//
//  Created by Ryan Evans on 9/4/10.
//  All sample code is licensed under the MIT license, enjoy!
//

attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

void main()
{
    gl_Position = position;
    colorVarying = color;
}
